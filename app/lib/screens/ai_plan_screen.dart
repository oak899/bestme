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
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 教练')),
      body: Stack(
        children: [
          Padding(
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
                  'This may take 10–30 seconds.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _input,
                  maxLines: 6,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Finish quarterly report, gym 30 min, call mom, mail tax form...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _generate(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_loading ? 'Generating...' : 'Generate & apply plan'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade900)),
                    ),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
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
          if (_loading)
            ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Asking AI to plan your day…', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your goals first')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final state = context.read<AppState>();
      final outcome = await state.runAiPlan(text);
      if (!mounted) return;
      final msg = outcome.count > 0
          ? 'Created ${outcome.count} tasks for ${state.selectedDate}.'
          : 'AI returned a plan but no tasks were saved. Try again.';
      setState(() => _result = outcome.notes != null ? '$msg\n\n${outcome.notes}' : msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (outcome.count > 0) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      setState(() => _error = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $err'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
