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
import 'features/chat/services/chat_service.dart';
import 'features/moderation/services/moderation_service.dart';
import 'features/recipes/services/recipes_service.dart';
import 'features/stories/services/stories_service.dart';
import 'features/settings/services/dav_sync_service.dart';
import 'features/settings/services/dav_token_service.dart';
import 'features/settings/services/mcp_key_service.dart';
import 'features/subscription/services/subscription_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/travel/services/pt_service.dart';
import 'features/user/services/user_service.dart';
import 'features/home/dashboard_controller.dart';
import 'features/home/dashboard_widget_repository.dart';
import 'features/notifications/services/notification_content_resolver.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/services/unified_push_service.dart';
import 'features/notifications/services/web_push_service.dart';
import 'features/settings/models/notification_preference.dart';
import 'core/notifications/notification_lifecycle_observer.dart';

class SinclearApp extends StatelessWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final PublicTransportService publicTransport;
  final UserService user;
  final CalendarService calendar;
  final FeedbackService feedback;
  final ForumService forum;
  final ChatService chat;
  final RecipesService recipes;
  final ModerationService moderation;
  final SubscriptionService subscription;
  final StoriesService stories;
  final McpKeyService mcpKeys;
  final DavTokenService davTokens;
  final DavSyncService davSync;
  final AndroidUpdateService androidUpdate;
  final WebUpdateService webUpdate;
  final DashboardController dashboardController;
  final DashboardWidgetRepository dashboardWidgets;
  final NotificationService notification;
  final NotificationContentResolver notificationContent;
  final UnifiedPushService unifiedPush;
  final WebPushService webPush;
  final GoRouter router;

  /// Initial, lokal gespeicherte Benachrichtigungs-Methode.
  final NotificationMethod initialNotificationMethod;

  /// Aktive Zustell-Methode; Änderungen werden in der UI sofort wirksam
  /// (z. B. Lifecycle-Observer pollt nur bei [NotificationMethod.polling]).
  final ValueNotifier<NotificationMethod> notificationMethod;

  /// Initial, locally persisted design variant (survives logout/login).
  final DesignVariant initialDesignVariant;

  /// Active design selection; changes are persisted via [DesignController].
  final ValueNotifier<DesignVariant> designVariant;

  /// Initial, locally persisted grain opacity fraction (0..1).
  final double initialGrainOpacity;

  /// Active grain intensity; changes are persisted via [GrainController].
  final ValueNotifier<double> grainOpacity;

  /// Initial, locally persisted theme mode.
  final ThemeMode initialThemeMode;

  /// Active theme mode; changes are persisted via [ThemeModeController].
  final ValueNotifier<ThemeMode> themeMode;

  /// Initial, locally persisted custom accent color.
  final Color initialCustomAccent;

  /// Active custom accent color; changes are persisted via
  /// [CustomAccentController].
  final ValueNotifier<Color> customAccent;
  final String appBaseUrl;
  final String apiBaseUrl;

  SinclearApp({
    super.key,
    required this.initialDesignVariant,
    required this.initialGrainOpacity,
    required this.initialThemeMode,
    required this.initialCustomAccent,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.publicTransport,
    required this.user,
    required this.calendar,
    required this.feedback,
    required this.forum,
    required this.chat,
    required this.recipes,
    required this.moderation,
    required this.subscription,
    required this.stories,
    required this.mcpKeys,
    required this.davTokens,
    required this.davSync,
    required this.androidUpdate,
    required this.webUpdate,
    required this.dashboardController,
    required this.notification,
    required this.notificationContent,
    required this.unifiedPush,
    required this.webPush,
    required this.initialNotificationMethod,
    required this.router,
    required this.appBaseUrl,
    required this.apiBaseUrl,
  }) : dashboardWidgets = DashboardWidgetRepository(
         recipes: recipes,
         calendar: calendar,
         travel: travel,
         forum: forum,
         subscription: subscription,
       ),
       designVariant = DesignController(initialDesignVariant),
       grainOpacity = GrainController(initialGrainOpacity),
       themeMode = ThemeModeController(initialThemeMode),
       customAccent = CustomAccentController(initialCustomAccent),
       notificationMethod = ValueNotifier<NotificationMethod>(
         initialNotificationMethod,
       );

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      explore: explore,
      nominatim: nominatim,
      travel: travel,
      publicTransport: publicTransport,
      user: user,
      calendar: calendar,
      feedback: feedback,
      forum: forum,
      chat: chat,
      recipes: recipes,
      moderation: moderation,
      subscription: subscription,
      stories: stories,
      mcpKeys: mcpKeys,
      davTokens: davTokens,
      davSync: davSync,
      androidUpdate: androidUpdate,
      dashboard: dashboardController,
      dashboardWidgets: dashboardWidgets,
      notification: notification,
      notificationContent: notificationContent,
      unifiedPush: unifiedPush,
      webPush: webPush,
      notificationMethod: notificationMethod,
      webUpdate: webUpdate,
      appBaseUrl: appBaseUrl,
      apiBaseUrl: apiBaseUrl,
      child: WebUpdateBanner(
        service: webUpdate,
        child: DesignScope(
          variant: designVariant,
          grain: grainOpacity,
          themeMode: themeMode,
          customAccent: customAccent,
          child: NotificationLifecycleObserver(
            notificationService: notification,
            getToken: () => auth.getAccessToken(),
            getNotificationMethod: () => notificationMethod.value,
            child: ListenableBuilder(
              listenable: themeMode,
              builder: (context, _) => MaterialApp.router(
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
                  ).copyWith(surface: const Color(0xFF011219)),
                ),
                themeMode: themeMode.value,
                routerConfig: router,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
