import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/growth.dart';
import '../../models/task.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_section_header.dart';
import '../../shared/widgets/app_surface_card.dart';
import '../../shared/widgets/decorative_background.dart';
import '../../widgets/task_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String _formatDate(DateTime date) => '${DateFormat('yyyy年M月d日').format(date)} ${_weekdays[date.weekday - 1]}';

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dash = state.dashboard;
    final date = DateTime.tryParse(state.selectedDate) ?? DateTime.now();

    return AppScaffold(
      title: 'GrowthOS',
      subtitle: _formatDate(date),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          tooltip: '选择日期',
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) await state.setDate(picked);
          },
        ),
        IconButton(icon: const Icon(Icons.refresh), tooltip: '刷新', onPressed: () => state.refreshAll()),
      ],
      refreshIndicator: () async {
        await state.refreshAll();
      },
      body: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                if (state.loading && dash == null)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                _heroCard(state, dash, date),
                if (state.activeTimer != null) _timerBar(state),
                AppSectionHeader(title: '今日计划', actionLabel: '编辑', onAction: () => context.push('/daily-plan')),
                _planCard(state, dash),
                const AppSectionHeader(title: '项目进度'),
                _projectProgress(state),
                const AppSectionHeader(title: '进行中'),
                ..._tasks(dash?.inProgress ?? [], state, '暂无进行中的任务'),
                const AppSectionHeader(title: '待办'),
                ..._tasks(dash?.todo ?? [], state, '暂无待办任务'),
                const AppSectionHeader(title: '已完成'),
                ..._tasks(dash?.done ?? [], state, '今日暂无已完成任务'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentWarm, Color(0xFFFBBF24)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentWarm.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/ai-coach'),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome_outlined, color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                'AI 规划今日工作',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              ],
            ),
    );
  }

  Widget _heroCard(AppState state, DashboardData? dash, DateTime date) {
    final minutes = dash?.todayMinutes ?? state.timeStats?.totalMinutes ?? 0;
    final week = dash?.weekCompletionPct ?? 0;
    final quote = dash?.quote ?? '专注今日，复利成长。';

    return HeroDecoration(
      child: AppSurfaceCard(
        margin: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.sm),
        gradient: AppColors.heroGradient,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quote,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.format_quote, color: Colors.white70, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: _stat('今日工时', '${minutes ~/ 60}h ${minutes % 60}m')),
                Expanded(child: _stat('本周完成', '$week%')),
                Expanded(child: _stat('周累计', '${state.timeStats?.weekTotalMinutes ?? 0}m')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _timerBar(AppState state) {
    final t = state.activeTimer!;
    return AppSurfaceCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('计时进行中', style: Theme.of(context).textTheme.labelMedium),
                Text('任务 #${t.taskId}', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: t.isPaused ? state.resumeTimer : state.pauseTimer,
            icon: Icon(t.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          ),
          IconButton(onPressed: state.stopTimer, icon: const Icon(Icons.stop_rounded)),
        ],
      ),
    );
  }

  Widget _planCard(AppState state, DashboardData? dash) {
    final focus = dash?.dailyPlan?.focusGoals ?? state.dailyPlan?.focusGoals ?? '';
    return AppSurfaceCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      onTap: () => context.push('/daily-plan'),
      accentColor: AppColors.accent,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.flag_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日重点', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  focus.isEmpty ? '点击设置今日工作重点' : focus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _projectProgress(AppState state) {
    if (state.projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: AppEmptyState(
          emoji: '📁',
          title: '暂无项目',
          subtitle: '去创建你的第一个项目吧',
          action: () => context.push('/projects'),
          actionLabel: '创建项目',
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page - AppSpacing.sm),
        itemCount: state.projects.length,
        itemBuilder: (_, i) {
          final p = state.projects[i];
          final pct = p.taskTotal == 0 ? 0.0 : p.taskDone / p.taskTotal;
          final progressColor = pct >= 1.0
              ? AppColors.done
              : pct >= 0.5
                  ? AppColors.accent
                  : AppColors.primary;
          return SizedBox(
            width: 180,
            child: AppSurfaceCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              onTap: () => context.push('/projects/${p.id}'),
              accentColor: progressColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      StatusRing(
                        progress: pct,
                        size: 32,
                        strokeWidth: 3,
                        color: progressColor,
                      ),
                    ],
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: progressColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${p.taskDone}/${p.taskTotal} 完成', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _tasks(List<Task> list, AppState state, String emptyText) {
    if (list.isEmpty) {
      final emoji = emptyText.contains('进行中')
          ? '🚀'
          : emptyText.contains('待办')
              ? '📝'
              : '🎉';
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.md),
          child: AppEmptyState(
            emoji: emoji,
            title: emptyText,
            subtitle: '保持高效，从添加任务开始',
          ),
        ),
      ];
    }
    return list.take(5).map((t) => TaskTile(task: t, state: state)).toList();
  }
}
