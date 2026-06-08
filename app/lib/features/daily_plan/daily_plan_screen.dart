import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/growth.dart';
import '../../providers/app_state.dart';

class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  final _focus = TextEditingController();
  final _review = TextEditingController();
  final _tomorrow = TextEditingController();
  var _estimated = 480;
  var _actual = 0;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _applyPlan(DailyPlan p) {
    _focus.text = p.focusGoals;
    _review.text = p.review;
    _tomorrow.text = p.tomorrowImprove;
    _estimated = p.estimatedMinutes;
    _actual = p.actualMinutes;
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      await state.loadDailyPlan();
      final p = state.dailyPlan ?? DailyPlan(planDate: state.selectedDate);
      _applyPlan(p);
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _review.dispose();
    _tomorrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!_loaded || state.dailyPlanLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('每日计划')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('每日计划 · ${state.selectedDate}'),
        actions: [
          TextButton(
            onPressed: () async {
              await state.copyYesterdayPlan();
              final p = state.dailyPlan;
              if (p != null) _applyPlan(p);
              if (mounted) setState(() {});
            },
            child: const Text('复制昨日'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.dailyPlanError != null)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(state.dailyPlanError!, maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: TextButton(onPressed: _load, child: const Text('重试')),
              ),
            ),
          TextField(
            controller: _focus,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '今日重点',
              border: OutlineInputBorder(),
              hintText: '今天最重要的 1-3 件事…',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('est_$_estimated'),
                  initialValue: '$_estimated',
                  decoration: const InputDecoration(labelText: '预计工时(分钟)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _estimated = int.tryParse(v) ?? _estimated,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: ValueKey('act_$_actual'),
                  initialValue: '$_actual',
                  decoration: const InputDecoration(labelText: '实际工时(分钟)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _actual = int.tryParse(v) ?? _actual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _review,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '今日复盘', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tomorrow,
            maxLines: 2,
            decoration: const InputDecoration(labelText: '明日改进', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              try {
                await state.saveDailyPlan(DailyPlan(
                  planDate: state.selectedDate,
                  focusGoals: _focus.text.trim(),
                  estimatedMinutes: _estimated,
                  actualMinutes: _actual,
                  review: _review.text.trim(),
                  tomorrowImprove: _tomorrow.text.trim(),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('保存计划'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/ai-coach'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('用 AI 生成任务'),
          ),
        ],
      ),
    );
  }
}
