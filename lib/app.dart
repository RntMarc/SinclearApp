import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dynamic_theme_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/calendar/services/calendar_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/user/services/user_service.dart';

class SinclearApp extends StatefulWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final UserService user;
  final NotificationService notification;
  final CalendarService calendar;
  final GoRouter router;
  final DynamicThemeService dynamicTheme;

  const SinclearApp({
    super.key,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.user,
    required this.notification,
    required this.calendar,
    required this.router,
    required this.dynamicTheme,
  });

  @override
  State<SinclearApp> createState() => _SinclearAppState();
}

class _SinclearAppState extends State<SinclearApp> {
  late final DynamicThemeService _dynamicTheme;
  bool _themeInitialized = false;

  @override
  void initState() {
    super.initState();
    _dynamicTheme = widget.dynamicTheme;
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await _dynamicTheme.initialize();
    if (mounted) {
      setState(() {
        _themeInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _dynamicTheme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeInitialized) {
      return MaterialApp(
        title: 'Sinclear Beyond',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final palette = _dynamicTheme.palette;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final themeMode = brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return ThemeProvider(
      palette: palette,
      service: _dynamicTheme,
      child: AppScope(
        auth: widget.auth,
        explore: widget.explore,
        nominatim: widget.nominatim,
        travel: widget.travel,
        user: widget.user,
        notification: widget.notification,
        calendar: widget.calendar,
        child: MaterialApp.router(
          title: 'Sinclear Beyond',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.fromPalette(palette, Brightness.light),
          darkTheme: AppTheme.fromPalette(palette, Brightness.dark),
          themeMode: themeMode,
          routerConfig: widget.router,
        ),
      ),
    );
  }
}
