import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_surface_card.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppScaffold(
      title: '项目',
      subtitle: '管理目标与进度',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, state),
        icon: const Icon(Icons.add),
        label: const Text('新建'),
      ),
      body: state.projects.isEmpty
          ? AppEmptyState(
              icon: Icons.folder_open_outlined,
              title: '还没有项目',
              subtitle: '创建第一个项目，开始追踪你的成长目标',
              actionLabel: '创建项目',
              action: () => _showCreate(context, state),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, 96),
              itemCount: state.projects.length,
              itemBuilder: (_, i) => _projectCard(context, state.projects[i]),
            ),
    );
  }

  Widget _projectCard(BuildContext context, dynamic p) {
    final pct = p.taskTotal == 0 ? 0.0 : p.taskDone / p.taskTotal;
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => context.push('/projects/${p.id}'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.titleSmall),
                if (p.goal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(p.goal, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.border),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('${p.taskDone}/${p.taskTotal} · ${(pct * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }

  void _showCreate(BuildContext context, AppState state) {
    final name = TextEditingController();
    final goal = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.xl, bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('新建项目', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(controller: name, decoration: const InputDecoration(labelText: '项目名称')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: goal, decoration: const InputDecoration(labelText: '项目目标')),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await state.addProject(name: name.text.trim(), goal: goal.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}
