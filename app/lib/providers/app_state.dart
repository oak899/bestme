import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/growth.dart';
import '../models/routine.dart';
import '../models/summary.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  AppState({ApiService? api, AuthService? auth}) : auth = auth ?? AuthService() {
    _api = api ?? ApiService(getToken: () => this.auth.token);
  }

  final AuthService auth;
  late ApiService _api;
  final dateFmt = DateFormat('yyyy-MM-dd');

  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? selectedCategory;
  ThemeMode themeMode = ThemeMode.system;

  List<Task> tasks = [];
  List<Routine> routines = [];
  List<BestMeEvent> events = [];
  List<ReminderItem> reminders = [];
  DailySummary? summary;
  DashboardData? dashboard;
  DailyPlan? dailyPlan;
  List<Project> projects = [];
  List<KanbanColumn> kanban = [];
  bool kanbanLoading = false;
  bool kanbanLoaded = false;
  String? kanbanError;
  bool dailyPlanLoading = false;
  String? dailyPlanError;
  UserSettings? settings;
  ReportsData? reports;
  String reportsPeriod = 'week';
  TimeStats? timeStats;
  TimeEntry? activeTimer;

  bool loading = false;
  bool initialized = false;
  Future<void>? _refreshFuture;
  bool serverSupportsAuth = false;
  String serverVersion = '';
  String? error;

  static const categories = [
    ('life', 'Life', 0xFF6C9BCF),
    ('work', 'Work', 0xFFE8A87C),
    ('exercise', 'Exercise', 0xFF85CDCA),
    ('other', 'Other', 0xFFB8B8B8),
  ];

  Future<void> init() async {
    await auth.load();
    try {
      final info = await _api.getApiInfo();
      serverVersion = info['version'] as String? ?? '';
      serverSupportsAuth = await _api.authEndpointsAvailable();
      if (!serverSupportsAuth && !auth.canUseApp) {
        await skipLogin();
      }
      await loadSettings();
    } catch (e) {
      error = e.toString();
      if (!auth.canUseApp) await skipLogin();
    }
    initialized = true;
    notifyListeners();
    unawaited(refreshAll());
    unawaited(loadActiveTimer());
  }

  Future<void> refreshAll() {
    return _refreshFuture ??= _refreshAllImpl().whenComplete(() => _refreshFuture = null);
  }

  Future<void> _refreshAllImpl() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _api.generateRoutineTasks(selectedDate);
      await Future.wait([
        loadTasks(),
        loadRoutines(),
        loadEvents(),
        loadReminders(),
        loadDashboard(),
        loadDailyPlan(),
        loadProjects(),
        loadTimeStats(),
      ]);
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

  Future<Task> loadTask(String id) => _api.getTask(id);

  Future<void> saveTask(Task task) async {
    if (task.id.isEmpty) {
      await _api.createTask(task);
    } else {
      await _api.updateTask(task);
    }
    await Future.wait([loadTasks(), loadDashboard()]);
  }

  Future<List<TaskHistory>> loadTaskHistory(String id) => _api.getTaskHistory(id);

  Future<List<TaskComment>> loadTaskComments(String id) => _api.getTaskComments(id);

  Future<List<Task>> loadSubtasks(String id) => _api.getSubtasks(id);

  Future<void> addTaskComment(String id, String body) async {
    await _api.addTaskComment(id, body);
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

  Future<void> loadDashboard() async {
    dashboard = await _api.getDashboard(selectedDate);
    notifyListeners();
  }

  Future<void> loadDailyPlan() async {
    dailyPlanLoading = true;
    dailyPlanError = null;
    notifyListeners();
    try {
      dailyPlan = await _api.getDailyPlan(selectedDate);
    } catch (e) {
      dailyPlanError = e.toString();
      dailyPlan = DailyPlan(planDate: selectedDate);
    } finally {
      dailyPlanLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveDailyPlan(DailyPlan plan) async {
    dailyPlan = await _api.saveDailyPlan(plan);
    notifyListeners();
  }

  Future<void> copyYesterdayPlan() async {
    dailyPlan = await _api.copyYesterdayPlan(selectedDate);
    notifyListeners();
  }

  Future<void> loadProjects() async {
    projects = await _api.getProjects();
    notifyListeners();
  }

  Future<void> addProject({required String name, String goal = ''}) async {
    await _api.createProject(Project(id: 0, name: name, goal: goal));
    await loadProjects();
  }

  static List<KanbanColumn> emptyKanbanColumns() => [
        KanbanColumn(status: 'backlog', tasks: []),
        KanbanColumn(status: 'todo', tasks: []),
        KanbanColumn(status: 'in_progress', tasks: []),
        KanbanColumn(status: 'blocked', tasks: []),
        KanbanColumn(status: 'done', tasks: []),
      ];

  Future<void> loadKanban({int? projectId}) async {
    kanbanLoading = true;
    kanbanError = null;
    notifyListeners();
    try {
      final cols = await _api.getKanban(projectId: projectId);
      kanban = cols.isNotEmpty ? cols : emptyKanbanColumns();
      kanbanLoaded = true;
    } catch (e) {
      kanbanError = e.toString();
      kanban = emptyKanbanColumns();
      kanbanLoaded = true;
    } finally {
      kanbanLoading = false;
      notifyListeners();
    }
  }

  Future<void> reorderKanban(List<Map<String, dynamic>> updates, {int? projectId}) async {
    kanban = await _api.reorderKanban(updates, projectId: projectId);
    await loadTasks();
    notifyListeners();
  }

  Future<void> loadReports({String? period}) async {
    if (period != null) reportsPeriod = period;
    reports = await _api.getReports(selectedDate, period: reportsPeriod);
    notifyListeners();
  }

  Future<ProjectDetail> loadProjectDetail(int id) => _api.getProjectDetail(id);

  Future<void> loadSettings() async {
    try {
      settings = await _api.getSettings();
    } catch (_) {
      settings = UserSettings();
    }
    themeMode = switch (settings?.theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> saveSettings(UserSettings s) async {
    settings = await _api.saveSettings(s);
    themeMode = switch (s.theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> loadTimeStats() async {
    timeStats = await _api.getTimeStats(selectedDate);
    notifyListeners();
  }

  Future<void> loadActiveTimer() async {
    activeTimer = await _api.getActiveTimer();
    notifyListeners();
  }

  Future<void> startTimer(int taskId) async {
    activeTimer = await _api.startTimer(taskId);
    notifyListeners();
  }

  Future<void> pauseTimer() async {
    if (activeTimer == null) return;
    activeTimer = await _api.pauseTimer(activeTimer!.id);
    notifyListeners();
  }

  Future<void> resumeTimer() async {
    if (activeTimer == null) return;
    activeTimer = await _api.resumeTimer(activeTimer!.id);
    notifyListeners();
  }

  Future<void> stopTimer() async {
    if (activeTimer == null) return;
    await _api.stopTimer(activeTimer!.id);
    activeTimer = null;
    await Future.wait([loadTimeStats(), loadDashboard()]);
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
    String priority = 'medium',
    int? projectId,
    String? dueDate,
    int estimateMinutes = 0,
  }) async {
    final status = needsVerification ? 'blocked' : 'todo';
    await _api.createTask(Task(
      id: '',
      title: title,
      description: description,
      category: category,
      date: selectedDate,
      status: status,
      needsVerification: needsVerification,
      priority: priority,
      projectId: projectId,
      dueDate: dueDate,
      estimateMinutes: estimateMinutes,
    ));
    await loadTasks();
  }

  Future<void> markDone(Task task) => _updateStatus(task, 'done');
  Future<void> markNeedsVerification(Task task) => _updateStatus(task, 'blocked');
  Future<void> markPending(Task task) => _updateStatus(task, 'todo');
  Future<void> markInProgress(Task task) => _updateStatus(task, 'in_progress');
  Future<void> markBacklog(Task task) => _updateStatus(task, 'backlog');

  Future<void> _updateStatus(Task task, String status) async {
    await _api.updateTaskStatus(task.id, status);
    await loadTasks();
  }

  Future<void> updateTaskStatus(Task task, String status) async {
    await _api.updateTaskStatus(task.id, status);
    await Future.wait([loadTasks(), loadDashboard()]);
  }

  Future<({int count, String? notes})> runAiPlan(String input) async {
    final outcome = await _api.planAndApply(selectedDate, input);
    await loadTasks();
    return outcome;
  }

  Future<void> skipLogin() async {
    await auth.skipLogin();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await _api.login(email, password);
    if (r.token.isNotEmpty) await auth.save(r.token, r.email);
    notifyListeners(); // Notify immediately so router can redirect
    // Don't block on refreshAll - do it in background
    unawaited(refreshAll());
  }

  Future<void> register(String email, String password, String name) async {
    final r = await _api.register(email, password, name);
    if (r.token.isNotEmpty) await auth.save(r.token, r.email);
    notifyListeners(); // Notify immediately so router can redirect
    // Don't block on refreshAll - do it in background
    unawaited(refreshAll());
  }

  Future<void> logout() async {
    await auth.clear();
    notifyListeners();
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

  List<Task> tasksForCategory(String cat) => tasks.where((t) => t.category == cat).toList();
}
