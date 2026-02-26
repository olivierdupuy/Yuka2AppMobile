import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/compare_provider.dart';
import 'providers/product_provider.dart';
import 'providers/review_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'screens/home_screen.dart';
import 'screens/maintenance_screen.dart';
import 'services/remote_config_service.dart';
import 'services/tracking_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Initialize tracking silently - don't await
  try {
    TrackingService.instance.initialize();
  } catch (_) {}
  runApp(const Yuka2App());
}

class Yuka2App extends StatefulWidget {
  const Yuka2App({super.key});

  @override
  State<Yuka2App> createState() => _Yuka2AppState();
}

class _Yuka2AppState extends State<Yuka2App> with WidgetsBindingObserver {
  bool _configLoaded = false;
  BlockingReason? _blockingReason;
  Timer? _configTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RemoteConfigService.instance.addListener(_onConfigChanged);
    _checkRemoteConfig();
    // Vérification périodique toutes les 30 secondes
    _configTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => RemoteConfigService.instance.fetchConfig(),
    );
  }

  @override
  void dispose() {
    _configTimer?.cancel();
    RemoteConfigService.instance.removeListener(_onConfigChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onConfigChanged(RemoteConfig config) {
    final reason = _reasonFromConfig(config);
    if (reason != _blockingReason) {
      setState(() => _blockingReason = reason);
    }
  }

  BlockingReason? _reasonFromConfig(RemoteConfig config) {
    if (config.maintenanceMode) return BlockingReason.maintenance;
    if (config.requiresUpdate) return BlockingReason.forceUpdate;
    return null;
  }

  Future<void> _checkRemoteConfig() async {
    final config = await RemoteConfigService.instance.fetchConfig();
    setState(() {
      _blockingReason = _reasonFromConfig(config);
      _configLoaded = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleChange(state);
  }

  Future<void> _handleLifecycleChange(AppLifecycleState state) async {
    try {
      if (state == AppLifecycleState.resumed) {
        // Re-check config when app comes back to foreground
        _checkRemoteConfig();
        await TrackingService.instance.startSession();
        TrackingService.instance.trackEvent('app_open');
      } else if (state == AppLifecycleState.paused) {
        TrackingService.instance.trackEvent('app_background');
        await TrackingService.instance.endSession();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (ctx) => ProductProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? ProductProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReviewProvider>(
          create: (ctx) => ReviewProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? ReviewProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ShoppingListProvider>(
          create: (ctx) => ShoppingListProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? ShoppingListProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompareProvider>(
          create: (ctx) => CompareProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? CompareProvider(auth.api),
        ),
      ],
      child: MaterialApp(
        title: 'Yuka2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _configLoaded ? const HomeScreen() : const _LoadingScreen(),
        builder: (context, child) {
          // Affiche l'écran de maintenance PAR-DESSUS toute la navigation
          if (_blockingReason != null) {
            return MaintenanceScreen(
              reason: _blockingReason!,
              onRetry: _checkRemoteConfig,
            );
          }
          return child!;
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      ),
    );
  }
}
