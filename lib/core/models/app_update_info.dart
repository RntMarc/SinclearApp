class AppUpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final List<String> changelog;

  const AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.changelog,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      downloadUrl: json['downloadUrl'] as String,
      changelog: (json['changelog'] as List)
          .map((e) => e as String)
          .toList(),
    );
  }
}
