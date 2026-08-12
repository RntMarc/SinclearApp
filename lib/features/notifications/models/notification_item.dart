import '../../../core/utils/date_utils.dart';

/// Eine einzelne Objekt-Referenz innerhalb von [NotificationItem.data].
///
/// Die API liefert pro Benachrichtigung eine Liste solcher Einträge.
/// [relation] beschreibt die Rolle des Objekts für die Benachrichtigung
/// (z. B. `reply_author`, `parent_post`), [object] den API-Typ
/// (z. B. `User`, `ForumPost`) und [identifier] die ID des Objekts.
/// Aus den IDs baut der Client Deep-Links lokal selbst; zum Rendern der
/// Texte werden die referenzierten Ressourcen bei Bedarf nachgeladen.
class NotificationRelation {
  final String relation;
  final String object;
  final String identifier;

  const NotificationRelation({
    required this.relation,
    required this.object,
    required this.identifier,
  });

  factory NotificationRelation.fromJson(Map<String, dynamic> json) {
    return NotificationRelation(
      relation: json['relation'] as String? ?? '',
      object: json['object'] as String? ?? '',
      identifier: json['identifier'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'relation': relation,
    'object': object,
    'identifier': identifier,
  };
}

/// Eine Benachrichtigung der API.
///
/// Die API liefert weder Titel, Texte noch Routen — der Client erzeugt sie
/// aus [type] und [data] (siehe `NotificationTypeLabel` und
/// `NotificationContentResolver`).
class NotificationItem {
  final String id;
  final String type;
  final List<NotificationRelation> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    this.data = const [],
    this.isRead = false,
    required this.createdAt,
  });

  /// Die ID des Objekts mit der Rolle [relation], oder `null`, wenn kein
  /// solcher Eintrag in [data] existiert.
  String? identifierFor(String relation) {
    for (final entry in data) {
      if (entry.relation == relation && entry.identifier.isNotEmpty) {
        return entry.identifier;
      }
    }
    return null;
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      data: rawData is List
          ? rawData
                .whereType<Map<String, dynamic>>()
                .map(NotificationRelation.fromJson)
                .toList()
          : const [],
      isRead: json['isRead'] == true || json['isRead'] == 1,
      createdAt: parseApiDate(json['createdAt'] as String),
    );
  }

  /// Serialisiert für das Tap-Payload lokaler System-Benachrichtigungen,
  /// damit der Tap-Handler die Benachrichtigung wieder vollständig
  /// rekonstruieren kann.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data.map((entry) => entry.toJson()).toList(),
    'createdAt': toApiDate(createdAt, withMilliseconds: true),
  };
}
