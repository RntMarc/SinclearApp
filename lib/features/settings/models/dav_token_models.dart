/// Ein DAV-Token des Nutzers, wie ihn `GET /user/me/dav-tokens` liefert.
///
/// Das vollständige Token wird aus Sicherheitsgründen nicht erneut
/// zurückgegeben – es ist nur einmalig bei der Erstellung sichtbar
/// (siehe [DavTokenCreateResult.token]).
class DavToken {
  final String id;
  final String label;
  final String expiresAt;
  final String? lastUsedAt;
  final String createdAt;

  const DavToken({
    required this.id,
    required this.label,
    required this.expiresAt,
    this.lastUsedAt,
    required this.createdAt,
  });

  factory DavToken.fromJson(Map<String, dynamic> json) => DavToken(
    id: json['id'] as String,
    label: json['label'] as String,
    expiresAt: json['expiresAt'] as String,
    lastUsedAt: json['lastUsedAt'] as String?,
    createdAt: json['createdAt'] as String,
  );
}

/// Antwort von `POST /user/me/dav-tokens` – enthält das vollständige
/// Token, das nur bei der Erstellung einmalig ausgegeben wird.
class DavTokenCreateResult {
  final String id;
  final String label;
  final String token;
  final String expiresAt;
  final String createdAt;

  const DavTokenCreateResult({
    required this.id,
    required this.label,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
  });

  factory DavTokenCreateResult.fromJson(Map<String, dynamic> json) =>
      DavTokenCreateResult(
        id: json['id'] as String,
        label: json['label'] as String,
        token: json['token'] as String,
        expiresAt: json['expiresAt'] as String,
        createdAt: json['createdAt'] as String,
      );
}
