import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/task.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_list_tile.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_surface_card.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _tags = TextEditingController();
  var _priority = 'medium';
  var _status = 'todo';
  var _category = 'work';
  int? _projectId;
  String? _dueDate;
  var _estimate = 60;
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppScaffold(
      title: '添加任务',
      subtitle: '记录并规划你的工作',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.xxl),
        children: [
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('基本信息', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.lg),
                TextField(controller: _title, decoration: const InputDecoration(labelText: '标题 *')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: '描述')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('分类与状态', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: '优先级'),
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('高')),
                    DropdownMenuItem(value: 'medium', child: Text('中')),
                    DropdownMenuItem(value: 'low', child: Text('低')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: '状态'),
                  items: const [
                    DropdownMenuItem(value: 'backlog', child: Text('待规划')),
                    DropdownMenuItem(value: 'todo', child: Text('待办')),
                    DropdownMenuItem(value: 'in_progress', child: Text('进行中')),
                    DropdownMenuItem(value: 'blocked', child: Text('阻塞')),
                    DropdownMenuItem(value: 'done', child: Text('已完成')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'todo'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: AppState.categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'work'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('时间与标签', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.lg),
                AppPickerTile(
                  title: '截止日期',
                  value: _dueDate ?? '未设置',
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setState(() => _dueDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  initialValue: '$_estimate',
                  decoration: const InputDecoration(labelText: '预计耗时（分钟）'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _estimate = int.tryParse(v) ?? 60,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: _tags, decoration: const InputDecoration(labelText: '标签（逗号分隔）')),
                if (state.projects.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int?>(
                    initialValue: _projectId,
                    decoration: const InputDecoration(labelText: '所属项目'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('无')),
                      ...state.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (v) => setState(() => _projectId = v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _saving ? null : () => _save(state),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('创建任务'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppState state) async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final tags = _tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await state.saveTask(Task(
        id: '',
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _category,
        date: state.selectedDate,
        status: _status,
        priority: _priority,
        projectId: _projectId,
        dueDate: _dueDate,
        estimateMinutes: _estimate,
        tags: tags,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('任务已创建')));
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
