/// Ein MCP-API-Key des Nutzers, wie ihn `GET /mcp/keys` liefert.
///
/// Der vollständige Key wird aus Sicherheitsgründen nicht erneut
/// zurückgegeben – er ist nur einmalig bei der Erstellung sichtbar
/// (siehe [McpApiKeyCreateResult.key]).
class McpApiKey {
  final String id;
  final String label;
  final String expiresAt;
  final String createdAt;

  const McpApiKey({
    required this.id,
    required this.label,
    required this.expiresAt,
    required this.createdAt,
  });

  factory McpApiKey.fromJson(Map<String, dynamic> json) => McpApiKey(
    id: json['id'] as String,
    label: json['label'] as String,
    expiresAt: json['expiresAt'] as String,
    createdAt: json['createdAt'] as String,
  );
}

/// Antwort von `POST /mcp/keys` – enthält den vollständigen API-Key,
/// der nur bei der Erstellung einmalig ausgegeben wird.
class McpApiKeyCreateResult {
  final String id;
  final String label;
  final String key;
  final String expiresAt;
  final String createdAt;

  const McpApiKeyCreateResult({
    required this.id,
    required this.label,
    required this.key,
    required this.expiresAt,
    required this.createdAt,
  });

  factory McpApiKeyCreateResult.fromJson(Map<String, dynamic> json) =>
      McpApiKeyCreateResult(
        id: json['id'] as String,
        label: json['label'] as String,
        key: json['key'] as String,
        expiresAt: json['expiresAt'] as String,
        createdAt: json['createdAt'] as String,
      );
}
