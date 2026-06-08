import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/growth.dart';
import '../../providers/app_state.dart';
import '../../widgets/task_tile.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  ProjectDetail? _detail;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _detail = await context.read<AppState>().loadProjectDetail(int.parse(widget.projectId));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('项目')), body: const Center(child: CircularProgressIndicator()));
    }
    final d = _detail;
    if (d == null) {
      return Scaffold(appBar: AppBar(title: const Text('项目')), body: const Center(child: Text('项目不存在')));
    }
    final p = d.project;
    final pct = p.taskTotal == 0 ? 0.0 : p.taskDone / p.taskTotal;

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.goal.isNotEmpty) Text(p.goal),
          if (p.startDate.isNotEmpty || p.endDate.isNotEmpty)
            Text('${p.startDate} → ${p.endDate}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: pct),
          Text('${p.taskDone}/${p.taskTotal} 完成 · ${p.totalMinutes} 分钟投入'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('任务列表', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Spacer(),
              TextButton(onPressed: () => context.go('/add-task'), child: const Text('添加任务')),
            ],
          ),
          ...d.tasks.map((t) => TaskTile(task: t, state: state)),
        ],
      ),
    );
  }
}
