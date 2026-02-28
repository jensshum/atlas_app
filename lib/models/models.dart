// Health
class HealthStatus {
  final String status;
  final String agent;
  final double uptime;

  HealthStatus({required this.status, required this.agent, required this.uptime});

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        status: json['status'] as String,
        agent: json['agent'] as String,
        uptime: (json['uptime'] as num).toDouble(),
      );
}

// Lock
class LockStatus {
  final bool locked;
  final String? owner;
  final String? ownerType;
  final int? acquiredAt;

  LockStatus({required this.locked, this.owner, this.ownerType, this.acquiredAt});

  factory LockStatus.fromJson(Map<String, dynamic> json) => LockStatus(
        locked: json['locked'] as bool,
        owner: json['owner'] as String?,
        ownerType: json['ownerType'] as String?,
        acquiredAt: json['acquiredAt'] as int?,
      );
}

// Notification status
class NotificationStatus {
  final bool running;
  final int queueLength;
  final int filterCount;

  NotificationStatus({required this.running, required this.queueLength, required this.filterCount});

  factory NotificationStatus.fromJson(Map<String, dynamic> json) => NotificationStatus(
        running: json['running'] as bool,
        queueLength: json['queueLength'] as int,
        filterCount: json['filterCount'] as int,
      );
}

// Notification log entry
class NotificationLogEntry {
  final int timestamp;
  final String packageName;
  final String title;
  final String action;
  final String reason;

  NotificationLogEntry({
    required this.timestamp,
    required this.packageName,
    required this.title,
    required this.action,
    required this.reason,
  });

  factory NotificationLogEntry.fromJson(Map<String, dynamic> json) => NotificationLogEntry(
        timestamp: json['timestamp'] as int,
        packageName: json['packageName'] as String,
        title: json['title'] as String,
        action: json['action'] as String,
        reason: json['reason'] as String,
      );
}

// Scheduler status
class SchedulerStatus {
  final bool running;
  final int taskCount;

  SchedulerStatus({required this.running, required this.taskCount});

  factory SchedulerStatus.fromJson(Map<String, dynamic> json) => SchedulerStatus(
        running: json['running'] as bool,
        taskCount: json['taskCount'] as int,
      );
}

// Scheduled task
class ScheduledTask {
  final String id;
  final String name;
  final String prompt;
  final String cronExpression;
  final bool enabled;
  final String createdAt;
  final String? lastRunAt;
  final String? lastResult;

  ScheduledTask({
    required this.id,
    required this.name,
    required this.prompt,
    required this.cronExpression,
    required this.enabled,
    required this.createdAt,
    this.lastRunAt,
    this.lastResult,
  });

  factory ScheduledTask.fromJson(Map<String, dynamic> json) => ScheduledTask(
        id: json['id'] as String,
        name: json['name'] as String,
        prompt: json['prompt'] as String,
        cronExpression: json['cronExpression'] as String,
        enabled: json['enabled'] as bool,
        createdAt: json['createdAt']?.toString() ?? '',
        lastRunAt: json['lastRunAt'] as String?,
        lastResult: json['lastResult'] as String?,
      );

  ScheduledTask copyWith({bool? enabled}) => ScheduledTask(
        id: id,
        name: name,
        prompt: prompt,
        cronExpression: cronExpression,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
        lastRunAt: lastRunAt,
        lastResult: lastResult,
      );
}

// Scheduler log entry
class SchedulerLogEntry {
  final int timestamp;
  final String taskId;
  final String taskName;
  final bool success;
  final String result;
  final int turns;

  SchedulerLogEntry({
    required this.timestamp,
    required this.taskId,
    required this.taskName,
    required this.success,
    required this.result,
    required this.turns,
  });

  factory SchedulerLogEntry.fromJson(Map<String, dynamic> json) => SchedulerLogEntry(
        timestamp: json['timestamp'] as int,
        taskId: json['taskId'] as String,
        taskName: json['taskName'] as String,
        success: json['success'] as bool,
        result: json['result'] as String,
        turns: json['turns'] as int,
      );
}

// Chat message for command screen
class ChatMessage {
  final String text;
  final bool isUser;
  final int? turns;

  ChatMessage({required this.text, required this.isUser, this.turns});
}
