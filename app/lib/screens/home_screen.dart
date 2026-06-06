import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/category_chip.dart';
import '../widgets/task_tile.dart';
import 'ai_plan_screen.dart';
import 'events_screen.dart';
import 'routines_screen.dart';
import 'summary_screen.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: const Text('BestMe'),
        backgroundColor: const Color(0xFF2D3436),
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
                  SliverToBoxAdapter(child: _header(context, state, date)),
                  if (state.reminders.isNotEmpty)
                    SliverToBoxAdapter(child: _reminders(state)),
                  SliverToBoxAdapter(child: _categoryFilter(state)),
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  if (state.tasks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No tasks yet. Add one or use AI Plan.')),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => TaskTile(task: state.tasks[i], state: state),
                        childCount: state.tasks.length,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ai',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiPlanScreen()),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI Plan'),
            backgroundColor: const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddTask(context, state),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutinesScreen()));
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.repeat), label: 'Routines'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.summarize), label: 'Summary'),
        ],
      ),
    );
  }

  bool tasksEmpty(AppState state) => state.tasks.isEmpty && state.routines.isEmpty;

  Widget _header(BuildContext context, AppState state, DateTime date) {
    final done = state.tasks.where((t) => t.isDone).length;
    final total = state.tasks.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D3436), Color(0xFF636E72)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(date),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$done / $total tasks done',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: const Color(0xFF00B894),
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

  Widget _categoryFilter(AppState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CategoryChip(
            label: 'All',
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
