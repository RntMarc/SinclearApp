import '../../../core/utils/date_utils.dart';

/// Nutzer-Kurzform, wie sie die Chat-Endpunkte liefern (`id`,
/// `displayName`, `avatar`).
class ChatUser {
  final String id;
  final String displayName;
  final String? avatar;

  const ChatUser({required this.id, this.displayName = '', this.avatar});

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
    id: json['id'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    avatar: json['avatar'] as String?,
  );
}

/// Vorschau der letzten Nachricht einer Konversation.
class ChatMessageSummary {
  final String content;
  final String senderId;
  final DateTime createdAt;
  final bool deleted;

  const ChatMessageSummary({
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.deleted = false,
  });

  factory ChatMessageSummary.fromJson(Map<String, dynamic> json) =>
      ChatMessageSummary(
        content: json['content'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        createdAt: parseApiDate(json['createdAt'] as String),
        deleted: json['deleted'] == true,
      );
}

/// Eine Konversation (1:1 oder Gruppe).
class ChatConversation {
  final String id;
  final String type;
  final String? name;

  /// Icon/Avatar der Gruppenkonversation (base64-encoded Bild); null bei
  /// 1:1 und wenn nicht gesetzt.
  final String? image;
  final ChatUser? otherUser;
  final ChatMessageSummary? lastMessage;
  final int unreadCount;
  final DateTime? lastSeenAt;
  final int lastReadSeq;
  final int otherLastReadSeq;

  /// Anzahl der Teilnehmer (nur bei Gruppen; `null` bei 1:1).
  final int? memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.type,
    this.name,
    this.image,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastSeenAt,
    this.lastReadSeq = 0,
    this.otherLastReadSeq = 0,
    this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final rawOther = json['otherUser'];
    final rawLast = json['lastMessage'];
    return ChatConversation(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      name: json['name'] as String?,
      image: json['image'] as String?,
      otherUser: rawOther is Map<String, dynamic>
          ? ChatUser.fromJson(rawOther)
          : null,
      lastMessage: rawLast is Map<String, dynamic>
          ? ChatMessageSummary.fromJson(rawLast)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastSeenAt: json['lastSeenAt'] != null
          ? parseApiDate(json['lastSeenAt'] as String)
          : null,
      lastReadSeq: json['lastReadSeq'] as int? ?? 0,
      otherLastReadSeq: json['otherLastReadSeq'] as int? ?? 0,
      memberCount: json['memberCount'] as int?,
      createdAt: parseApiDate(json['createdAt'] as String),
      updatedAt: parseApiDate(json['updatedAt'] as String),
    );
  }
}

/// Eine einzelne Nachricht.
class DirectMessage {
  final String id;
  final int seq;
  final String conversationId;
  final String senderId;
  final ChatUser sender;
  final String type;
  final String content;
  final Map<String, dynamic>? payload;
  final String? clientId;
  final DateTime? editedAt;
  final bool deleted;
  final DateTime createdAt;

  const DirectMessage({
    required this.id,
    required this.seq,
    required this.conversationId,
    required this.senderId,
    required this.sender,
    this.type = 'text',
    this.content = '',
    this.payload,
    this.clientId,
    this.editedAt,
    this.deleted = false,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    final rawSender = json['sender'];
    return DirectMessage(
      id: json['id'] as String,
      seq: json['seq'] as int,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String? ?? '',
      sender: rawSender is Map<String, dynamic>
          ? ChatUser.fromJson(rawSender)
          : ChatUser(id: json['senderId'] as String? ?? ''),
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
      clientId: json['clientId'] as String?,
      editedAt: json['editedAt'] != null
          ? parseApiDate(json['editedAt'] as String)
          : null,
      deleted: json['deleted'] == true,
      createdAt: parseApiDate(json['createdAt'] as String),
    );
  }
}
