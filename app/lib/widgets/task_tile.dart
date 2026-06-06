import 'package:flutter/material.dart';

import '../models/task.dart';
import '../providers/app_state.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.state});

  final Task task;
  final AppState state;

  Color get _categoryColor {
    for (final c in AppState.categories) {
      if (c.$1 == task.category) return Color(c.$3);
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _categoryColor.withValues(alpha: 0.2),
          child: Icon(
            task.isDone
                ? Icons.check_circle
                : task.needsVerify
                    ? Icons.verified_user_outlined
                    : Icons.radio_button_unchecked,
            color: _categoryColor,
            size: 22,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(task.category, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _categoryColor.withValues(alpha: 0.15),
                ),
                if (task.aiGenerated)
                  const Chip(
                    label: Text('AI', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (task.needsVerify)
                  Chip(
                    label: const Text('Verify', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.amber.shade100,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'done':
                await state.markDone(task);
              case 'verify':
                await state.markNeedsVerification(task);
              case 'pending':
                await state.markPending(task);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'done', child: Text('Mark done')),
            const PopupMenuItem(value: 'verify', child: Text('Needs verification')),
            const PopupMenuItem(value: 'pending', child: Text('Mark pending')),
          ],
        ),
      ),
    );
  }
}
