import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRemoteConfig();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkRemoteConfig() async {
    final config = await RemoteConfigService.instance.fetchConfig();

    BlockingReason? reason;
    if (config.maintenanceMode) {
      reason = BlockingReason.maintenance;
    } else if (config.requiresUpdate) {
      reason = BlockingReason.forceUpdate;
    }

    setState(() {
      _blockingReason = reason;
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
      ],
      child: MaterialApp(
        title: 'Yuka2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (!_configLoaded) {
      // Show a simple loading while checking config
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
        ),
      );
    }

    if (_blockingReason != null) {
      return MaintenanceScreen(
        reason: _blockingReason!,
        onRetry: _checkRemoteConfig,
      );
    }

    return const HomeScreen();
  }
}
