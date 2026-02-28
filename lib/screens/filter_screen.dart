import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

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
        content: Column(
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
            const SizedBox(height: 12),
            const Text('Common packages:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ..._knownApps.entries
                .where((e) => !state.packages.contains(e.key))
                .map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.value),
                    subtitle: Text(e.key, style: const TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      state.addPackage(e.key);
                    },
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
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
          body: Column(
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Expanded(
                child: state.packages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list_off, size: 48, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 12),
                            Text('No packages in whitelist', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.packages.length,
                        itemBuilder: (context, index) {
                          final pkg = state.packages[index];
                          final name = _knownApps[pkg];
                          return Dismissible(
                            key: Key(pkg),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Theme.of(context).colorScheme.error,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => state.removePackage(pkg),
                            child: ListTile(
                              leading: const Icon(Icons.apps),
                              title: Text(name ?? pkg),
                              subtitle: name != null ? Text(pkg) : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => state.removePackage(pkg),
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
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
