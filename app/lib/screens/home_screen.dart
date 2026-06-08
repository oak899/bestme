import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/growth.dart';
import '../providers/app_state.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final date = DateTime.tryParse(state.selectedDate) ?? DateTime.now();

    final dash = state.dashboard;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: const Text('GrowthOS'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) await state.setDate(picked);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.refreshAll(),
          ),
        ],
      ),
      body: state.loading && tasksEmpty(state)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.refreshAll,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(context, state, date, dash)),
                  if (state.activeTimer != null)
                    SliverToBoxAdapter(child: _timerBar(state)),
                  SliverToBoxAdapter(child: _planSummary(state, dash)),
                  if (state.reminders.isNotEmpty)
                    SliverToBoxAdapter(child: _reminders(state)),
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ..._quadrant('进行中', dash?.inProgress ?? [], state, const Color(0xFF8B5CF6)),
                  ..._quadrant('待办', dash?.todo ?? [], state, const Color(0xFF2563EB)),
                  ..._quadrant('已完成', dash?.done ?? [], state, const Color(0xFF22C55E)),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ai',
            onPressed: () => context.push('/ai-coach'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 教练'),
            backgroundColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddTask(context, state),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  bool tasksEmpty(AppState state) => state.tasks.isEmpty && state.routines.isEmpty;

  Widget _header(BuildContext context, AppState state, DateTime date, DashboardData? dash) {
    final done = state.tasks.where((t) => t.isDone).length;
    final total = state.tasks.length;
    final quote = dash?.quote ?? '专注今日，复利成长。';
    final weekPct = dash?.weekCompletionPct ?? 0;
    final minutes = dash?.todayMinutes ?? 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(date),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(quote, style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Text(
            '$done / $total 任务完成',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('本周完成率 $weekPct% · 今日工时 ${minutes ~/ 60}h${minutes % 60}m',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminders(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.amber.shade50,
        child: ExpansionTile(
          leading: const Icon(Icons.notifications_active, color: Colors.amber),
          title: Text('${state.reminders.length} upcoming reminders'),
          children: state.reminders
              .map((r) => ListTile(
                    title: Text(r.title),
                    subtitle: Text(r.aiMessage ?? '${r.daysUntil} days until ${r.date}'),
                  ))
              .toList(),
        ),
      ),
    );
  }

  List<Widget> _quadrant(String title, List<Task> tasks, AppState state, Color color) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 8),
              Text('$title (${tasks.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ),
      ),
      if (tasks.isEmpty)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('暂无', style: TextStyle(color: Colors.grey))))
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => TaskTile(task: tasks[i], state: state),
            childCount: tasks.length,
          ),
        ),
    ];
  }

  Widget _planSummary(AppState state, DashboardData? dash) {
    final plan = dash?.dailyPlan ?? state.dailyPlan;
    final focus = plan?.focusGoals ?? '';
    if (focus.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.today_outlined),
            title: const Text('今日计划'),
            subtitle: const Text('尚未设置重点目标'),
            trailing: TextButton(onPressed: () => context.go('/daily-plan'), child: const Text('去填写')),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined, color: Color(0xFF2563EB)),
          title: const Text('今日计划'),
          subtitle: Text(focus, maxLines: 3, overflow: TextOverflow.ellipsis),
          onTap: () => context.go('/daily-plan'),
        ),
      ),
    );
  }

  Widget _timerBar(AppState state) {
    final t = state.activeTimer!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('任务 #${t.taskId} 计时中', style: const TextStyle(color: Colors.white))),
              if (t.isPaused)
                IconButton(onPressed: state.resumeTimer, icon: const Icon(Icons.play_arrow, color: Colors.white))
              else
                IconButton(onPressed: state.pauseTimer, icon: const Icon(Icons.pause, color: Colors.white)),
              IconButton(onPressed: state.stopTimer, icon: const Icon(Icons.stop, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTask(BuildContext context, AppState state) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var category = 'life';
    var needsVerify = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppState.categories
                    .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                    .toList(),
                onChanged: (v) => setLocal(() => category = v ?? 'life'),
              ),
              SwitchListTile(
                title: const Text('Needs verification'),
                subtitle: const Text('e.g. mail, payment, proof required'),
                value: needsVerify,
                onChanged: (v) => setLocal(() => needsVerify = v),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  await state.addTask(
                    title: titleCtrl.text.trim(),
                    category: category,
                    description: descCtrl.text.trim(),
                    needsVerification: needsVerify,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
