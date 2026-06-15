import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/services/auth_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v2';

  final api = ApiClient(baseUrl: baseUrl);
  final storage = TokenStorage();
  final nominatim = NominatimService();
  final auth = AuthService(api: api, storage: storage);
  await auth.init();
  final explore = ExploreService(api: api, auth: auth);
  final router = createRouter(auth);

  runApp(SinclearApp(
    auth: auth,
    explore: explore,
    nominatim: nominatim,
    router: router,
  ));
}
