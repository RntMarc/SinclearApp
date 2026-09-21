/// Online-Status eines Nutzers basierend auf Centrifugo Presence.
class UserPresence {
  final bool online;
  final String? lastJoin;
  final String? lastLeave;
  final String? lastSeen;

  const UserPresence({
    required this.online,
    this.lastJoin,
    this.lastLeave,
    this.lastSeen,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      online: json['online'] as bool? ?? false,
      lastJoin: json['lastJoin'] as String?,
      lastLeave: json['lastLeave'] as String?,
      lastSeen: json['lastSeen'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'online': online,
      if (lastJoin != null) 'lastJoin': lastJoin,
      if (lastLeave != null) 'lastLeave': lastLeave,
      if (lastSeen != null) 'lastSeen': lastSeen,
    };
  }
}
