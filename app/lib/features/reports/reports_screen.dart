import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_surface_card.dart' show AppMetricCard, AppSurfaceCard;
import '../../shared/widgets/app_section_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _periods = [
    ('week', '周'),
    ('2week', '2周'),
    ('month', '月'),
    ('year', '年'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadReports());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.reports;

    return AppScaffold(
      title: '报表',
      subtitle: '数据驱动成长',
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => state.loadReports())],
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.sm),
            child: Row(
              children: [
                for (final p in _periods)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(p.$2),
                      selected: state.reportsPeriod == p.$1,
                      onSelected: (_) => state.loadReports(period: p.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: data == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xxl),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.6,
                        children: [
                          AppMetricCard(label: '完成率', value: '${data.weekCompletionPct}%', icon: Icons.check_circle_outline, color: AppColors.done),
                          AppMetricCard(label: '高优完成', value: '${data.highPriorityCompletionPct}%', icon: Icons.priority_high, color: AppColors.primary),
                          AppMetricCard(label: '拖延任务', value: '${data.overdueCount}', icon: Icons.schedule, color: AppColors.blocked),
                          AppMetricCard(label: '总工时', value: '${data.totalWorkMinutes}m', icon: Icons.timer_outlined, color: AppColors.accent),
                        ],
                      ),
                      const AppSectionHeader(title: '完成率趋势'),
                      AppSurfaceCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(height: 200, child: _lineChart(data)),
                      ),
                      const AppSectionHeader(title: '项目时间占比'),
                      AppSurfaceCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: data.projectTimeShare.isEmpty
                            ? Text('暂无工时数据', style: Theme.of(context).textTheme.bodyMedium)
                            : SizedBox(height: 200, child: _pieChart(data)),
                      ),
                      const AppSectionHeader(title: '工作时段分布'),
                      AppSurfaceCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(height: 140, child: _barChart(data)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _lineChart(dynamic data) {
    final pts = data.dailyCompletion as List;
    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), (pts[i].pct as int).toDouble())],
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
        ),
      ],
    ));
  }

  Widget _pieChart(dynamic data) {
    final shares = data.projectTimeShare as List;
    return PieChart(PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 36,
      sections: [
        for (var i = 0; i < shares.length; i++)
          PieChartSectionData(
            value: (shares[i].minutes as int).toDouble().clamp(1, double.infinity),
            title: '${(shares[i].pct as double).toStringAsFixed(0)}%',
            radius: 64,
            color: AppColors.chartPalette[i % AppColors.chartPalette.length],
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
      ],
    ));
  }

  Widget _barChart(dynamic data) {
    final hours = data.hourlyDistribution as List;
    if (hours.isEmpty) {
      return Center(child: Text('暂无数据', style: Theme.of(context).textTheme.bodyMedium));
    }
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < hours.length; i++)
          BarChartGroupData(
            x: hours[i].hour as int,
            barRods: [
              BarChartRodData(
                toY: (hours[i].minutes as int).toDouble(),
                color: AppColors.primary,
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
      ],
    ));
  }
}
