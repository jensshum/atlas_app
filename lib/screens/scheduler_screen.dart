import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SchedulerState>().startPolling();
    });
  }

  @override
  void dispose() {
    context.read<SchedulerState>().stopPolling();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulerState>(
      builder: (context, state, _) {
        return Column(
          children: [
            _SchedulerHeader(state: state),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
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
            TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Tasks'), Tab(text: 'Log')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TasksTab(state: state),
                  _LogTab(state: state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _SchedulerHeader extends StatelessWidget {
  final SchedulerState state;
  const _SchedulerHeader({required this.state});

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
                      ? Icons.event_repeat_rounded
                      : Icons.event_busy_rounded,
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
                      'Scheduler',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AtlasColors.textPrimary,
                      ),
                    ),
                    if (status != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${status.taskCount} tasks',
                          style: const TextStyle(
                            color: AtlasColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: running,
                onChanged: (val) => state.toggleScheduler(val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tasks tab ────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  final SchedulerState state;
  const _TasksTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: state.loadingTasks && state.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.refreshTasks,
              color: AtlasColors.gold,
              child: state.tasks.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AtlasColors.surfaceContainer,
                                  border: Border.all(
                                      color: AtlasColors.border),
                                ),
                                child: const Icon(
                                  Icons.event_repeat_rounded,
                                  size: 28,
                                  color: AtlasColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No scheduled tasks',
                                style: TextStyle(
                                  color: AtlasColors.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: state.tasks.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => _TaskCard(
                        task: state.tasks[index],
                        state: state,
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, state),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, SchedulerState state) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateTaskDialog(state: state),
    );
  }
}

// ─── Task card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final ScheduledTask task;
  final SchedulerState state;
  const _TaskCard({required this.task, required this.state});

  static final _dateFmt = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context) {
    final lastRun = task.lastRunAt != null
        ? _dateFmt
            .format(DateTime.parse(task.lastRunAt!).toLocal())
        : 'Never';

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AtlasColors.errorSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AtlasColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Delete "${task.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => state.deleteTask(task.id),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.enabled
                            ? AtlasColors.success
                            : AtlasColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Switch(
                      value: task.enabled,
                      onChanged: (val) =>
                          state.toggleTask(task.id, enabled: val),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AtlasColors.goldSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AtlasColors.gold
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          _cronHuman(task.cronExpression),
                          style: const TextStyle(
                            color: AtlasColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: AtlasColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last run: $lastRun',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AtlasColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      if (task.lastResult != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.lastResult!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AtlasColors.textTertiary,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => _runNow(context),
                            icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16),
                            label: const Text('Run Now',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AtlasColors.gold,
                              side: const BorderSide(
                                color: AtlasColors.goldDark,
                                width: 0.5,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cronHuman(String cron) {
    final parts = cron.split(' ');
    if (parts.length != 5) return cron;
    final min = parts[0];
    final hour = parts[1];
    final dow = parts[4];

    if (min == '*' && hour == '*') return 'Every minute';
    if (min.startsWith('*/')) {
      return 'Every ${min.substring(2)} minutes';
    }
    if (hour.startsWith('*/')) {
      return 'Every ${hour.substring(2)} hours';
    }
    if (dow == '*') {
      return 'Daily at ${hour.padLeft(2, '0')}:${min.padLeft(2, '0')}';
    }
    final days = dow
        .split(',')
        .map((d) => [
              'Sun',
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat'
            ][int.parse(d)])
        .join('/');
    return '$days at ${hour.padLeft(2, '0')}:${min.padLeft(2, '0')}';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AtlasColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AtlasColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                task.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AtlasColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.cronExpression,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AtlasColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'PROMPT',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 1,
                  color: AtlasColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AtlasColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AtlasColors.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  task.prompt,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AtlasColors.textPrimary,
                  ),
                ),
              ),
              if (task.lastResult != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'LAST RESULT',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 1,
                    color: AtlasColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AtlasColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AtlasColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    task.lastResult!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AtlasColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runNow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Running task...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This may take several minutes',
                      style: TextStyle(
                        fontSize: 13,
                        color: AtlasColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = await state.runTask(task.id);
    if (context.mounted) Navigator.of(context).pop();

    if (result != null) {
      final entry = result['entry'] as Map<String, dynamic>?;
      final success = result['ok'] as bool? ?? false;
      final resultText =
          entry?['result'] as String? ?? 'Done';
      messenger.showSnackBar(SnackBar(
        content: Text(success ? resultText : 'Skipped: $resultText'),
        backgroundColor:
            success ? AtlasColors.success : AtlasColors.warning,
      ));
    }
  }
}

// ─── Create task dialog ───────────────────────────────────────────────────────

class _CreateTaskDialog extends StatefulWidget {
  final SchedulerState state;
  const _CreateTaskDialog({required this.state});

  @override
  State<_CreateTaskDialog> createState() =>
      _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _nameCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _cronCtrl = TextEditingController();
  bool _cronMode = false;

  int _hour = 9;
  int _minute = 0;
  String _frequency = 'daily';

  String get _generatedCron {
    switch (_frequency) {
      case 'hourly':
        return '$_minute * * * *';
      case 'daily':
        return '$_minute $_hour * * *';
      case 'every15':
        return '*/15 * * * *';
      case 'every30':
        return '*/30 * * * *';
      default:
        return '$_minute $_hour * * *';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _promptCtrl.dispose();
    _cronCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final prompt = _promptCtrl.text.trim();
    final cron =
        _cronMode ? _cronCtrl.text.trim() : _generatedCron;

    if (name.isEmpty || prompt.isEmpty || cron.isEmpty) return;

    Navigator.of(context).pop();
    await widget.state.createTask(name, prompt, cron);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Scheduled Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Task name',
                hintText: 'Check LinkedIn posts',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText:
                    'Open LinkedIn, scroll through the first 3 posts...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 1,
                    color: AtlasColors.textTertiary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _cronMode = !_cronMode),
                  child: Text(
                      _cronMode ? 'Use helper' : 'Custom cron'),
                ),
              ],
            ),
            if (!_cronMode) ...[
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                dropdownColor: AtlasColors.surfaceContainer,
                items: const [
                  DropdownMenuItem(
                      value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(
                      value: 'hourly', child: Text('Hourly')),
                  DropdownMenuItem(
                      value: 'every15',
                      child: Text('Every 15 minutes')),
                  DropdownMenuItem(
                      value: 'every30',
                      child: Text('Every 30 minutes')),
                ],
                onChanged: (val) =>
                    setState(() => _frequency = val!),
                decoration:
                    const InputDecoration(labelText: 'Frequency'),
              ),
              if (_frequency == 'daily' ||
                  _frequency == 'hourly') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_frequency == 'daily') ...[
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _hour,
                          dropdownColor:
                              AtlasColors.surfaceContainer,
                          items: List.generate(
                            24,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(
                                  '${i.toString().padLeft(2, '0')}h'),
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _hour = val!),
                          decoration: const InputDecoration(
                              labelText: 'Hour'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _minute,
                        dropdownColor:
                            AtlasColors.surfaceContainer,
                        items: [0, 15, 30, 45]
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                      '${m.toString().padLeft(2, '0')}m'),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _minute = val!),
                        decoration: const InputDecoration(
                            labelText: 'Minute'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AtlasColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _generatedCron,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AtlasColors.textSecondary,
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _cronCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cron expression',
                  hintText: '0 9 * * *',
                  helperText: 'min hour dom month dow',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ─── Log tab ──────────────────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final SchedulerState state;
  const _LogTab({required this.state});

  static final _dateFmt = DateFormat('MMM d, HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return state.loadingLog && state.log.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: state.refreshLog,
            color: AtlasColors.gold,
            child: state.log.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AtlasColors.surfaceContainer,
                                border: Border.all(
                                    color: AtlasColors.border),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                size: 28,
                                color: AtlasColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No run history',
                              style: TextStyle(
                                color: AtlasColors.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: state.log.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry =
                          state.log[state.log.length - 1 - index];
                      final time = _dateFmt.format(
                        DateTime.fromMillisecondsSinceEpoch(
                            entry.timestamp),
                      );
                      return Container(
                        decoration: BoxDecoration(
                          color: AtlasColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AtlasColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: entry.success
                                      ? AtlasColors.success
                                      : AtlasColors.error,
                                  borderRadius:
                                      const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft:
                                        Radius.circular(12),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            entry.success
                                                ? Icons
                                                    .check_circle_rounded
                                                : Icons
                                                    .cancel_rounded,
                                            size: 16,
                                            color: entry.success
                                                ? AtlasColors
                                                    .success
                                                : AtlasColors
                                                    .error,
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.taskName,
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.result,
                                        maxLines: 2,
                                        overflow: TextOverflow
                                            .ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AtlasColors
                                              .textTertiary,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${entry.turns} turns  ·  $time',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AtlasColors
                                              .textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }
}
