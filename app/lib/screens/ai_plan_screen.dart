import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class AiPlanScreen extends StatefulWidget {
  const AiPlanScreen({super.key});

  @override
  State<AiPlanScreen> createState() => _AiPlanScreenState();
}

class _AiPlanScreenState extends State<AiPlanScreen> {
  final _input = TextEditingController();
  bool _loading = false;
  String? _result;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Daily Plan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Describe your goals for today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI will create a balanced plan across life, work, and exercise. '
              'Tasks like sending mail will be flagged for verification.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'e.g. Finish quarterly report, gym 30 min, call mom, mail tax form...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Generating...' : 'Generate & apply plan'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_result!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (_input.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final state = context.read<AppState>();
      final count = await state.runAiPlan(_input.text.trim());
      await state.loadTasks();
      setState(() => _result = 'Created $count tasks for ${state.selectedDate}.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI plan applied: $count tasks')),
        );
      }
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}
