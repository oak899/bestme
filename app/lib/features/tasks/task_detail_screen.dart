import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/app_state.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  List<TaskHistory> _history = [];
  List<TaskComment> _comments = [];
  List<Task> _subtasks = [];
  final _commentCtrl = TextEditingController();
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final t = await state.loadTask(widget.taskId);
      final h = await state.loadTaskHistory(widget.taskId);
      final c = await state.loadTaskComments(widget.taskId);
      final st = await state.loadSubtasks(widget.taskId);
      if (mounted) {
        setState(() {
          _task = t;
          _history = h;
          _comments = c;
          _subtasks = st;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('任务详情')), body: const Center(child: CircularProgressIndicator()));
    }
    final task = _task;
    if (task == null) {
      return Scaffold(appBar: AppBar(title: const Text('任务详情')), body: const Center(child: Text('任务不存在')));
    }

    final state = context.watch<AppState>();
    final timer = state.activeTimer;
    final isTimingThis = timer?.taskId.toString() == task.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () => _save(task)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('标题', task.title, (v) => _task = task.copyWith(title: v)),
          const SizedBox(height: 12),
          _field('描述', task.description ?? '', (v) => _task = task.copyWith(description: v), maxLines: 3),
          const SizedBox(height: 12),
          _dropdown('优先级', task.priority, ['high', 'medium', 'low'], (v) => _task = task.copyWith(priority: v)),
          _dropdown('状态', task.status, ['backlog', 'todo', 'in_progress', 'blocked', 'done'], (v) => _task = task.copyWith(status: v)),
          _dropdown('分类', task.category, AppState.categories.map((c) => c.$1).toList(), (v) => _task = task.copyWith(category: v)),
          _field('截止日期', task.dueDate ?? '', (v) => _task = task.copyWith(dueDate: v)),
          Row(
            children: [
              Expanded(child: _field('预计(分)', '${task.estimateMinutes}', (v) => _task = task.copyWith(estimateMinutes: int.tryParse(v) ?? 0))),
              const SizedBox(width: 12),
              Expanded(child: Text('实际: ${task.actualMinutes} 分钟')),
            ],
          ),
          if (state.projects.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: task.projectId,
              decoration: const InputDecoration(labelText: '项目', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('无')),
                ...state.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
              ],
              onChanged: (v) => setState(() => _task = task.copyWith(projectId: v)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isTimingThis)
                FilledButton.icon(
                  onPressed: () => state.startTimer(int.parse(task.id)),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始计时'),
                )
              else ...[
                if (timer!.isPaused)
                  FilledButton.icon(onPressed: state.resumeTimer, icon: const Icon(Icons.play_arrow), label: const Text('继续'))
                else
                  FilledButton.icon(onPressed: state.pauseTimer, icon: const Icon(Icons.pause), label: const Text('暂停')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: state.stopTimer, icon: const Icon(Icons.stop), label: const Text('结束')),
              ],
            ],
          ),
          const Divider(height: 32),
          Text('子任务', style: Theme.of(context).textTheme.titleMedium),
          ..._subtasks.map((s) => ListTile(dense: true, title: Text(s.title), subtitle: Text(s.status), onTap: () => context.push('/tasks/${s.id}'))),
          if (_subtasks.isEmpty) const ListTile(dense: true, title: Text('暂无子任务', style: TextStyle(color: Colors.grey))),
          const Divider(height: 32),
          Text('状态历史', style: Theme.of(context).textTheme.titleMedium),
          ..._history.map((h) => ListTile(
                dense: true,
                title: Text('${h.fromStatus} → ${h.toStatus}'),
                subtitle: Text(h.changedAt),
              )),
          const Divider(height: 32),
          Text('评论', style: Theme.of(context).textTheme.titleMedium),
          ..._comments.map((c) => ListTile(title: Text(c.body), subtitle: Text(c.createdAt))),
          Row(
            children: [
              Expanded(child: TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: '添加评论'))),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (_commentCtrl.text.trim().isEmpty) return;
                  await state.addTaskComment(task.id, _commentCtrl.text.trim());
                  _commentCtrl.clear();
                  await _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value, void Function(String) onChanged, {int maxLines = 1}) {
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, void Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : options.first,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) {
          if (v != null) setState(() => onChanged(v));
        },
      ),
    );
  }

  Future<void> _save(Task original) async {
    final t = _task ?? original;
    await context.read<AppState>().saveTask(t);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
      context.pop();
    }
  }
}
