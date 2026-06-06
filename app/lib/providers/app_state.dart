import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/routine.dart';
import '../models/summary.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  AppState({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  final dateFmt = DateFormat('yyyy-MM-dd');

  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? selectedCategory;

  List<Task> tasks = [];
  List<Routine> routines = [];
  List<BestMeEvent> events = [];
  List<ReminderItem> reminders = [];
  DailySummary? summary;

  bool loading = false;
  String? error;

  static const categories = [
    ('life', 'Life', 0xFF6C9BCF),
    ('work', 'Work', 0xFFE8A87C),
    ('exercise', 'Exercise', 0xFF85CDCA),
    ('other', 'Other', 0xFFB8B8B8),
  ];

  Future<void> refreshAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([
        loadTasks(),
        loadRoutines(),
        loadEvents(),
        loadReminders(),
      ]);
      await _api.generateRoutineTasks(selectedDate);
      await loadTasks();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks() async {
    tasks = await _api.getTasks(selectedDate, category: selectedCategory);
    notifyListeners();
  }

  Future<void> loadRoutines() async {
    routines = await _api.getRoutines();
    notifyListeners();
  }

  Future<void> loadEvents() async {
    events = await _api.getEvents();
    notifyListeners();
  }

  Future<void> loadReminders() async {
    reminders = await _api.getReminders();
    notifyListeners();
  }

  Future<void> loadSummary() async {
    loading = true;
    notifyListeners();
    try {
      summary = await _api.getSummary(selectedDate);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setDate(DateTime date) async {
    selectedDate = dateFmt.format(date);
    await refreshAll();
  }

  void setCategory(String? cat) {
    selectedCategory = cat;
    loadTasks();
  }

  Future<void> addTask({
    required String title,
    required String category,
    String? description,
    bool needsVerification = false,
  }) async {
    final status = needsVerification ? 'needs_verification' : 'pending';
    await _api.createTask(Task(
      id: '',
      title: title,
      description: description,
      category: category,
      date: selectedDate,
      status: status,
      needsVerification: needsVerification,
    ));
    await loadTasks();
  }

  Future<void> markDone(Task task) => _updateStatus(task, 'done');
  Future<void> markNeedsVerification(Task task) => _updateStatus(task, 'needs_verification');
  Future<void> markPending(Task task) => _updateStatus(task, 'pending');

  Future<void> _updateStatus(Task task, String status) async {
    await _api.updateTaskStatus(task.id, status);
    await loadTasks();
  }

  Future<int> runAiPlan(String input) async {
    final plan = await _api.generatePlan(selectedDate, input);
    return _api.applyPlan(plan);
  }

  Future<void> addRoutine({
    required String title,
    required String category,
    String? description,
    bool needsVerification = false,
  }) async {
    await _api.createRoutine(Routine(
      id: '',
      title: title,
      category: category,
      description: description,
      needsVerification: needsVerification,
    ));
    await loadRoutines();
  }

  Future<void> addEvent({
    required String title,
    required String type,
    required String date,
    int remindDaysBefore = 3,
    String? notes,
  }) async {
    await _api.createEvent(BestMeEvent(
      id: '',
      title: title,
      type: type,
      date: date,
      remindDaysBefore: remindDaysBefore,
      notes: notes,
    ));
    await loadEvents();
    await loadReminders();
  }

  List<Task> tasksForCategory(String cat) =>
      tasks.where((t) => t.category == cat).toList();
}
