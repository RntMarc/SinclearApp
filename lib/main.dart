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
import 'features/moderation/services/moderation_service.dart';
import 'features/notifications/services/unified_push_service.dart';
import 'features/notifications/services/web_push_service.dart';
import 'features/recipes/services/recipes_service.dart';
import 'features/settings/models/notification_preference.dart';
import 'features/settings/services/mcp_key_service.dart';
import 'features/subscription/services/subscription_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/travel/services/pt_service.dart';
import 'features/user/services/user_service.dart';
import 'features/home/dashboard_cache.dart';
import 'features/home/dashboard_controller.dart';
import 'features/home/dashboard_layout_store.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/models/notification_item.dart';
import 'router/router.dart';

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
  final recipes = RecipesService(api: api, auth: auth);
  final moderation = ModerationService(api: api, auth: auth);
  final subscription = SubscriptionService(api: api, auth: auth);
  final mcpKeys = McpKeyService(api: api, auth: auth);
  final notification = NotificationService(api: api);
  final unifiedPush = UnifiedPushService(api: api);
  final webPush = WebPushService(api: api);
  final androidUpdate = AndroidUpdateService(baseUrl: baseUrl);
  final webUpdate = WebUpdateService(
    currentBuildNumber: packageInfo.buildNumber,
  );
  if (kIsWeb) {
    webUpdate.init();
  }

  final router = createRouter(auth);
  final initialNotificationMethod = await NotificationPreference.load();

  if (!kIsWeb) {
    DeepLinkHandler().init(router, appBaseUrl: appBaseUrl);
    LocalNotificationHelper.setNotificationTapHandler(
      (payload) => _handleNotificationTap(
        router,
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
            notification.startPolling(token: token);
          case NotificationMethod.unifiedPush:
            unifiedPush.init(token: token, onMessage: _showLocalNotification);
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
      recipes: recipes,
      moderation: moderation,
      subscription: subscription,
      mcpKeys: mcpKeys,
      androidUpdate: androidUpdate,
      webUpdate: webUpdate,
      dashboardController: dashboardController,
      notification: notification,
      unifiedPush: unifiedPush,
      webPush: webPush,
      initialNotificationMethod: initialNotificationMethod,
      initialDesignVariant: initialDesign,
      initialGrainOpacity: initialGrainOpacity,
      initialThemeMode: initialThemeMode,
      initialCustomAccent: initialCustomAccent,
      router: router,
      appBaseUrl: appBaseUrl,
      apiBaseUrl: baseUrl,
    ),
  );
}

void _handleNotificationTap(
  GoRouter router,
  String? payload, {
  required AuthService auth,
  required NotificationService notification,
}) {
  if (payload == null) {
    _navigate(router, '/home');
    return;
  }

  String type;
  Map<String, dynamic>? data;
  String? id;
  try {
    final decoded = jsonDecode(payload);
    type = decoded is Map<String, dynamic> && decoded['type'] is String
        ? decoded['type'] as String
        : '';
    final rawData = decoded is Map<String, dynamic> ? decoded['data'] : null;
    data = rawData is Map<String, dynamic> ? rawData : null;
    id = decoded is Map<String, dynamic> ? decoded['id'] as String? : null;
  } catch (e, st) {
    developer.log(
      'Notification tap payload invalid',
      error: e,
      stackTrace: st,
      name: 'notification_tap',
    );
    type = '';
    data = null;
    id = null;
  }

  final route = data == null ? null : NotificationTypeLabel.route(type, data);
  _navigate(router, route ?? '/home');

  if (id != null && id.isNotEmpty) {
    unawaited(_markNotificationRead(notification, auth, id));
  }
}

/// Navigiert Cold-Start-sicher: Läuft die App noch nicht (der Tap-Handler
/// feuert vor `runApp`, z. B. beim Start durch eine Notification), wird die
/// Navigation in den ersten Frame verschoben.
void _navigate(GoRouter router, String route) {
  if (router.routerDelegate.navigatorKey.currentContext != null) {
    router.go(route);
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (router.routerDelegate.navigatorKey.currentContext != null) {
      router.go(route);
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

/// Zeigt eine eingegangene Benachrichtigung als lokale System-Notification.
void _showLocalNotification(NotificationItem item) {
  LocalNotificationHelper.show(
    id: localNotificationId(item.id),
    title: item.title,
    body: item.body,
    payload: jsonEncode({'type': item.type, 'data': item.data}),
  );
}
