import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/discovery_service.dart';
import '../models/models.dart';

enum ServerConnectionState { searching, connected, notFound }

class AppState extends ChangeNotifier {
  ServerConnectionState _connectionState = ServerConnectionState.searching;
  String? _serverIp;
  ApiClient? _client;
  int _scanProgress = 0;
  int _scanTotal = 254;

  ServerConnectionState get connectionState => _connectionState;
  String? get serverIp => _serverIp;
  ApiClient? get client => _client;
  int get scanProgress => _scanProgress;
  int get scanTotal => _scanTotal;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await _discover();
  }

  Future<void> _discover() async {
    _connectionState = ServerConnectionState.searching;
    _scanProgress = 0;
    notifyListeners();

    final ip = await DiscoveryService.discover(
      onProgress: (checked, total) {
        _scanProgress = checked;
        _scanTotal = total;
        notifyListeners();
      },
    );

    if (ip != null) {
      _serverIp = ip;
      _client = ApiClient('http://$ip:$_port');
      _connectionState = ServerConnectionState.connected;
    } else {
      _connectionState = ServerConnectionState.notFound;
    }
    notifyListeners();
  }

  Future<void> rescan() async {
    await DiscoveryService.clearCachedIp();
    _serverIp = null;
    _client = null;
    await _discover();
  }

  Future<void> useManualIp(String ip) async {
    final trimmed = ip.trim();
    final alive = await DiscoveryService.checkIp(trimmed);
    if (alive) {
      await DiscoveryService.cacheIp(trimmed);
      _serverIp = trimmed;
      _client = ApiClient('http://$trimmed:$_port');
      _connectionState = ServerConnectionState.connected;
      notifyListeners();
    } else {
      throw ApiException('Could not connect to $trimmed:$_port');
    }
  }

  void triggerRescanOnError() {
    if (_connectionState == ServerConnectionState.connected) {
      rescan();
    }
  }
}

const _port = 3000;

// ─── Command State ────────────────────────────────────────────────────────────

class CommandState extends ChangeNotifier {
  final AppState _app;
  final List<ChatMessage> messages = [];
  bool _loading = false;
  LockStatus? _lockStatus;
  Timer? _lockPoller;
  String? _error;

  CommandState(this._app);

  bool get loading => _loading;
  LockStatus? get lockStatus => _lockStatus;
  String? get error => _error;

  Future<void> sendCommand(String prompt) async {
    // Always show user message immediately, regardless of connection state.
    messages.add(ChatMessage(text: prompt, isUser: true));
    notifyListeners();

    final client = _app.client;
    if (client == null) {
      messages.add(ChatMessage(
          text: 'Not connected to Atlas. Check the connection status in the toolbar.',
          isUser: false));
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    _startLockPolling();

    try {
      final result = await client.sendCommand(prompt);
      final responseText = result['result'] as String? ?? result['error'] as String? ?? 'No response';
      final turns = result['turns'] as int?;
      messages.add(ChatMessage(text: responseText, isUser: false, turns: turns));
    } on ApiException catch (e) {
      _error = e.message;
      messages.add(ChatMessage(text: 'Error: ${e.message}', isUser: false));
    } catch (e) {
      _error = e.toString();
      messages.add(ChatMessage(text: 'Error: $e', isUser: false));
      _app.triggerRescanOnError();
    } finally {
      _loading = false;
      _stopLockPolling();
      notifyListeners();
    }
  }

  void addVoiceMessage(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }

  Future<void> releaseLock() async {
    try {
      await _app.client?.releaseLock();
      await _refreshLock();
    } catch (_) {}
  }

  void _startLockPolling() {
    _lockPoller = Timer.periodic(const Duration(seconds: 2), (_) => _refreshLock());
  }

  void _stopLockPolling() {
    _lockPoller?.cancel();
    _lockPoller = null;
    _lockStatus = null;
  }

  Future<void> _refreshLock() async {
    try {
      _lockStatus = await _app.client?.getLockStatus();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopLockPolling();
    super.dispose();
  }
}

// ─── Notifications State ──────────────────────────────────────────────────────

class NotificationsState extends ChangeNotifier {
  final AppState _app;
  NotificationStatus? status;
  List<NotificationLogEntry> log = [];
  Timer? _poller;
  bool _loadingLog = false;
  String? _error;

  NotificationsState(this._app);

  bool get loadingLog => _loadingLog;
  String? get error => _error;

  void startPolling() {
    _refreshStatus();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refreshStatus());
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _refreshStatus() async {
    try {
      status = await _app.client?.getNotificationStatus();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> toggleWatcher(bool start) async {
    try {
      if (start) {
        await _app.client?.startNotifications();
      } else {
        await _app.client?.stopNotifications();
      }
      await _refreshStatus();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshLog() async {
    _loadingLog = true;
    notifyListeners();
    try {
      log = await _app.client?.getNotificationLog() ?? [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loadingLog = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

// ─── Filter State ─────────────────────────────────────────────────────────────

class FilterState extends ChangeNotifier {
  final AppState _app;
  List<String> packages = [];
  bool _loading = false;
  String? _error;

  FilterState(this._app);

  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      packages = await _app.client?.getWhitelist() ?? [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addPackage(String pkg) async {
    try {
      packages = await _app.client?.addToWhitelist(pkg) ?? packages;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> removePackage(String pkg) async {
    try {
      packages = await _app.client?.removeFromWhitelist(pkg) ?? packages;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }
}

// ─── Scheduler State ──────────────────────────────────────────────────────────

class SchedulerState extends ChangeNotifier {
  final AppState _app;
  SchedulerStatus? status;
  List<ScheduledTask> tasks = [];
  List<SchedulerLogEntry> log = [];
  Timer? _poller;
  bool _loadingTasks = false;
  bool _loadingLog = false;
  String? _error;

  SchedulerState(this._app);

  bool get loadingTasks => _loadingTasks;
  bool get loadingLog => _loadingLog;
  String? get error => _error;

  void startPolling() {
    _refreshStatus();
    refreshTasks();
    _poller = Timer.periodic(const Duration(seconds: 10), (_) => _refreshStatus());
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _refreshStatus() async {
    try {
      status = await _app.client?.getSchedulerStatus();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshTasks() async {
    _loadingTasks = true;
    notifyListeners();
    try {
      tasks = await _app.client?.getTasks() ?? [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loadingTasks = false;
    notifyListeners();
  }

  Future<void> toggleScheduler(bool start) async {
    try {
      if (start) {
        await _app.client?.startScheduler();
      } else {
        await _app.client?.stopScheduler();
      }
      await _refreshStatus();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createTask(String name, String prompt, String cron) async {
    try {
      await _app.client?.createTask(name, prompt, cron);
      _error = null;
      await refreshTasks(); // refresh from server for consistent data format
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _app.client?.deleteTask(id);
      tasks.removeWhere((t) => t.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> toggleTask(String id, {required bool enabled}) async {
    try {
      await _app.client?.toggleTask(id, enabled: enabled);
      final idx = tasks.indexWhere((t) => t.id == id);
      if (idx >= 0) tasks[idx] = tasks[idx].copyWith(enabled: enabled);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> runTask(String id) async {
    try {
      final result = await _app.client?.runTask(id);
      _error = null;
      await refreshTasks(); // refresh to pick up updated lastRunAt/lastResult
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshLog() async {
    _loadingLog = true;
    notifyListeners();
    try {
      log = await _app.client?.getSchedulerLog() ?? [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loadingLog = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
