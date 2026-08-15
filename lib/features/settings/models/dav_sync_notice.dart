/// Schweregrad einer Synchronisations-Hinweismeldung.
enum DavSyncSeverity { error, warning, info }

/// Ein persistenter, schließbarer Hinweis zum Kalender-Synchronisationsfluss.
///
/// Wird bei Fehlern in einzelnen Schritten (Berechtigung, Token-Erstellung,
/// Account-Einrichtung, Sync) erzeugt und im DAV-Tokens-Screen als Karte
/// angezeigt, bis der Nutzer sie schließt.
class DavSyncNotice {
  final String id;
  final DavSyncSeverity severity;
  final String step;
  final String message;
  final DateTime createdAt;

  const DavSyncNotice({
    required this.id,
    required this.severity,
    required this.step,
    required this.message,
    required this.createdAt,
  });

  factory DavSyncNotice.fromJson(Map<String, dynamic> json) => DavSyncNotice(
    id: json['id'] as String,
    severity: DavSyncSeverity.values.firstWhere(
      (s) => s.name == json['severity'],
      orElse: () => DavSyncSeverity.info,
    ),
    step: json['step'] as String,
    message: json['message'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'severity': severity.name,
    'step': step,
    'message': message,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
