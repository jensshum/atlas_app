import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  static const _shortTimeout = Duration(seconds: 5);
  static const _longTimeout = Duration(minutes: 5);

  ApiClient(this.baseUrl);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> _get(String path, {Duration? timeout}) async {
    final response = await http
        .get(_uri(path), headers: _headers)
        .timeout(timeout ?? _shortTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {Duration? timeout}) async {
    final response = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(timeout ?? _shortTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final response = await http
        .put(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_shortTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: _headers)
        .timeout(_shortTimeout);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        body['error'] as String? ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  // Health
  Future<HealthStatus> getHealth() async {
    final data = await _get('/health');
    return HealthStatus.fromJson(data);
  }

  // Commands
  Future<Map<String, dynamic>> sendCommand(String prompt) async {
    return _post('/command', {'prompt': prompt}, timeout: _longTimeout);
  }

  // Lock
  Future<LockStatus> getLockStatus() async {
    final data = await _get('/lock/status');
    return LockStatus.fromJson(data);
  }

  Future<void> releaseLock() async {
    await _post('/lock/release', {});
  }

  // Notifications
  Future<void> startNotifications() async {
    await _post('/notifications/start', {});
  }

  Future<void> stopNotifications() async {
    await _post('/notifications/stop', {});
  }

  Future<NotificationStatus> getNotificationStatus() async {
    final data = await _get('/notifications/status');
    return NotificationStatus.fromJson(data);
  }

  Future<List<NotificationLogEntry>> getNotificationLog() async {
    final data = await _get('/notifications/log');
    final log = data['log'] as List<dynamic>;
    return log.map((e) => NotificationLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Whitelist
  Future<List<String>> getWhitelist() async {
    final data = await _get('/filter/whitelist');
    return List<String>.from(data['packages'] as List);
  }

  Future<List<String>> addToWhitelist(String package) async {
    final data = await _post('/filter/whitelist/add', {'package': package});
    return List<String>.from(data['packages'] as List);
  }

  Future<List<String>> removeFromWhitelist(String package) async {
    final data = await _post('/filter/whitelist/remove', {'package': package});
    return List<String>.from(data['packages'] as List);
  }

  Future<List<String>> replaceWhitelist(List<String> packages) async {
    final data = await _put('/filter/whitelist', {'packages': packages});
    return List<String>.from(data['packages'] as List);
  }

  // Scheduler
  Future<SchedulerStatus> getSchedulerStatus() async {
    final data = await _get('/scheduler/status');
    return SchedulerStatus.fromJson(data);
  }

  Future<void> startScheduler() async {
    await _post('/scheduler/start', {});
  }

  Future<void> stopScheduler() async {
    await _post('/scheduler/stop', {});
  }

  Future<List<ScheduledTask>> getTasks() async {
    final data = await _get('/scheduler/tasks');
    final tasks = data['tasks'] as List<dynamic>;
    return tasks.map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScheduledTask> createTask(String name, String prompt, String cronExpression) async {
    final data = await _post('/scheduler/tasks', {
      'name': name,
      'prompt': prompt,
      'cronExpression': cronExpression,
    });
    return ScheduledTask.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await _delete('/scheduler/tasks/$id');
  }

  Future<void> toggleTask(String id, {required bool enabled}) async {
    await _post('/scheduler/tasks/$id/toggle', {'enabled': enabled});
  }

  Future<Map<String, dynamic>> runTask(String id) async {
    return _post('/scheduler/tasks/$id/run', {}, timeout: _longTimeout);
  }

  Future<List<SchedulerLogEntry>> getSchedulerLog() async {
    final data = await _get('/scheduler/log');
    final log = data['log'] as List<dynamic>;
    return log.map((e) => SchedulerLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
