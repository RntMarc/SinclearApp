import 'package:flutter/material.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'router/router.dart';

class SinclearApp extends StatelessWidget {
  final AuthService auth;

  const SinclearApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      child: MaterialApp.router(
        title: 'Sinclear Beyond',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: goRouter,
      ),
    );
  }
}
