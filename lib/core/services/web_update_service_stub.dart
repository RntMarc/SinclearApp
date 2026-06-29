/// Version metadata placeholder for non-web platforms.
class RootVersion {
  /// Creates immutable metadata for the deployed root build.
  const RootVersion({required this.buildNumber, required this.version});

  /// Build number from `/version.json`.
  final String buildNumber;

  /// Human-readable version from `/version.json`.
  final String? version;
}

/// No-op update metadata fetcher for non-web platforms.
Future<RootVersion?> fetchRootVersion() async => null;

/// No-op reload for non-web platforms.
void reloadPage() {}
