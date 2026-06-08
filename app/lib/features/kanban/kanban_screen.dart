import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../providers/app_state.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadKanban());
  }

  static Color _colorFor(String status) => switch (status) {
        'backlog' => AppColors.backlog,
        'todo' => AppColors.todo,
        'in_progress' => AppColors.inProgress,
        'blocked' => AppColors.blocked,
        'done' => AppColors.done,
        _ => AppColors.textMuted,
      };

  static String _label(String status) => switch (status) {
        'backlog' => 'Backlog',
        'todo' => 'Todo',
        'in_progress' => '进行中',
        'blocked' => '阻塞',
        'done' => '完成',
        _ => status,
      };

  Future<void> _onDrop(String targetStatus, Task task, int index) async {
    final state = context.read<AppState>();
    final updates = <Map<String, dynamic>>[];
    for (final col in state.kanban) {
      var order = 0;
      for (final t in col.tasks) {
        if (t.id == task.id) continue;
        if (col.status == targetStatus && order == index) order++;
        updates.add({'id': int.parse(t.id), 'status': col.status, 'sortOrder': order++});
      }
    }
    updates.add({'id': int.parse(task.id), 'status': targetStatus, 'sortOrder': index});
    try {
      await state.reorderKanban(updates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final boardHeight = MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight - 48;

    return Scaffold(
      appBar: AppBar(
        title: const Text('看板'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => state.loadKanban())],
      ),
      body: state.kanbanLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (state.kanbanError != null)
                  Material(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.orange),
                      title: Text(state.kanbanError!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: TextButton(onPressed: () => state.loadKanban(), child: const Text('重试')),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final col in state.kanban)
                        SizedBox(
                          width: 280,
                          height: boardHeight,
                          child: Card(
                            margin: const EdgeInsets.only(right: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.circle, size: 10, color: _colorFor(col.status)),
                                      const SizedBox(width: 8),
                                      Text('${_label(col.status)} (${col.tasks.length})',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: DragTarget<Task>(
                                      onAcceptWithDetails: (d) => _onDrop(col.status, d.data, col.tasks.length),
                                      builder: (context, candidates, _) => col.tasks.isEmpty
                                          ? const Center(
                                              child: Text('拖拽任务到此处', style: TextStyle(color: AppColors.textMuted)),
                                            )
                                          : ListView.builder(
                                              itemCount: col.tasks.length,
                                              itemBuilder: (_, i) {
                                                final task = col.tasks[i];
                                                return LongPressDraggable<Task>(
                                                  data: task,
                                                  feedback: Material(
                                                    elevation: 4,
                                                    child: SizedBox(width: 240, child: _card(task)),
                                                  ),
                                                  childWhenDragging: Opacity(opacity: 0.4, child: _card(task)),
                                                  child: DragTarget<Task>(
                                                    onAcceptWithDetails: (d) => _onDrop(col.status, d.data, i),
                                                    builder: (ctx, c, _) =>
                                                        _card(task, onTap: () => context.push('/tasks/${task.id}')),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(Task task, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        onTap: onTap,
        title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${task.priority} · ${task.category}', style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
