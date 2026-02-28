import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/voice_state.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/scheduler_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AtlasColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
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
        theme: AtlasTheme.dark,
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
      icon: Icon(Icons.terminal_rounded),
      selectedIcon: Icon(Icons.terminal_rounded),
      label: 'Command',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_none_rounded),
      selectedIcon: Icon(Icons.notifications_rounded),
      label: 'Alerts',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_rounded),
      selectedIcon: Icon(Icons.tune_rounded),
      label: 'Filter',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_repeat_rounded),
      selectedIcon: Icon(Icons.event_repeat_rounded),
      label: 'Schedule',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  'ATLAS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: AtlasColors.gold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AtlasColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                _ConnectionBadge(app: app),
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
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AtlasColors.border, width: 0.5),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              destinations: _destinations,
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final AppState app;
  const _ConnectionBadge({required this.app});

  @override
  Widget build(BuildContext context) {
    final isConnected =
        app.connectionState == ServerConnectionState.connected;
    final isSearching =
        app.connectionState == ServerConnectionState.searching;

    final color = isConnected
        ? AtlasColors.success
        : isSearching
            ? AtlasColors.gold
            : AtlasColors.error;

    return GestureDetector(
      onTap: isConnected ? null : app.rescan,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSearching)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 6),
            Text(
              isSearching
                  ? '${app.scanProgress}/${app.scanTotal}'
                  : isConnected
                      ? app.serverIp ?? ''
                      : 'Offline',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
