import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'screens/home_screen.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.resumed) {
        TrackingService.instance.startSession();
        TrackingService.instance.trackEvent('app_open');
      } else if (state == AppLifecycleState.paused) {
        TrackingService.instance.trackEvent('app_background');
        TrackingService.instance.endSession();
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
        home: const HomeScreen(),
      ),
    );
  }
}
