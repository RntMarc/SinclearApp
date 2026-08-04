import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/deep_link_handler.dart';
import 'design/theme/design_preferences.dart';
import 'core/config/osm_config.dart';
import 'core/logging.dart';
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
import 'features/notifications/services/notification_service.dart';
import 'features/recipes/services/recipes_service.dart';
import 'features/settings/services/mcp_key_service.dart';
import 'features/subscription/services/subscription_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/travel/services/pt_service.dart';
import 'features/user/services/user_service.dart';
import 'features/home/dashboard_cache.dart';
import 'features/home/dashboard_controller.dart';
import 'features/home/dashboard_layout_store.dart';
import 'firebase_options.dart';
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
  final log = Logger('main');

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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    log.severe('Firebase initialization failed', e, s);
  }
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
  final notification = NotificationService(api: api, auth: auth);
  final feedback = FeedbackService(api: api, auth: auth);
  final forum = ForumService(api: api, auth: auth);
  final recipes = RecipesService(api: api, auth: auth);
  final moderation = ModerationService(api: api, auth: auth);
  final subscription = SubscriptionService(api: api, auth: auth);
  final mcpKeys = McpKeyService(api: api, auth: auth);
  final androidUpdate = AndroidUpdateService(baseUrl: baseUrl);
  final webUpdate = WebUpdateService(
    currentBuildNumber: packageInfo.buildNumber,
  );
  try {
    await notification.init();
    if (auth.isLoggedIn) notification.onLoggedIn();
  } catch (e, s) {
    log.severe('Notification service initialization failed', e, s);
  }
  auth.addListener(() {
    if (auth.isLoggedIn) {
      notification.onLoggedIn();
    } else {
      notification.onLoggedOut();
    }
  });
  if (kIsWeb) {
    webUpdate.init();
  }

  final router = createRouter(auth);

  if (!kIsWeb) {
    DeepLinkHandler().init(router, appBaseUrl: appBaseUrl);
  }

  final initialDesign = await DesignPreferences.load();
  final initialGrainOpacity = await DesignPreferences.loadGrainOpacity();
  final initialThemeMode = await DesignPreferences.loadThemeMode();

  final dashboardLayoutStore = SharedPreferencesDashboardLayoutStore();
  final dashboardController = DashboardController(
    initialLayout: await dashboardLayoutStore.load(),
    store: dashboardLayoutStore,
    cache: DashboardCache(),
  );

  notification.onNotificationTapped = (notificationId) {
    if (auth.isLoggedIn) {
      router.go('/home');
    }
  };

  final initialNotifId = notification.consumePendingNotificationId();
  if (initialNotifId != null && auth.isLoggedIn) {
    router.go('/home');
  }

  runApp(
    SinclearApp(
      auth: auth,
      explore: explore,
      nominatim: nominatim,
      travel: travel,
      publicTransport: publicTransport,
      user: user,
      calendar: calendar,
      notification: notification,
      feedback: feedback,
      forum: forum,
      recipes: recipes,
      moderation: moderation,
      subscription: subscription,
      mcpKeys: mcpKeys,
      androidUpdate: androidUpdate,
      webUpdate: webUpdate,
      dashboardController: dashboardController,
      initialDesignVariant: initialDesign,
      initialGrainOpacity: initialGrainOpacity,
      initialThemeMode: initialThemeMode,
      router: router,
      appBaseUrl: appBaseUrl,
      apiBaseUrl: baseUrl,
    ),
  );
}
