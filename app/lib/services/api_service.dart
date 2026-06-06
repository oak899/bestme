import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/event.dart';
import '../models/routine.dart';
import '../models/summary.dart';
import '../models/task.dart';

class ApiService {
  ApiService({String? baseUrl}) : _base = baseUrl ?? AppConfig.apiBaseUrl;

  final String _base;

  Future<List<Task>> getTasks(String date, {String? category}) async {
    var url = '$_base/tasks?date=$date';
    if (category != null && category.isNotEmpty) {
      url += '&category=$category';
    }
    final res = await http.get(Uri.parse(url));
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask(Task task) async {
    final res = await http.post(
      Uri.parse('$_base/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    _check(res);
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> updateTaskStatus(String id, String status) async {
    final res = await http.patch(
      Uri.parse('$_base/tasks/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    _check(res);
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    final res = await http.delete(Uri.parse('$_base/tasks/$id'));
    _check(res);
  }

  Future<int> generateRoutineTasks(String date) async {
    final res = await http.post(
      Uri.parse('$_base/tasks/generate-routines'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'date': date}),
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['count'] as int? ?? 0;
  }

  Future<Map<String, dynamic>> generatePlan(String date, String input) async {
    final res = await http.post(
      Uri.parse('$_base/ai/plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'date': date, 'input': input}),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<int> applyPlan(Map<String, dynamic> plan) async {
    final res = await http.post(
      Uri.parse('$_base/ai/apply-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plan),
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['count'] as int? ?? 0;
  }

  Future<DailySummary> getSummary(String date) async {
    final res = await http.post(
      Uri.parse('$_base/ai/summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'date': date}),
    );
    _check(res);
    return DailySummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Routine>> getRoutines() async {
    final res = await http.get(Uri.parse('$_base/routines'));
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Routine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Routine> createRoutine(Routine routine) async {
    final res = await http.post(
      Uri.parse('$_base/routines'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(routine.toJson()),
    );
    _check(res);
    return Routine.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteRoutine(String id) async {
    final res = await http.delete(Uri.parse('$_base/routines/$id'));
    _check(res);
  }

  Future<List<BestMeEvent>> getEvents() async {
    final res = await http.get(Uri.parse('$_base/events'));
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => BestMeEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BestMeEvent> createEvent(BestMeEvent event) async {
    final res = await http.post(
      Uri.parse('$_base/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(event.toJson()),
    );
    _check(res);
    return BestMeEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ReminderItem>> getReminders() async {
    final res = await http.get(Uri.parse('$_base/events/reminders'));
    _check(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => ReminderItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }
}
