import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/app_state.dart';
import '../../widgets/task_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focused,
            calendarFormat: _format,
            selectedDayPredicate: (d) => DateUtils.isSameDay(d, selected),
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() => _focused = focusedDay);
              await state.setDate(selectedDay);
            },
            onFormatChanged: (f) => setState(() => _format = f),
            onPageChanged: (d) => _focused = d,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('yyyy-MM-dd').format(selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: state.tasks.isEmpty
                ? const Center(child: Text('该日无任务'))
                : ListView.builder(
                    itemCount: state.tasks.length,
                    itemBuilder: (_, i) => TaskTile(task: state.tasks[i], state: state),
                  ),
          ),
        ],
      ),
    );
  }
}
