import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/event.dart';
import '../models/growth.dart';
import '../models/routine.dart';
import '../models/summary.dart';
import '../models/task.dart';

class ApiService {
  ApiService({String? baseUrl, http.Client? client, this.getToken})
      : _base = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  final String _base;
  final http.Client _client;
  final String? Function()? getToken;

  static const _timeout = Duration(seconds: 90);

  Future<Map<String, dynamic>> getApiInfo() async {
    final res = await _client.get(Uri.parse(_base.endsWith('/') ? _base : '$_base')).timeout(_timeout);
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<bool> authEndpointsAvailable() async {
    try {
      final res = await _client
          .post(Uri.parse('$_base/auth/login'), headers: _headers, body: jsonEncode({'email': '_probe_', 'password': '_'}))
          .timeout(const Duration(seconds: 10));
      return res.statusCode != 404;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    final t = getToken?.call();
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<List<Task>> getTasks(String date, {String? category}) async {
    var url = '$_base/tasks?date=$date';
    if (category != null && category.isNotEmpty) url += '&category=$category';
    final res = await _client.get(Uri.parse(url), headers: _headers).timeout(_timeout);
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> getTask(String id) async {
    final res = await _client.get(Uri.parse('$_base/tasks/$id'), headers: _headers).timeout(_timeout);
    _check(res);
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> createTask(Task task) async {
    final res = await _client.post(Uri.parse('$_base/tasks'), headers: _headers, body: jsonEncode(task.toJson())).timeout(_timeout);
    _check(res);
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> updateTask(Task task) async {
    final res = await _client.put(Uri.parse('$_base/tasks/${task.id}'), headers: _headers, body: jsonEncode(task.toJson())).timeout(_timeout);
    _check(res);
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> updateTaskStatus(String id, String status) async {
    final res = await _client
        .patch(Uri.parse('$_base/tasks/$id/status'), headers: _headers, body: jsonEncode({'status': status}))
        .timeout(_timeout);
    _check(res);
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<TaskHistory>> getTaskHistory(String id) async {
    final res = await _client.get(Uri.parse('$_base/tasks/$id/history'), headers: _headers).timeout(_timeout);
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => TaskHistory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TaskComment>> getTaskComments(String id) async {
    final res = await _client.get(Uri.parse('$_base/tasks/$id/comments'), headers: _headers).timeout(_timeout);
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => TaskComment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TaskComment> addTaskComment(String id, String body) async {
    final res = await _client
        .post(Uri.parse('$_base/tasks/$id/comments'), headers: _headers, body: jsonEncode({'body': body}))
        .timeout(_timeout);
    _check(res);
    return TaskComment.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<int> generateRoutineTasks(String date) async {
    final res = await _client
        .post(Uri.parse('$_base/tasks/generate-routines'), headers: _headers, body: jsonEncode({'date': date}))
        .timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<({int count, String? notes})> planAndApply(String date, String input) async {
    final res = await _client
        .post(Uri.parse('$_base/ai/plan-and-apply'), headers: _headers, body: jsonEncode({'date': date, 'input': input}))
        .timeout(_timeout);
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (count: body['count'] as int? ?? 0, notes: body['notes'] as String?);
  }

  Future<DailySummary> getSummary(String date) async {
    final res = await _client.post(Uri.parse('$_base/ai/summary'), headers: _headers, body: jsonEncode({'date': date})).timeout(_timeout);
    _check(res);
    return DailySummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Routine>> getRoutines() async {
    final res = await _client.get(Uri.parse('$_base/routines'), headers: _headers).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => Routine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Routine> createRoutine(Routine routine) async {
    final res = await _client.post(Uri.parse('$_base/routines'), headers: _headers, body: jsonEncode(routine.toJson())).timeout(_timeout);
    _check(res);
    return Routine.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<BestMeEvent>> getEvents() async {
    final res = await _client.get(Uri.parse('$_base/events'), headers: _headers).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => BestMeEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BestMeEvent> createEvent(BestMeEvent event) async {
    final res = await _client.post(Uri.parse('$_base/events'), headers: _headers, body: jsonEncode(event.toJson())).timeout(_timeout);
    _check(res);
    return BestMeEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ReminderItem>> getReminders() async {
    final res = await _client.get(Uri.parse('$_base/events/reminders'), headers: _headers).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => ReminderItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DashboardData> getDashboard(String date) async {
    final res = await _client.get(Uri.parse('$_base/dashboard?date=$date'), headers: _headers).timeout(_timeout);
    _check(res);
    return DashboardData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DailyPlan> getDailyPlan(String date) async {
    final res = await _client.get(Uri.parse('$_base/daily-plans?date=$date'), headers: _headers).timeout(_timeout);
    _check(res);
    return DailyPlan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DailyPlan> saveDailyPlan(DailyPlan plan) async {
    final res = await _client.post(Uri.parse('$_base/daily-plans'), headers: _headers, body: jsonEncode(plan.toJson())).timeout(_timeout);
    _check(res);
    return DailyPlan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DailyPlan> copyYesterdayPlan(String date) async {
    final res = await _client
        .post(Uri.parse('$_base/daily-plans/copy-yesterday'), headers: _headers, body: jsonEncode({'date': date}))
        .timeout(_timeout);
    _check(res);
    return DailyPlan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Project>> getProjects() async {
    final res = await _client.get(Uri.parse('$_base/projects'), headers: _headers).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Project> createProject(Project project) async {
    final res = await _client.post(Uri.parse('$_base/projects'), headers: _headers, body: jsonEncode(project.toJson())).timeout(_timeout);
    _check(res);
    return Project.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<KanbanColumn>> getKanban({int? projectId}) async {
    var url = '$_base/kanban';
    if (projectId != null && projectId > 0) url += '?project_id=$projectId';
    final res = await _client.get(Uri.parse(url), headers: _headers).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => KanbanColumn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<KanbanColumn>> reorderKanban(List<Map<String, dynamic>> updates, {int? projectId}) async {
    var url = '$_base/kanban/reorder';
    if (projectId != null && projectId > 0) url += '?project_id=$projectId';
    final res = await _client.post(Uri.parse(url), headers: _headers, body: jsonEncode({'updates': updates})).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => KanbanColumn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TimeEntry> startTimer(int taskId) async {
    final res = await _client.post(Uri.parse('$_base/time-entries/start'), headers: _headers, body: jsonEncode({'taskId': taskId})).timeout(_timeout);
    _check(res);
    return TimeEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TimeEntry?> getActiveTimer() async {
    final res = await _client.get(Uri.parse('$_base/time-entries/active'), headers: _headers).timeout(_timeout);
    _check(res);
    final body = jsonDecode(res.body);
    if (body == null) return null;
    return TimeEntry.fromJson(body as Map<String, dynamic>);
  }

  Future<TimeEntry> pauseTimer(int entryId) async {
    final res = await _client.post(Uri.parse('$_base/time-entries/$entryId/pause'), headers: _headers).timeout(_timeout);
    _check(res);
    return TimeEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TimeEntry> resumeTimer(int entryId) async {
    final res = await _client.post(Uri.parse('$_base/time-entries/$entryId/resume'), headers: _headers).timeout(_timeout);
    _check(res);
    return TimeEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TimeEntry> stopTimer(int entryId) async {
    final res = await _client.post(Uri.parse('$_base/time-entries/$entryId/stop'), headers: _headers).timeout(_timeout);
    _check(res);
    return TimeEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TimeStats> getTimeStats(String date) async {
    final res = await _client.get(Uri.parse('$_base/time-entries/stats?date=$date'), headers: _headers).timeout(_timeout);
    _check(res);
    return TimeStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<UserSettings> getSettings() async {
    final res = await _client.get(Uri.parse('$_base/settings'), headers: _headers).timeout(_timeout);
    _check(res);
    return UserSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<UserSettings> saveSettings(UserSettings s) async {
    final res = await _client.put(Uri.parse('$_base/settings'), headers: _headers, body: jsonEncode(s.toJson())).timeout(_timeout);
    _check(res);
    return UserSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ReportsData> getReports(String date, {String period = 'week'}) async {
    final res = await _client.get(Uri.parse('$_base/reports?date=$date&period=$period'), headers: _headers).timeout(_timeout);
    _check(res);
    return ReportsData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ProjectDetail> getProjectDetail(int id) async {
    final res = await _client.get(Uri.parse('$_base/projects/$id'), headers: _headers).timeout(_timeout);
    _check(res);
    return ProjectDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Task>> getSubtasks(String taskId) async {
    final res = await _client.get(Uri.parse('$_base/tasks/$taskId/subtasks'), headers: _headers).timeout(_timeout);
    _check(res);
    return (jsonDecode(res.body) as List).map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({String token, String email})> login(String email, String password) async {
    final res = await _client.post(Uri.parse('$_base/auth/login'), headers: _headers, body: jsonEncode({'email': email, 'password': password})).timeout(_timeout);
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;
    return (token: body['token'] as String? ?? '', email: user['email'] as String? ?? email);
  }

  Future<({String token, String email})> register(String email, String password, String name) async {
    final res = await _client
        .post(Uri.parse('$_base/auth/register'), headers: _headers, body: jsonEncode({'email': email, 'password': password, 'name': name}))
        .timeout(_timeout);
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;
    return (token: body['token'] as String? ?? '', email: user['email'] as String? ?? email);
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }
}
