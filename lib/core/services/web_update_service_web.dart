import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

Future<String?> fetchServerBuildNumber() async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final origin = web.window.location.origin;
  final uri = Uri.parse('$origin/version.json?t=$timestamp');

  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) return null;

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json['build_number'] as String?;
}

void reloadPage() {
  web.window.location.reload();
}
