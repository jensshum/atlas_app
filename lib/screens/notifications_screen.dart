import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<NotificationsState>();
      state.startPolling();
      state.refreshLog();
    });
  }

  @override
  void dispose() {
    context.read<NotificationsState>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsState>(
      builder: (context, state, _) {
        return Column(
          children: [
            _StatusHeader(state: state),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Expanded(
              child: state.loadingLog && state.log.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: state.refreshLog,
                      child: state.log.isEmpty
                          ? const _EmptyLog()
                          : ListView.builder(
                              itemCount: state.log.length,
                              itemBuilder: (context, index) =>
                                  _LogEntry(entry: state.log[state.log.length - 1 - index]),
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final NotificationsState state;
  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final running = status?.running ?? false;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notification Watcher', style: Theme.of(context).textTheme.titleMedium),
                if (status != null)
                  Text(
                    'Queue: ${status.queueLength} • Filters: ${status.filterCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const Spacer(),
            Switch(
              value: running,
              onChanged: (val) => state.toggleWatcher(val),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.notifications_none, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text('No notifications logged yet', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogEntry extends StatelessWidget {
  final NotificationLogEntry entry;
  const _LogEntry({required this.entry});

  static const _actionColors = {
    'act': Colors.green,
    'log': Colors.blue,
    'ignore': Colors.grey,
    'skip': Colors.orange,
    'error': Colors.red,
  };

  static const _actionIcons = {
    'act': Icons.play_circle,
    'log': Icons.edit_note,
    'ignore': Icons.do_not_disturb,
    'skip': Icons.skip_next,
    'error': Icons.error_outline,
  };

  static final _appNames = {
    'com.google.android.gm': 'Gmail',
    'com.whatsapp': 'WhatsApp',
    'com.slack': 'Slack',
    'com.discord': 'Discord',
    'com.facebook.orca': 'Messenger',
    'com.instagram.android': 'Instagram',
    'com.twitter.android': 'X (Twitter)',
    'com.google.android.apps.messaging': 'Google Messages',
    'com.linkedin.android': 'LinkedIn',
    'com.facebook.katana': 'Facebook',
  };

  @override
  Widget build(BuildContext context) {
    final color = _actionColors[entry.action] ?? Colors.grey;
    final icon = _actionIcons[entry.action] ?? Icons.help_outline;
    final appName = _appNames[entry.packageName] ?? entry.packageName;
    final time = DateFormat('MMM d, HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appName, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(entry.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.action.toUpperCase(),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
