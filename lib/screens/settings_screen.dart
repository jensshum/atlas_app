import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

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
      setState(() => _testResult =
          'Connected  ·  uptime ${health?.uptime.toStringAsFixed(0)}s');
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
          SnackBar(
            content: Text('$e'),
            backgroundColor: AtlasColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final connected =
            app.connectionState == ServerConnectionState.connected;
        final searching =
            app.connectionState == ServerConnectionState.searching;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Connection ───
            const _SectionLabel('CONNECTION'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: connected
                                ? AtlasColors.success
                                    .withValues(alpha: 0.1)
                                : searching
                                    ? AtlasColors.gold
                                        .withValues(alpha: 0.1)
                                    : AtlasColors.error
                                        .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: connected
                                  ? AtlasColors.success
                                      .withValues(alpha: 0.3)
                                  : searching
                                      ? AtlasColors.gold
                                          .withValues(alpha: 0.3)
                                      : AtlasColors.error
                                          .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            connected
                                ? Icons.wifi_rounded
                                : searching
                                    ? Icons.wifi_find_rounded
                                    : Icons.wifi_off_rounded,
                            color: connected
                                ? AtlasColors.success
                                : searching
                                    ? AtlasColors.gold
                                    : AtlasColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                connected
                                    ? 'Connected'
                                    : searching
                                        ? 'Scanning...'
                                        : 'Disconnected',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              if (connected && app.serverIp != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2),
                                  child: Text(
                                    app.serverIp!,
                                    style: const TextStyle(
                                      color:
                                          AtlasColors.textSecondary,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              if (searching)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${app.scanProgress}/${app.scanTotal} IPs checked',
                                    style: const TextStyle(
                                      color:
                                          AtlasColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AtlasColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResult!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AtlasColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: app.rescan,
                              icon: const Icon(
                                  Icons.radar_rounded,
                                  size: 16),
                              label: const Text('Rescan',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        if (connected) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: _testingConnection
                                    ? null
                                    : () =>
                                        _testConnection(app),
                                icon: _testingConnection
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                        ),
                                      )
                                    : const Icon(
                                        Icons
                                            .speed_rounded,
                                        size: 16),
                                label: const Text('Test',
                                    style:
                                        TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Manual IP ───
            const _SectionLabel('MANUAL OVERRIDE'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _showManual = !_showManual),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  AtlasColors.surfaceContainerHigh,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AtlasColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Enter IP manually',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            _showManual
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AtlasColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showManual) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualCtrl,
                              keyboardType:
                                  TextInputType.number,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                              decoration:
                                  const InputDecoration(
                                hintText: '192.168.1.100',
                                labelText: 'Server IP',
                                contentPadding:
                                    EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: () =>
                                  _connectManual(app),
                              child: const Text('Connect'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── About ───
            const _SectionLabel('ABOUT'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AtlasColors.goldSurface,
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: AtlasColors.gold
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(
                            Icons.terminal_rounded,
                            size: 18,
                            color: AtlasColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atlas Controller',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'v1.0.0',
                              style: TextStyle(
                                color: AtlasColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Controls an AI agent running on a rooted Android phone via Termux + Node.js.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AtlasColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AtlasColors.textTertiary,
        ),
      ),
    );
  }
}
