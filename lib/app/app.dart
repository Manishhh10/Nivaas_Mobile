import 'dart:async';

import 'package:ambient_light/ambient_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/app/theme/app_theme.dart';
import 'package:nivaas/app/theme/theme_mode_provider.dart';
import 'package:nivaas/features/report/presentation/widgets/shake_report_listener.dart';
import 'package:nivaas/features/splash/presentation/pages/home_check_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

/// Global route observer so detail screens can track when they are visible.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final AmbientLight _ambientLight = AmbientLight();
  StreamSubscription<double>? _ambientLightSub;
  ThemeMode? _ambientThemeMode;

  // Use a wider hysteresis band so mode does not flicker,
  // and avoid switching to dark in moderately lit rooms.
  static const double _darkThresholdLux = 8;
  static const double _lightThresholdLux = 80;

  @override
  void initState() {
    super.initState();
    _listenAmbientLight();
  }

  void _listenAmbientLight() {
    _ambientLightSub?.cancel();
    _ambientLightSub = _ambientLight.ambientLightStream.listen((lux) {
      final nextMode = _resolveAmbientTheme(lux, _ambientThemeMode);
      if (nextMode != _ambientThemeMode && mounted) {
        setState(() {
          _ambientThemeMode = nextMode;
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _ambientThemeMode = null;
        });
      }
    });
  }

  ThemeMode _resolveAmbientTheme(double lux, ThemeMode? current) {
    if (lux.isNaN || lux.isInfinite) {
      return current ?? ThemeMode.light;
    }

    final safeLux = lux < 0 ? 0.0 : lux;

    if (current == null) {
      return safeLux >= ((_darkThresholdLux + _lightThresholdLux) / 2)
          ? ThemeMode.light
          : ThemeMode.dark;
    }

    if (current == ThemeMode.dark && safeLux >= _lightThresholdLux) {
      return ThemeMode.light;
    }

    if (current == ThemeMode.light && safeLux <= _darkThresholdLux) {
      return ThemeMode.dark;
    }

    return current;
  }

  @override
  void dispose() {
    _ambientLightSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedThemeMode = ref.watch(themeModeProvider);
    final effectiveThemeMode = selectedThemeMode == ThemeMode.system
        ? (_ambientThemeMode ?? ThemeMode.light)
        : selectedThemeMode;

    return ShakeReportListener(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      child: MaterialApp(
        title: 'Nivaas',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        navigatorObservers: [appRouteObserver],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: effectiveThemeMode,
        home: const HomeCheckScreen(),
      ),
    );
  }
}
