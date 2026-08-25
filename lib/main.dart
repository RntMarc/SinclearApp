import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/notification_config.dart';
import 'core/deep_link_handler.dart';
import 'design/theme/design_preferences.dart';
import 'core/config/osm_config.dart';
import 'core/logging.dart';
import 'core/notifications/local_notification_helper.dart';
import 'core/url_strategy.dart';
import 'core/network/api_client.dart';
import 'core/services/android_update_service.dart';
import 'core/services/web_update_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/services/auth_service.dart';
import 'features/calendar/services/calendar_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'features/feedback/services/feedback_service.dart';
import 'features/forum/services/forum_service.dart';
import 'features/chat/services/chat_service.dart';
import 'features/location_sharing/services/location_sharing_service.dart';
import 'features/moderation/services/moderation_service.dart';
import 'features/notifications/services/unified_push_service.dart';
import 'features/notifications/services/web_push_service.dart';
import 'features/recipes/services/recipes_service.dart';
import 'features/stories/services/stories_service.dart';
import 'features/settings/models/notification_preference.dart';
import 'features/settings/models/map_app_preference.dart';
import 'features/settings/services/dav_token_service.dart';
import 'features/settings/services/dav_sync_service.dart';
import 'features/settings/services/mcp_key_service.dart';
import 'features/subscription/services/subscription_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/travel/services/pt_service.dart';
import 'features/user/services/user_service.dart';
import 'features/home/dashboard_cache.dart';
import 'features/home/dashboard_controller.dart';
import 'features/home/dashboard_layout_store.dart';
import 'features/notifications/services/notification_content_resolver.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/models/notification_item.dart';
import 'router/router.dart';

/// Pending cold-start notification route. Set when the notification tap
/// fires before the router exists (Cold-Start). Sie wird dann die
/// Start-Route (`initialLocation`) des Routers, damit die Story erst
/// geöffnet wird, wenn die App fertig geladen ist. Cleared after the
/// route is executed exactly once.
String? _pendingNotificationRoute;

/// Der aktive Router; gesetzt nach der Erstellung in `_bootstrap`.
/// Taps, die danach eintreffen (App läuft), navigieren direkt.
GoRouter? _router;

void main() {
  runZonedGuarded(
    _bootstrap,
    (error, stackTrace) => reportUncaughtError(error, stackTrace),
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupUrlStrategy();
  setupLogging();
  setupGlobalErrorHandling();

  if (!kIsWeb) {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    if (size.shortestSide < 600) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  await initializeDateFormatting('de');
  await dotenv.load();

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v2';
  final appId = dotenv.env['APP_ID'] ?? 'de.example.beyond';
  final apiUri = Uri.tryParse(baseUrl);
  final appBaseUrl = apiUri != null
      ? '${apiUri.scheme}://${apiUri.host}'
      : 'http://localhost:8000';

  final packageInfo = await PackageInfo.fromPlatform();
  OsmConfig.init(appId: appId, version: 'v${packageInfo.version}');

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_base_url', baseUrl);

  final api = ApiClient(baseUrl: baseUrl);
  final storage = TokenStorage();
  final nominatim = NominatimService();
  final auth = AuthService(api: api, storage: storage);
  await auth.init();
  final explore = ExploreService(api: api, auth: auth);
  final travel = TravelService(api: api, auth: auth);
  final publicTransport = PublicTransportService(api: api, auth: auth);
  final user = UserService(api: api, auth: auth);
  final calendar = CalendarService(api: api, auth: auth);
  final feedback = FeedbackService(api: api, auth: auth);
  final forum = ForumService(api: api, auth: auth);
  final chat = ChatService(api: api, auth: auth);
  final locationSharing = LocationSharingService(api: api, auth: auth);
  final recipes = RecipesService(api: api, auth: auth);
  final stories = StoriesService(api: api, auth: auth);
  final moderation = ModerationService(api: api, auth: auth);
  final subscription = SubscriptionService(api: api, auth: auth);
  final mcpKeys = McpKeyService(api: api, auth: auth);
  final davTokens = DavTokenService(api: api, auth: auth);
  final davSync = DavSyncService(
    davTokens: davTokens,
    user: user,
    apiBaseUrl: baseUrl,
    prefs: prefs,
  );
  final notificationContent = NotificationContentResolver(
    user: user,
    forum: forum,
  );
  final notification = NotificationService(
    api: api,
    contentResolver: notificationContent,
  );
  final unifiedPush = UnifiedPushService(api: api);
  final webPush = WebPushService(api: api);
  final androidUpdate = AndroidUpdateService(baseUrl: baseUrl);
  final webUpdate = WebUpdateService(
    currentBuildNumber: packageInfo.buildNumber,
  );
  if (kIsWeb) {
    webUpdate.init();
  }

  final initialNotificationMethod = await NotificationPreference.load();
  final initialMapApp = await MapAppPreference.load();

  if (!kIsWeb) {
    // Handler VOR der Router-Erstellung registrieren: Ein Cold-Start-Tap
    // feuert während init() und merkt die Ziel-Route vor, die dann die
    // Start-Route des Routers wird. So öffnet die Story erst, wenn die App
    // fertig geladen ist — statt ihr nachträglich und evtl. zu früh per
    // router.go() hinterherzunavigieren.
    LocalNotificationHelper.setNotificationTapHandler(
      (payload) => _handleNotificationTap(
        payload,
        auth: auth,
        notification: notification,
      ),
    );
    await LocalNotificationHelper.init();

    // Gespeicherte Zustell-Methode beim App-Start aktivieren (Cold-Start
    // liefert sonst erst nach einem Resume wieder Benachrichtigungen).
    if (auth.isLoggedIn) {
      try {
        final token = await auth.getAccessToken();
        switch (initialNotificationMethod) {
          case NotificationMethod.polling:
            notification.startPolling(getToken: auth.getAccessToken);
          case NotificationMethod.unifiedPush:
            unifiedPush.init(
              token: token,
              onMessage: (item) {
                notification.registerIncoming(item);
                unawaited(notificationContent.showLocal(item));
              },
            );
          case NotificationMethod.fcm:
            break;
        }
      } catch (e, st) {
        developer.log(
          'Failed to start notification method at bootstrap',
          error: e,
          stackTrace: st,
          name: 'bootstrap',
        );
      }
    }
  }

  // Ein Cold-Start-Tap hat die Ziel-Route vorgemerkt: Sie wird direkt die
  // erste Route des Routers (redirect-gesichert über auth/onboarding).
  final router = createRouter(auth, initialLocation: _pendingNotificationRoute);
  _pendingNotificationRoute = null;
  _router = router;

  if (!kIsWeb) {
    DeepLinkHandler().init(router);
  }

  final initialDesign = await DesignPreferences.load();
  final initialGrainOpacity = await DesignPreferences.loadGrainOpacity();
  final initialThemeMode = await DesignPreferences.loadThemeMode();
  final initialCustomAccent = await DesignPreferences.loadCustomAccent();

  final dashboardLayoutStore = SharedPreferencesDashboardLayoutStore();
  final dashboardController = DashboardController(
    initialLayout: await dashboardLayoutStore.load(),
    store: dashboardLayoutStore,
    cache: DashboardCache(),
  );

  runApp(
    SinclearApp(
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
      locationSharing: locationSharing,
      recipes: recipes,
      stories: stories,
      moderation: moderation,
      subscription: subscription,
      mcpKeys: mcpKeys,
      davTokens: davTokens,
      davSync: davSync,
      androidUpdate: androidUpdate,
      webUpdate: webUpdate,
      dashboardController: dashboardController,
      notification: notification,
      notificationContent: notificationContent,
      unifiedPush: unifiedPush,
      webPush: webPush,
      initialNotificationMethod: initialNotificationMethod,
      initialMapApp: initialMapApp,
      initialDesignVariant: initialDesign,
      initialGrainOpacity: initialGrainOpacity,
      initialThemeMode: initialThemeMode,
      initialCustomAccent: initialCustomAccent,
      router: router,
      appBaseUrl: appBaseUrl,
      apiBaseUrl: baseUrl,
    ),
  );

  // Sicherheitsnetz: Taps, die nach der Router-Erstellung, aber vor dem
  // ersten Frame eintreffen, landen in _pendingNotificationRoute und werden
  // hier ausgeführt, sobald der Navigator-Context verfügbar ist. (Der
  // Cold-Start-Tap selbst ist bereits als initialLocation im Router.)
  _tryNavigatePendingNavigation(router);
}

void _handleNotificationTap(
  String? payload, {
  required AuthService auth,
  required NotificationService notification,
}) {
  NotificationItem? item;
  if (payload != null) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        item = NotificationItem.fromJson(decoded);
      }
    } catch (e, st) {
      developer.log(
        'Notification tap payload invalid',
        error: e,
        stackTrace: st,
        name: 'notification_tap',
      );
    }
  }

  // Route lokal aus Typ + Relation-IDs aufbauen. Ohne auflösbares Ziel
  // (unbekannter Typ, fehlende Relationen, ungültiges Payload) geht es zum
  // Fallback — bis eine Inbox existiert, ist das `/home`.
  final route = item == null
      ? null
      : NotificationTypeLabel.route(item.type, item.data);
  final router = _router;
  if (router == null) {
    // Router existiert noch nicht (Cold-Start): Route als Start-Route
    // vormerken — der Router nimmt sie als initialLocation entgegen.
    _pendingNotificationRoute = route ?? '/home';
  } else {
    _navigate(router, route ?? '/home');
  }

  final id = item?.id;
  if (id != null && id.isNotEmpty) {
    unawaited(_markNotificationRead(notification, auth, id));
  }
}

/// Navigiert Cold-Start-sicher: Ist der Navigator noch nicht bereit (Tap
/// vor dem ersten Frame), wird die Route vorgemerkt und nach dem ersten
/// Frame via [_tryNavigatePendingNavigation] ausgeführt.
void _navigate(GoRouter router, String route) {
  if (router.routerDelegate.navigatorKey.currentContext != null) {
    router.go(route);
    return;
  }
  // Router ist noch nicht bereit (Cold-Start). Route speichern; wird nach
  // dem ersten Frame via [_tryNavigatePendingNavigation] ausgeführt.
  _pendingNotificationRoute = route;
  developer.log(
    'Router context not ready, pending route stored: $route',
    name: 'notification_tap',
  );
}

/// Wird einmalig nach `runApp()` aufgerufen. Wartet mittels
/// [addPostFrameCallback]-Kette, bis der Navigator-Context verfügbar ist,
/// und führt dann die Pending-Route aus. Maximal 10 Frames (~160 ms).
void _tryNavigatePendingNavigation(GoRouter router, [int attempt = 0]) {
  if (_pendingNotificationRoute == null || attempt >= 10) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final pending = _pendingNotificationRoute;
    if (pending == null) return;
    if (router.routerDelegate.navigatorKey.currentContext != null) {
      _pendingNotificationRoute = null;
      developer.log(
        'Executing pending notification route: $pending '
        '(attempt $attempt)',
        name: 'notification_tap',
      );
      router.go(pending);
    } else {
      _tryNavigatePendingNavigation(router, attempt + 1);
    }
  });
}

Future<void> _markNotificationRead(
  NotificationService notification,
  AuthService auth,
  String id,
) async {
  try {
    await notification.markRead([id], token: await auth.getAccessToken());
  } catch (e, st) {
    developer.log(
      'markRead after tap failed',
      error: e,
      stackTrace: st,
      name: 'notification_tap',
    );
  }
}
