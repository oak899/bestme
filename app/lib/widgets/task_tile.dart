import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/task.dart';
import '../providers/app_state.dart';
import '../shared/widgets/app_surface_card.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.state});

  final Task task;
  final AppState state;

  Color get _categoryColor {
    for (final c in AppState.categories) {
      if (c.$1 == task.category) return Color(c.$3);
    }
    return AppColors.textMuted;
  }

  static const _statusActions = [
    ('todo', '待办', Icons.circle_outlined, AppColors.todo),
    ('in_progress', '进行中', Icons.play_circle_outline, AppColors.inProgress),
    ('done', '完成', Icons.check_circle_outline, AppColors.done),
    ('blocked', '验证', Icons.verified_outlined, AppColors.blocked),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStatus = task.status;
    final available = _statusActions.where((a) => a.$1 != currentStatus).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.sm),
      child: Dismissible(
        key: ValueKey('task-${task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async => false,
        onDismissed: (_) {},
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final action in available)
                _ActionButton(
                  label: action.$2,
                  icon: action.$3,
                  color: action.$4,
                  onTap: () async {
                    await state.updateTaskStatus(task, action.$1);
                  },
                ),
            ],
          ),
        ),
        child: AppSurfaceCard(
          onTap: () => context.push('/tasks/${task.id}'),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  task.isDone
                      ? Icons.check_circle_rounded
                      : task.needsVerify
                          ? Icons.verified_outlined
                          : Icons.radio_button_unchecked,
                  color: _categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? AppColors.textMuted : null,
                          ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(task.category, _categoryColor),
                        if (task.aiGenerated) _chip('AI', AppColors.accent),
                        if (task.needsVerify) _chip('待验证', AppColors.blocked),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: double.infinity,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
