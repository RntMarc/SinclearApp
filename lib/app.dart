import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'features/news/services/news_service.dart';

class SinclearApp extends StatelessWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final NewsService news;
  final GoRouter router;

  const SinclearApp({
    super.key,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.news,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      explore: explore,
      nominatim: nominatim,
      news: news,
      child: MaterialApp.router(
        title: 'Sinclear Beyond',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
