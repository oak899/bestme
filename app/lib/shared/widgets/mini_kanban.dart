import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/growth.dart';
import '../../models/task.dart';

class MiniKanban extends StatelessWidget {
  const MiniKanban({super.key, required this.columns, this.height = 200});

  final List<KanbanColumn> columns;
  final double height;

  static String _label(String s) => switch (s) {
        'backlog' => '待规划',
        'todo' => '待办',
        'in_progress' => '进行',
        'blocked' => '阻塞',
        'done' => '完成',
        _ => s,
      };

  static Color _color(String s) => switch (s) {
        'backlog' => AppColors.backlog,
        'todo' => AppColors.todo,
        'in_progress' => AppColors.inProgress,
        'blocked' => AppColors.blocked,
        'done' => AppColors.done,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(child: Text('看板加载中…', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final col in columns)
            Container(
              width: 148,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _color(col.status), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_label(col.status)} (${col.tasks.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: col.tasks.length.clamp(0, 5),
                      itemBuilder: (_, i) => _taskChip(context, col.tasks[i], isDark),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _taskChip(BuildContext context, Task t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isDark ? AppColors.borderDark : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        child: InkWell(
          onTap: () => context.push('/tasks/${t.id}'),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
    );
  }
}
