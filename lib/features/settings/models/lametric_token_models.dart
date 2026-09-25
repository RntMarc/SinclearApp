/// Das LaMetric-Token des Nutzers, wie es `GET /lametric/token` liefert.
///
/// Anders als DAV-/MCP-Tokens wird der Klartext gespeichert und kann
/// jederzeit erneut abgerufen werden ([token]).
class LaMetricToken {
  final String id;
  final String label;
  final String token;
  final String expiresAt;
  final String? lastUsedAt;
  final String createdAt;

  const LaMetricToken({
    required this.id,
    required this.label,
    required this.token,
    required this.expiresAt,
    this.lastUsedAt,
    required this.createdAt,
  });

  factory LaMetricToken.fromJson(Map<String, dynamic> json) => LaMetricToken(
    id: json['id'] as String,
    label: json['label'] as String,
    token: json['token'] as String,
    expiresAt: json['expiresAt'] as String,
    lastUsedAt: json['lastUsedAt'] as String?,
    createdAt: json['createdAt'] as String,
  );
}
