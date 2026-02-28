import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _addController = TextEditingController();

  static final _knownApps = {
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

  static const _appIcons = {
    'com.google.android.gm': Icons.mail_rounded,
    'com.whatsapp': Icons.chat_rounded,
    'com.slack': Icons.tag_rounded,
    'com.discord': Icons.headset_mic_rounded,
    'com.facebook.orca': Icons.message_rounded,
    'com.instagram.android': Icons.camera_alt_rounded,
    'com.twitter.android': Icons.flutter_dash_rounded,
    'com.google.android.apps.messaging': Icons.sms_rounded,
    'com.linkedin.android': Icons.work_rounded,
    'com.facebook.katana': Icons.facebook_rounded,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FilterState>().load();
    });
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _showAddDialog(FilterState state) {
    _addController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Package'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addController,
                decoration: const InputDecoration(
                  hintText: 'com.example.app',
                  labelText: 'Package name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SUGGESTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AtlasColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _knownApps.entries
                      .where((e) => !state.packages.contains(e.key))
                      .map(
                        (e) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AtlasColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AtlasColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            leading: Icon(
                              _appIcons[e.key] ?? Icons.apps_rounded,
                              color: AtlasColors.textSecondary,
                              size: 20,
                            ),
                            title: Text(
                              e.value,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AtlasColors.textTertiary,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              state.addPackage(e.key);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pkg = _addController.text.trim();
              if (pkg.isNotEmpty) {
                Navigator.of(ctx).pop();
                state.addPackage(pkg);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterState>(
      builder: (context, state, _) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
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
                        color:
                            AtlasColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                          color: AtlasColors.error, fontSize: 12),
                    ),
                  ),
                ),
              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Text(
                      'WHITELISTED APPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AtlasColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: AtlasColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.packages.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AtlasColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.packages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                Icons.tune_rounded,
                                size: 28,
                                color: AtlasColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No packages in whitelist',
                              style: TextStyle(
                                color: AtlasColors.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add apps to monitor their notifications',
                              style: TextStyle(
                                color: AtlasColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: state.packages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final pkg = state.packages[index];
                          final name = _knownApps[pkg];
                          final icon =
                              _appIcons[pkg] ?? Icons.apps_rounded;
                          return Dismissible(
                            key: Key(pkg),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AtlasColors.errorSurface,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AtlasColors.error,
                              ),
                            ),
                            onDismissed: (_) =>
                                state.removePackage(pkg),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AtlasColors.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: AtlasColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AtlasColors
                                        .surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(icon,
                                      size: 18,
                                      color:
                                          AtlasColors.textSecondary),
                                ),
                                title: Text(
                                  name ?? pkg,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: name != null
                                    ? Text(
                                        pkg,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AtlasColors
                                              .textTertiary,
                                        ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AtlasColors.textTertiary,
                                  ),
                                  onPressed: () =>
                                      state.removePackage(pkg),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddDialog(state),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}
