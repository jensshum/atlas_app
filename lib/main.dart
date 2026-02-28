import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/voice_state.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/scheduler_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const AtlasApp());
}

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, CommandState>(
          create: (ctx) => CommandState(ctx.read<AppState>()),
          update: (_, app, prev) => prev ?? CommandState(app),
        ),
        ChangeNotifierProxyProvider2<AppState, CommandState, VoiceState>(
          create: (ctx) =>
              VoiceState(ctx.read<AppState>(), ctx.read<CommandState>()),
          update: (_, app, cmd, prev) => prev ?? VoiceState(app, cmd),
        ),
        ChangeNotifierProxyProvider<AppState, NotificationsState>(
          create: (ctx) => NotificationsState(ctx.read<AppState>()),
          update: (_, app, prev) => prev ?? NotificationsState(app),
        ),
        ChangeNotifierProxyProvider<AppState, FilterState>(
          create: (ctx) => FilterState(ctx.read<AppState>()),
          update: (_, app, prev) => prev ?? FilterState(app),
        ),
        ChangeNotifierProxyProvider<AppState, SchedulerState>(
          create: (ctx) => SchedulerState(ctx.read<AppState>()),
          update: (_, app, prev) => prev ?? SchedulerState(app),
        ),
      ],
      child: MaterialApp(
        title: 'Atlas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Command'),
    NavigationDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications),
        label: 'Notifications'),
    NavigationDestination(
        icon: Icon(Icons.filter_list),
        selectedIcon: Icon(Icons.filter_list),
        label: 'Filter'),
    NavigationDestination(
        icon: Icon(Icons.schedule_outlined),
        selectedIcon: Icon(Icons.schedule),
        label: 'Scheduler'),
    NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings'),
  ];

  static const _titles = [
    'Command',
    'Notifications',
    'Filter',
    'Scheduler',
    'Settings'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(_titles[_selectedIndex]),
                const Spacer(),
                _ConnectionChip(app: app),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: const [
              HomeScreen(),
              NotificationsScreen(),
              FilterScreen(),
              SchedulerScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final AppState app;
  const _ConnectionChip({required this.app});

  @override
  Widget build(BuildContext context) {
    switch (app.connectionState) {
      case ServerConnectionState.searching:
        return Chip(
          avatar: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text(
            'Scanning ${app.scanProgress}/${app.scanTotal}',
            style: const TextStyle(fontSize: 12),
          ),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      case ServerConnectionState.notFound:
        return ActionChip(
          avatar: const Icon(Icons.wifi_off, size: 16),
          label: const Text('Not found — tap to retry', style: TextStyle(fontSize: 12)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: app.rescan,
        );
      case ServerConnectionState.connected:
        return Chip(
          avatar: const Icon(Icons.wifi, size: 16),
          label: Text(app.serverIp ?? '', style: const TextStyle(fontSize: 12)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
    }
  }
}

