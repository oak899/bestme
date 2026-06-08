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

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.sm),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
            onSelected: (v) async {
              switch (v) {
                case 'in_progress':
                  await state.markInProgress(task);
                case 'done':
                  await state.markDone(task);
                case 'verify':
                  await state.markNeedsVerification(task);
                case 'pending':
                  await state.markPending(task);
                case 'backlog':
                  await state.markBacklog(task);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'in_progress', child: Text('进行中')),
              PopupMenuItem(value: 'done', child: Text('完成')),
              PopupMenuItem(value: 'verify', child: Text('阻塞/待验证')),
              PopupMenuItem(value: 'pending', child: Text('待办')),
              PopupMenuItem(value: 'backlog', child: Text('待规划')),
            ],
          ),
        ],
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
