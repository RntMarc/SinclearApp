import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/osm_config.dart';
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
import 'features/notifications/services/notification_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/user/services/user_service.dart';
import 'firebase_options.dart';
import 'router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    developer.log(
      'Firebase initialization failed',
      name: 'main',
      error: e,
      stackTrace: s,
    );
  }
  await dotenv.load();

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v2';
  final appId = dotenv.env['APP_ID'] ?? 'de.example.beyond';

  final packageInfo = await PackageInfo.fromPlatform();
  OsmConfig.init(
    appId: appId,
    version: 'v${packageInfo.version}',
  );

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('api_base_url', baseUrl);

  final api = ApiClient(baseUrl: baseUrl);
  final storage = TokenStorage();
  final nominatim = NominatimService();
  final auth = AuthService(api: api, storage: storage);
  await auth.init();
  final explore = ExploreService(api: api, auth: auth);
  final travel = TravelService(api: api, auth: auth);
  final user = UserService(api: api, auth: auth);
  final calendar = CalendarService(api: api, auth: auth);
  final notification = NotificationService(api: api, auth: auth);
  final feedback = FeedbackService(api: api, auth: auth);
  final forum = ForumService(api: api, auth: auth);
  final androidUpdate = AndroidUpdateService(baseUrl: baseUrl);
  final webUpdate = WebUpdateService(
    currentBuildNumber: packageInfo.buildNumber,
  );
  try {
    await notification.init();
    if (auth.isLoggedIn) notification.onLoggedIn();
  } catch (e, s) {
    developer.log(
      'Notification service initialization failed',
      name: 'main',
      error: e,
      stackTrace: s,
    );
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
      user: user,
      calendar: calendar,
      notification: notification,
      feedback: feedback,
      forum: forum,
      androidUpdate: androidUpdate,
      webUpdate: webUpdate,
      router: router,
    ),
  );
}
