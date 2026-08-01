import 'package:flutter/material.dart';

/// Art einer Moderations-Anfrage (API: `requestType`).
enum ModerationRequestType {
  report('report', 'Meldung', Icons.flag_rounded),
  deletion('deletion', 'Löschung', Icons.delete_rounded),
  other('other', 'Anfrage', Icons.question_answer_rounded);

  final String apiValue;
  final String label;
  final IconData icon;

  const ModerationRequestType(this.apiValue, this.label, this.icon);

  static ModerationRequestType fromApi(String value) => values.firstWhere(
    (t) => t.apiValue == value,
    orElse: () => ModerationRequestType.other,
  );
}

/// Objekttyp, auf den sich eine Anfrage bezieht (API: `objectType`).
enum ModerationObjectType {
  user('user', 'Benutzer'),
  forumPost('forum_post', 'Forumsbeitrag'),
  recipe('recipe', 'Rezept'),
  explorePlace('explore_place', 'Ort');

  final String apiValue;
  final String label;

  const ModerationObjectType(this.apiValue, this.label);

  static ModerationObjectType fromApi(String value) => values.firstWhere(
    (t) => t.apiValue == value,
    orElse: () => ModerationObjectType.user,
  );
}

/// Bearbeitungsstatus einer Anfrage (API: `status`).
enum ModerationRequestStatus {
  unread('unread', 'Ungelesen'),
  read('read', 'Gelesen'),
  inWork('in_work', 'In Bearbeitung'),
  externalContact('external_contact', 'Externer Kontakt nötig'),
  publicDecision('public_decision', 'Öffentliche Entscheidung'),
  accepted('accepted', 'Akzeptiert'),
  denied('denied', 'Abgelehnt'),
  postponed('postponed', 'Verschoben');

  final String apiValue;
  final String label;

  const ModerationRequestStatus(this.apiValue, this.label);

  static ModerationRequestStatus fromApi(String value) => values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => ModerationRequestStatus.unread,
  );
}

/// Eine Moderations-Anfrage bzw. Meldung.
class ModerationRequest {
  final String id;
  final String userId;
  final String? userDisplayName;
  final String? userImage;
  final ModerationRequestType requestType;
  final ModerationObjectType objectType;
  final String objectId;
  final String message;
  final ModerationRequestStatus status;
  final String? adminComment;
  final String createdAt;
  final String updatedAt;

  const ModerationRequest({
    required this.id,
    required this.userId,
    this.userDisplayName,
    this.userImage,
    required this.requestType,
    required this.objectType,
    required this.objectId,
    required this.message,
    required this.status,
    this.adminComment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModerationRequest.fromJson(Map<String, dynamic> json) {
    return ModerationRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String?,
      userImage: json['userImage'] as String?,
      requestType: ModerationRequestType.fromApi(json['requestType'] as String),
      objectType: ModerationObjectType.fromApi(json['objectType'] as String),
      objectId: json['objectId'] as String,
      message: json['message'] as String,
      status: ModerationRequestStatus.fromApi(json['status'] as String),
      adminComment: json['adminComment'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class ModerationRequestListResponse {
  final List<ModerationRequest> data;
  final PaginationMeta meta;

  const ModerationRequestListResponse({required this.data, required this.meta});

  factory ModerationRequestListResponse.fromJson(Map<String, dynamic> json) {
    final requests = (json['data'] as List)
        .map((e) => ModerationRequest.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>);
    return ModerationRequestListResponse(data: requests, meta: meta);
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasMore => page < totalPages;
}

class ModerationRequestCreateRequest {
  final ModerationRequestType requestType;
  final ModerationObjectType objectType;
  final String objectId;
  final String message;

  const ModerationRequestCreateRequest({
    required this.requestType,
    required this.objectType,
    required this.objectId,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'requestType': requestType.apiValue,
    'objectType': objectType.apiValue,
    'objectId': objectId,
    'message': message,
  };
}
