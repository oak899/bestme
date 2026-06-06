import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Events & Birthdays')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, state),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.reminders.isNotEmpty) ...[
            const Text('AI Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...state.reminders.map((r) => Card(
                  color: Colors.purple.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.cake_outlined),
                    title: Text(r.title),
                    subtitle: Text(r.aiMessage ?? 'In ${r.daysUntil} days'),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          const Text('All events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...state.events.map((e) => Card(
                child: ListTile(
                  leading: Icon(e.type == 'birthday' ? Icons.cake : Icons.event),
                  title: Text(e.title),
                  subtitle: Text('${e.date} · remind ${e.remindDaysBefore}d before'),
                ),
              )),
          if (state.events.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Add birthdays and events for AI-powered reminders.')),
            ),
        ],
      ),
    );
  }

  void _showAdd(BuildContext context, AppState state) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var type = 'birthday';
    var remindDays = 3;

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
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date (MM-DD or YYYY-MM-DD)',
                  hintText: '03-15 or 2026-03-15',
                ),
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
                  DropdownMenuItem(value: 'event', child: Text('Event')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'birthday'),
              ),
              DropdownButtonFormField<int>(
                value: remindDays,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Remind 1 day before')),
                  DropdownMenuItem(value: 3, child: Text('Remind 3 days before')),
                  DropdownMenuItem(value: 7, child: Text('Remind 7 days before')),
                ],
                onChanged: (v) => setLocal(() => remindDays = v ?? 3),
              ),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) return;
                  await state.addEvent(
                    title: titleCtrl.text.trim(),
                    type: type,
                    date: dateCtrl.text.trim(),
                    remindDaysBefore: remindDays,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
