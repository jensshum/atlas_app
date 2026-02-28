import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
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

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduler', style: Theme.of(context).textTheme.titleMedium),
                if (status != null)
                  Text('${status.taskCount} tasks', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const Spacer(),
            Switch(
              value: running,
              onChanged: (val) => state.toggleScheduler(val),
            ),
          ],
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
      body: state.loadingTasks && state.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.refreshTasks,
              child: state.tasks.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.schedule, size: 48, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 12),
                              Text('No scheduled tasks', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: state.tasks.length,
                      itemBuilder: (context, index) =>
                          _TaskCard(task: state.tasks[index], state: state),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, state),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, SchedulerState state) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateTaskDialog(state: state),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ScheduledTask task;
  final SchedulerState state;
  const _TaskCard({required this.task, required this.state});

  static final _dateFmt = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context) {
    final lastRun = task.lastRunAt != null
        ? _dateFmt.format(DateTime.parse(task.lastRunAt!).toLocal())
        : 'Never';

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Delete "${task.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) => state.deleteTask(task.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Switch(
                      value: task.enabled,
                      onChanged: (val) => state.toggleTask(task.id, enabled: val),
                    ),
                  ],
                ),
                Text(
                  _cronHuman(task.cronExpression),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text('Last run: $lastRun', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (task.lastResult != null)
                  Text(
                    task.lastResult!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _runNow(context),
                      child: const Text('Run Now'),
                    ),
                  ],
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
    if (min.startsWith('*/')) return 'Every ${min.substring(2)} minutes';
    if (hour.startsWith('*/')) return 'Every ${hour.substring(2)} hours';
    if (dow == '*') return 'Daily at ${hour.padLeft(2, '0')}:${min.padLeft(2, '0')}';
    final days = dow.split(',').map((d) => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][int.parse(d)]).join('/');
    return '$days at ${hour.padLeft(2, '0')}:${min.padLeft(2, '0')}';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.cronExpression, style: const TextStyle(fontFamily: 'monospace')),
              const Divider(height: 24),
              const Text('Prompt:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.prompt),
              if (task.lastResult != null) ...[
                const Divider(height: 24),
                const Text('Last result:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(task.lastResult!),
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
      builder: (_) => const AlertDialog(
        title: Text('Running task...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('This may take several minutes.'),
          ],
        ),
      ),
    );

    final result = await state.runTask(task.id);
    if (context.mounted) Navigator.of(context).pop();

    if (result != null) {
      final entry = result['entry'] as Map<String, dynamic>?;
      final success = result['ok'] as bool? ?? false;
      final resultText = entry?['result'] as String? ?? 'Done';
      messenger.showSnackBar(SnackBar(
        content: Text(success ? resultText : 'Skipped: $resultText'),
        backgroundColor: success ? Colors.green : Colors.orange,
      ));
    }
  }
}

// ─── Create task dialog ───────────────────────────────────────────────────────

class _CreateTaskDialog extends StatefulWidget {
  final SchedulerState state;
  const _CreateTaskDialog({required this.state});

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _nameCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _cronCtrl = TextEditingController();
  bool _cronMode = false; // false = helper, true = custom

  // Helper fields
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
    final cron = _cronMode ? _cronCtrl.text.trim() : _generatedCron;

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
              decoration: const InputDecoration(labelText: 'Task name', hintText: 'Check LinkedIn posts'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Open LinkedIn, scroll through the first 3 posts...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _cronMode = !_cronMode),
                  child: Text(_cronMode ? 'Use helper' : 'Custom cron'),
                ),
              ],
            ),
            if (!_cronMode) ...[
              DropdownButtonFormField<String>(
                value: _frequency,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                  DropdownMenuItem(value: 'every15', child: Text('Every 15 minutes')),
                  DropdownMenuItem(value: 'every30', child: Text('Every 30 minutes')),
                ],
                onChanged: (val) => setState(() => _frequency = val!),
                decoration: const InputDecoration(labelText: 'Frequency'),
              ),
              if (_frequency == 'daily' || _frequency == 'hourly') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_frequency == 'daily') ...[
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _hour,
                          items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}h'))),
                          onChanged: (val) => setState(() => _hour = val!),
                          decoration: const InputDecoration(labelText: 'Hour'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _minute,
                        items: [0, 15, 30, 45].map((m) => DropdownMenuItem(value: m, child: Text('${m.toString().padLeft(2, '0')}m'))).toList(),
                        onChanged: (val) => setState(() => _minute = val!),
                        decoration: const InputDecoration(labelText: 'Minute'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(_generatedCron, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Create')),
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
            child: state.log.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 12),
                            Text('No run history', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: state.log.length,
                    itemBuilder: (context, index) {
                      final entry = state.log[state.log.length - 1 - index];
                      final time = _dateFmt.format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
                      return ListTile(
                        leading: Icon(
                          entry.success ? Icons.check_circle : Icons.cancel,
                          color: entry.success ? Colors.green : Colors.red,
                        ),
                        title: Text(entry.taskName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.result, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text('${entry.turns} turns · $time', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          );
  }
}
