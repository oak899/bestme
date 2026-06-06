import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: state.loadSummary),
        ],
      ),
      body: state.loading && s == null
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? const Center(child: Text('No summary available'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _statCard('Completed', s.completed, s.total, Colors.green),
                    _statCard('Pending', s.pending, s.total, Colors.orange),
                    _statCard('Needs verification', s.needsVerification, s.total, Colors.amber),
                    const SizedBox(height: 16),
                    const Text('By category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ...AppState.categories.map((c) {
                      final stats = s.byCategory[c.$1];
                      if (stats == null || stats.total == 0) return const SizedBox.shrink();
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Color(c.$3).withValues(alpha: 0.3), child: Text('${stats.completed}/${stats.total}')),
                        title: Text(c.$2),
                        subtitle: LinearProgressIndicator(
                          value: stats.total == 0 ? 0 : stats.completed / stats.total,
                          color: Color(c.$3),
                        ),
                      );
                    }),
                    if (s.aiSummary != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 20),
                                  SizedBox(width: 8),
                                  Text('AI Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(s.aiSummary!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _statCard(String label, int value, int total, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 16),
        title: Text(label),
        trailing: Text('$value / $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}
