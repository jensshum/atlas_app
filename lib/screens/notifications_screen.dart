import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AtlasColors.errorSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AtlasColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                        color: AtlasColors.error, fontSize: 12),
                  ),
                ),
              ),
            Expanded(
              child: state.loadingLog && state.log.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: state.refreshLog,
                      color: AtlasColors.gold,
                      child: state.log.isEmpty
                          ? const _EmptyLog()
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: state.log.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) => _LogEntry(
                                entry: state
                                    .log[state.log.length - 1 - index],
                              ),
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Status header ────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final NotificationsState state;
  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final running = status?.running ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: running
                      ? AtlasColors.success.withValues(alpha: 0.1)
                      : AtlasColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: running
                        ? AtlasColors.success.withValues(alpha: 0.3)
                        : AtlasColors.border,
                  ),
                ),
                child: Icon(
                  running
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: running
                      ? AtlasColors.success
                      : AtlasColors.textTertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Watcher',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AtlasColors.textPrimary,
                      ),
                    ),
                    if (status != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            _MiniStat(
                              label: 'Queue',
                              value: '${status.queueLength}',
                            ),
                            const SizedBox(width: 12),
                            _MiniStat(
                              label: 'Filters',
                              value: '${status.filterCount}',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: running,
                onChanged: (val) => state.toggleWatcher(val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AtlasColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AtlasColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─── Empty log ────────────────────────────────────────────────────────────────

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtlasColors.surfaceContainer,
                  border: Border.all(color: AtlasColors.border),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 28,
                  color: AtlasColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No notifications logged yet',
                style: TextStyle(
                  color: AtlasColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Log entry ────────────────────────────────────────────────────────────────

class _LogEntry extends StatelessWidget {
  final NotificationLogEntry entry;
  const _LogEntry({required this.entry});

  static const _actionColors = {
    'act': AtlasColors.success,
    'alert': AtlasColors.warning,
    'log': AtlasColors.info,
    'ignore': AtlasColors.textTertiary,
    'skip': Color(0xFFE0915B),
    'error': AtlasColors.error,
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
    final color =
        _actionColors[entry.action] ?? AtlasColors.textTertiary;
    final appName = _appNames[entry.packageName] ?? entry.packageName;
    final time = DateFormat('MMM d, HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AtlasColors.border, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.action.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          appName,
                          style: const TextStyle(
                            color: AtlasColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AtlasColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (entry.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AtlasColors.textTertiary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
