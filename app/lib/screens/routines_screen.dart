import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Routines')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdd(context, state),
        child: const Icon(Icons.add),
      ),
      body: state.routines.isEmpty
          ? const Center(
              child: Text('Create routines once — they repeat every day automatically.'),
            )
          : ListView.builder(
              itemCount: state.routines.length,
              itemBuilder: (ctx, i) {
                final r = state.routines[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.repeat),
                    title: Text(r.title),
                    subtitle: Text('${r.category}${r.needsVerification ? ' · needs verification' : ''}'),
                  ),
                );
              },
            ),
    );
  }

  void _showAdd(BuildContext context, AppState state) {
    final titleCtrl = TextEditingController();
    var category = 'life';
    var needsVerify = false;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Routine title')),
              DropdownButtonFormField<String>(
                value: category,
                items: AppState.categories
                    .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                    .toList(),
                onChanged: (v) => setLocal(() => category = v ?? 'life'),
              ),
              SwitchListTile(
                title: const Text('Needs verification'),
                value: needsVerify,
                onChanged: (v) => setLocal(() => needsVerify = v),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  await state.addRoutine(
                    title: titleCtrl.text.trim(),
                    category: category,
                    needsVerification: needsVerify,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save routine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
