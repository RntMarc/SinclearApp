/// Präferenz-Zustand eines Benachrichtigungstyps, gespiegelt von der API
/// (`GET/PUT /notifications/preferences`).
enum NotificationPreferenceState {
  enabled,
  disabled,
  custom;

  static NotificationPreferenceState fromApi(String value) {
    return switch (value) {
      'enabled' => NotificationPreferenceState.enabled,
      'disabled' => NotificationPreferenceState.disabled,
      'custom' => NotificationPreferenceState.custom,
      _ => NotificationPreferenceState.enabled,
    };
  }

  String toApi() => name;
}

/// Präferenz eines einzelnen Benachrichtigungstyps.
///
/// `custom` bedeutet aktiv mit Denylist: `customData` enthält genau einen
/// Schlüssel (`forumIds` bzw. `userIds`) mit den unterdrückten IDs. Der
/// Schlüssel ergibt sich deterministisch aus dem Typ, siehe
/// `NotificationTypeLabel.customDataKey`.
class NotificationTypePreference {
  final String type;
  final NotificationPreferenceState state;

  /// Ob der Server `custom` für diesen Typ unterstützt.
  final bool customAllowed;

  /// Denylist als `{ <key>: [ids] }`; nur bei `state == custom` gesetzt.
  final Map<String, dynamic>? customData;

  const NotificationTypePreference({
    required this.type,
    required this.state,
    required this.customAllowed,
    this.customData,
  });

  factory NotificationTypePreference.fromJson(Map<String, dynamic> json) {
    final rawData = json['customData'];
    return NotificationTypePreference(
      type: json['type'] as String? ?? '',
      state: NotificationPreferenceState.fromApi(
        json['state'] as String? ?? 'enabled',
      ),
      customAllowed: json['customAllowed'] == true,
      customData: rawData is Map<String, dynamic> ? rawData : null,
    );
  }

  /// Request-Body für `PUT /notifications/preferences` — nur geänderte
  /// Typen werden übermittelt.
  Map<String, dynamic> toRequestJson() {
    final body = <String, dynamic>{'type': type, 'state': state.toApi()};
    if (state == NotificationPreferenceState.custom) {
      body['customData'] = customData ?? const <String, dynamic>{};
    }
    return body;
  }

  /// Denylist-IDs dieses Typs als Liste (leer, wenn keine vorliegen).
  List<String> denylistIds(String key) {
    final data = customData;
    if (data == null) return const [];
    final raw = data[key];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }
}

/// Antwort-Wrapper für `GET/PUT /notifications/preferences`:
/// `{ "data": { "<type>": { state, customAllowed, customData } } }`.
class NotificationPreferencesResponse {
  final Map<String, NotificationTypePreference> data;

  const NotificationPreferencesResponse({required this.data});

  factory NotificationPreferencesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final prefs = <String, NotificationTypePreference>{};
    if (raw is Map<String, dynamic>) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          prefs[entry.key] = NotificationTypePreference.fromJson({
            'type': entry.key,
            ...value,
          });
        }
      }
    }
    return NotificationPreferencesResponse(data: prefs);
  }
}
