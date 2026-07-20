import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'design/design_variant.dart';
import 'design/theme/design_preferences.dart';
import 'design/theme/design_theme.dart';
import 'core/di/app_scope.dart';
import 'core/services/android_update_service.dart';
import 'core/services/web_update_service.dart';
import 'core/widgets/web_update_banner.dart';
import 'features/auth/services/auth_service.dart';
import 'features/calendar/services/calendar_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'features/feedback/services/feedback_service.dart';
import 'features/forum/services/forum_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/recipes/services/recipes_service.dart';
import 'features/subscription/services/subscription_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/travel/services/pt_service.dart';
import 'features/user/services/user_service.dart';

class SinclearApp extends StatelessWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final PublicTransportService publicTransport;
  final UserService user;
  final NotificationService notification;
  final CalendarService calendar;
  final FeedbackService feedback;
  final ForumService forum;
  final RecipesService recipes;
  final SubscriptionService subscription;
  final AndroidUpdateService androidUpdate;
  final WebUpdateService webUpdate;
  final GoRouter router;

  /// Initial, locally persisted design variant (survives logout/login).
  final DesignVariant initialDesignVariant;

  /// Active design selection; changes are persisted via [DesignController].
  final ValueNotifier<DesignVariant> designVariant;

  SinclearApp({
    super.key,
    required this.initialDesignVariant,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.publicTransport,
    required this.user,
    required this.notification,
    required this.calendar,
    required this.feedback,
    required this.forum,
    required this.recipes,
    required this.subscription,
    required this.androidUpdate,
    required this.webUpdate,
    required this.router,
  }) : designVariant = DesignController(initialDesignVariant);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      explore: explore,
      nominatim: nominatim,
      travel: travel,
      publicTransport: publicTransport,
      user: user,
      notification: notification,
      calendar: calendar,
      feedback: feedback,
      forum: forum,
      recipes: recipes,
      subscription: subscription,
      androidUpdate: androidUpdate,
      webUpdate: webUpdate,
      child: WebUpdateBanner(
        service: webUpdate,
        child: DesignScope(
          variant: designVariant,
          child: MaterialApp.router(
            title: 'Sinclear Beyond',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0064EA),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0064EA),
                brightness: Brightness.dark,
              ).copyWith(
                surface: const Color(0xFF011219),
              ),
            ),
            themeMode: ThemeMode.system,
            routerConfig: router,
          ),
        ),
      ),
    );
  }
}
