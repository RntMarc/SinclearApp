import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/services/auth_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/user/services/user_service.dart';
import 'firebase_options.dart';
import 'router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load();

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v2';

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
  final notification = NotificationService(api: api, auth: auth);
  await notification.init();
  if (auth.isLoggedIn) notification.onLoggedIn();
  auth.addListener(() {
    if (auth.isLoggedIn) {
      notification.onLoggedIn();
    } else {
      notification.onLoggedOut();
    }
  });
  final router = createRouter(auth);

  runApp(
    SinclearApp(
      auth: auth,
      explore: explore,
      nominatim: nominatim,
      travel: travel,
      user: user,
      notification: notification,
      router: router,
    ),
  );
}
