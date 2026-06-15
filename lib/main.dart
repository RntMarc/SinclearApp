import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v2';

  final api = ApiClient(baseUrl: baseUrl);
  final storage = TokenStorage();
  final auth = AuthService(api: api, storage: storage);

  runApp(SinclearApp(auth: auth));
}
