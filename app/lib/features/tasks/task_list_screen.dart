import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/task_tile.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('任务 · ${state.selectedDate}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => state.loadTasks()),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CategoryChip(
                  label: '全部',
                  color: 0xFF2D3436,
                  selected: state.selectedCategory == null,
                  onTap: () => state.setCategory(null),
                ),
                ...AppState.categories.map((c) => CategoryChip(
                      label: c.$2,
                      color: c.$3,
                      selected: state.selectedCategory == c.$1,
                      onTap: () => state.setCategory(c.$1),
                    )),
              ],
            ),
          ),
          Expanded(
            child: state.tasks.isEmpty
                ? const Center(child: Text('暂无任务'))
                : ListView.builder(
                    itemCount: state.tasks.length,
                    itemBuilder: (_, i) => TaskTile(task: state.tasks[i], state: state),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context, state),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTask(BuildContext context, AppState state) {
    final titleCtrl = TextEditingController();
    var category = 'work';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '任务标题')),
            DropdownButtonFormField<String>(
              value: category,
              items: AppState.categories
                  .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                  .toList(),
              onChanged: (v) => category = v ?? 'work',
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await state.addTask(title: titleCtrl.text.trim(), category: category);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
