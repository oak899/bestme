import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/growth.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_surface_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadSettings());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings ?? UserSettings();
    final auth = state.auth;

    return AppScaffold(
      title: '我的',
      subtitle: '账户与偏好设置',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.xxl),
        children: [
          _profileHeader(auth),
          const SizedBox(height: AppSpacing.lg),
          _settingsGroup(context, '偏好设置', [
            AppSwitchTile(
              title: '深色模式',
              subtitle: '切换界面主题',
              value: state.themeMode == ThemeMode.dark,
              onChanged: (v) => state.saveSettings(s.copyWith(theme: v ? 'dark' : 'light')),
            ),
            _settingTile(
              context,
              icon: Icons.schedule_outlined,
              title: '每日目标工时',
              subtitle: '${s.dailyGoalMinutes ~/ 60} 小时',
              onTap: () => _editGoal(context, state, s),
            ),
            _settingTile(
              context,
              icon: Icons.flag_outlined,
              title: '成长目标',
              subtitle: s.growthGoal.isEmpty ? '未设置' : s.growthGoal,
              onTap: () => _editGoalText(context, state, s),
            ),
            _settingTile(context, icon: Icons.low_priority_outlined, title: '默认优先级', subtitle: _priorityLabel(s.defaultPriority)),
          ]),
          const SizedBox(height: AppSpacing.md),
          _settingsGroup(context, '功能', [
            _settingTile(
              context,
              icon: Icons.notifications_outlined,
              title: '提醒设置',
              subtitle: '任务提醒、番茄钟（即将支持）',
            ),
            _settingTile(
              context,
              icon: Icons.auto_awesome_outlined,
              title: 'AI 教练',
              subtitle: '智能规划与建议',
              onTap: () => context.push('/ai-coach'),
            ),
            if (!auth.isLoggedIn)
              _settingTile(
                context,
                icon: Icons.login_outlined,
                title: '登录 / 注册',
                subtitle: '同步数据到云端',
                onTap: () => context.push('/login'),
              ),
          ]),
          const SizedBox(height: AppSpacing.md),
          _settingsGroup(context, '关于', [
            _settingTile(
              context,
              icon: Icons.storage_outlined,
              title: '数据存储',
              subtitle: 'SQLite · ${AppConfig.apiBaseUrl}',
            ),
            if (auth.isLoggedIn)
              _settingTile(
                context,
                icon: Icons.logout,
                title: '退出登录',
                subtitle: auth.email ?? '',
                titleColor: AppColors.error,
                onTap: () async {
                  await state.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
          ]),
        ],
      ),
    );
  }

  Widget _profileHeader(dynamic auth) {
    final initial = auth.isLoggedIn ? (auth.email?[0].toUpperCase() ?? 'U') : '?';
    return AppSurfaceCard(
      gradient: AppColors.heroGradient,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isLoggedIn ? (auth.email ?? '用户') : '访客模式',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text('GrowthOS · 个人成长工作台', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsGroup(BuildContext context, String title, List<Widget> children) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      titleColor: titleColor,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: titleColor ?? AppColors.primary),
      ),
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textMuted) : null,
      onTap: onTap,
    );
  }

  String _priorityLabel(String p) => switch (p) {
        'high' => '高',
        'medium' => '中',
        'low' => '低',
        _ => p,
      };

  void _editGoal(BuildContext context, AppState state, UserSettings s) {
    final ctrl = TextEditingController(text: '${s.dailyGoalMinutes ~/ 60}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('每日目标（小时）'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '小时')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await state.saveSettings(s.copyWith(dailyGoalMinutes: (int.tryParse(ctrl.text) ?? 8) * 60));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _editGoalText(BuildContext context, AppState state, UserSettings s) {
    final ctrl = TextEditingController(text: s.growthGoal);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('成长目标'),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: '描述你的长期成长目标')),
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
