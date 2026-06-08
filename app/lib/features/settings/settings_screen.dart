import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/growth.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_surface_card.dart';
import '../../shared/widgets/decorative_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadSettings());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings ?? UserSettings();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Stack(
        children: [
          const DecorativeBackground(intensity: 0.05),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              _profileCard(state),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('外观'),
              AppSurfaceCard(
                child: SwitchListTile(
                  title: const Text('深色模式'),
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.08)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (v) async {
                    await state.saveSettings(s.copyWith(theme: v ? 'dark' : 'light'));
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('工作习惯'),
              AppSurfaceCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.done.withValues(alpha: 0.15), AppColors.done.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_outlined, color: AppColors.done, size: 18),
                      ),
                      title: const Text('每日目标工时'),
                      subtitle: Text('${s.dailyGoalMinutes ~/ 60} 小时'),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () => _editGoal(context, state, s),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentWarm.withValues(alpha: 0.15), AppColors.accentWarm.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.priority_high, color: AppColors.accentWarm, size: 18),
                      ),
                      title: const Text('默认优先级'),
                      subtitle: Text(s.defaultPriority),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () async {
                        final p = await showDialog<String>(
                          context: context,
                          builder: (_) => SimpleDialog(
                            title: const Text('默认优先级'),
                            children: ['high', 'medium', 'low']
                                .map((e) => SimpleDialogOption(onPressed: () => Navigator.pop(context, e), child: Text(e)))
                                .toList(),
                          ),
                        );
                        if (p != null) await state.saveSettings(s.copyWith(defaultPriority: p));
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.inProgress.withValues(alpha: 0.15), AppColors.inProgress.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.trending_up, color: AppColors.inProgress, size: 18),
                      ),
                      title: const Text('个人成长目标'),
                      subtitle: Text(s.growthGoal.isEmpty ? '未设置' : s.growthGoal),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () => _editGrowthGoal(context, state, s),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('系统'),
              AppSurfaceCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.textMuted.withValues(alpha: 0.12), AppColors.textMuted.withValues(alpha: 0.04)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.api_outlined, color: AppColors.textSecondary, size: 18),
                      ),
                      title: const Text('API 地址'),
                      subtitle: Text(AppConfig.apiBaseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (state.auth.isLoggedIn) ...[
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline, color: AppColors.primary, size: 18),
                        ),
                        title: const Text('账号'),
                        subtitle: Text(state.auth.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.auth.isLoggedIn)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('退出登录', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    onTap: () => state.logout(),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
      ),
    );
  }

  Widget _profileCard(AppState state) {
    final initials = state.auth.email?.isNotEmpty == true
        ? state.auth.email![0].toUpperCase()
        : 'G';
    return HeroDecoration(
      child: AppSurfaceCard(
        gradient: AppColors.heroGradient,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.auth.isLoggedIn ? state.auth.email!.split('@').first : '访客用户',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.auth.isLoggedIn ? state.auth.email! : '登录以同步数据',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editGoal(BuildContext context, AppState state, UserSettings s) {
    final ctrl = TextEditingController(text: '${s.dailyGoalMinutes ~/ 60}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('每日目标（小时）'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final h = int.tryParse(ctrl.text) ?? 8;
              await state.saveSettings(s.copyWith(dailyGoalMinutes: h * 60));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _editGrowthGoal(BuildContext context, AppState state, UserSettings s) {
    final ctrl = TextEditingController(text: s.growthGoal);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('成长目标'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await state.saveSettings(UserSettings(
                dailyGoalMinutes: s.dailyGoalMinutes,
                workDays: s.workDays,
                defaultPriority: s.defaultPriority,
                theme: s.theme,
                growthGoal: ctrl.text.trim(),
                dailyPlanRemindAt: s.dailyPlanRemindAt,
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
