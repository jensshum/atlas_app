import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _manualCtrl = TextEditingController();
  bool _showManual = false;
  bool _testingConnection = false;
  String? _testResult;

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection(AppState app) async {
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });
    try {
      final health = await app.client?.getHealth();
      setState(() => _testResult = 'Connected · uptime ${health?.uptime.toStringAsFixed(0)}s');
    } catch (e) {
      setState(() => _testResult = 'Failed: $e');
    } finally {
      setState(() => _testingConnection = false);
    }
  }

  Future<void> _connectManual(AppState app) async {
    final ip = _manualCtrl.text.trim();
    if (ip.isEmpty) return;
    try {
      await app.useManualIp(ip);
      if (mounted) setState(() => _showManual = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final connected = app.connectionState == ServerConnectionState.connected;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connection status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          connected ? Icons.wifi : Icons.wifi_off,
                          color: connected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            connected
                                ? 'Connected to ${app.serverIp}'
                                : app.connectionState == ServerConnectionState.searching
                                    ? 'Scanning network...'
                                    : 'Not connected',
                          ),
                        ),
                      ],
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 4),
                      Text(_testResult!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: app.rescan,
                          child: const Text('Rescan Network'),
                        ),
                        const SizedBox(width: 8),
                        if (connected)
                          OutlinedButton(
                            onPressed: _testingConnection ? null : () => _testConnection(app),
                            child: _testingConnection
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Test'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Manual IP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showManual = !_showManual),
                      child: Row(
                        children: [
                          Text('Manual IP Override', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Icon(_showManual ? Icons.expand_less : Icons.expand_more),
                        ],
                      ),
                    ),
                    if (_showManual) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '192.168.1.100',
                          labelText: 'Server IP address',
                          suffix: FilledButton(
                            onPressed: () => _connectManual(app),
                            child: const Text('Connect'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Atlas Controller'),
                    const Text('Controls an AI agent running on a rooted Android phone via Termux + Node.js.',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
