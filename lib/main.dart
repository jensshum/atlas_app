import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/voice_state.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/scheduler_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'dart:math' as math;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
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
    return Consumer2<AppState, CommandState>(
      builder: (context, app, cmd, child) {
        return Stack(
          children: [
            Scaffold(
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
            ),
            // ── Global "Atlas is controlling" overlay ──────────────────────
            if (cmd.showOverlay) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _AtlasControlBanner(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _TakeControlButton(onPressed: cmd.cancelCommand),
              ),
            ],
          ],
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

// ─── Atlas control banner (top overlay) ───────────────────────────────────────

class _AtlasControlBanner extends StatefulWidget {
  const _AtlasControlBanner();

  @override
  State<_AtlasControlBanner> createState() => _AtlasControlBannerState();
}

class _AtlasControlBannerState extends State<_AtlasControlBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final glow = math.sin(_pulse.value * math.pi);
          return Container(
            decoration: BoxDecoration(
              color: AtlasColors.goldSurface,
              boxShadow: [
                BoxShadow(
                  color: AtlasColors.gold.withValues(alpha: 0.08 + glow * 0.10),
                  blurRadius: 12 + glow * 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ATLAS IS CONTROLLING YOUR PHONE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AtlasColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Executing command — tap "Take Control" to cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AtlasColors.gold.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Take control button (bottom overlay) ─────────────────────────────────────

class _TakeControlButton extends StatelessWidget {
  final Future<void> Function() onPressed;
  const _TakeControlButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AtlasColors.surface,
          border: Border(
            top: BorderSide(color: AtlasColors.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => onPressed(),
            icon: const Icon(Icons.pan_tool_alt_rounded, size: 18),
            label: const Text(
              'Take Control',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
