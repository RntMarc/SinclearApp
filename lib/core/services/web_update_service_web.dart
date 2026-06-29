import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

/// Version metadata loaded from the web root.
class RootVersion {
  /// Creates immutable metadata for the deployed root build.
  const RootVersion({required this.buildNumber, required this.version});

  /// Build number from `/version.json`.
  final String buildNumber;

  /// Human-readable version from `/version.json`.
  final String? version;
}

/// Fetches only the root `/version.json?t=<timestamp>` metadata file.
Future<RootVersion?> fetchRootVersion() async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final origin = web.window.location.origin;
  final uri = Uri.parse('$origin/version.json?t=$timestamp');

  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) return null;

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final buildNumber = json['build_number'] as String?;
  if (buildNumber == null || buildNumber.isEmpty) return null;

  return RootVersion(
    buildNumber: buildNumber,
    version: json['version'] as String?,
  );
}

/// Performs the only update activation action: a user-triggered page reload.
void reloadPage() {
  web.window.location.reload();
}
