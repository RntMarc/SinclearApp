import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/moderation/models/moderation_models.dart';

void main() {
  group('ModerationRequest.fromJson', () {
    Map<String, dynamic> sample() => {
      'id': 'request-1',
      'userId': 'user-1',
      'userDisplayName': 'max',
      'userImage': null,
      'requestType': 'report',
      'objectType': 'recipe',
      'objectId': 'recipe-1',
      'message': 'Allergenangaben falsch',
      'status': 'unread',
      'adminComment': null,
      'createdAt': '2026-08-01 12:00:00',
      'updatedAt': '2026-08-01 12:00:00',
    };

    test('parst alle Felder inklusive Enums', () {
      final request = ModerationRequest.fromJson(sample());
      expect(request.requestType, ModerationRequestType.report);
      expect(request.objectType, ModerationObjectType.recipe);
      expect(request.status, ModerationRequestStatus.unread);
      expect(request.adminComment, isNull);
    });

    test('Admin-Kommentar wird übernommen', () {
      final json = sample()..['adminComment'] = 'Entfernt';
      expect(ModerationRequest.fromJson(json).adminComment, 'Entfernt');
    });

    test('unbekannte API-Werte fallen auf sichere Defaults zurück', () {
      final json = sample()
        ..['requestType'] = 'unknown'
        ..['objectType'] = 'unknown'
        ..['status'] = 'unknown';
      final request = ModerationRequest.fromJson(json);
      expect(request.requestType, ModerationRequestType.other);
      expect(request.objectType, ModerationObjectType.user);
      expect(request.status, ModerationRequestStatus.unread);
    });
  });

  test('create-Request serialisiert die API-Enum-Werte', () {
    final body = const ModerationRequestCreateRequest(
      requestType: ModerationRequestType.deletion,
      objectType: ModerationObjectType.forumPost,
      objectId: 'post-1',
      message: 'Bitte löschen',
    ).toJson();
    expect(body['requestType'], 'deletion');
    expect(body['objectType'], 'forum_post');
    expect(body['message'], 'Bitte löschen');
  });

  test('ModerationRequestListResponse parst Paginierung', () {
    final response = ModerationRequestListResponse.fromJson({
      'data': [
        {
          'id': 'request-1',
          'userId': 'user-1',
          'requestType': 'other',
          'objectType': 'user',
          'objectId': 'user-2',
          'message': 'Hallo',
          'status': 'accepted',
          'createdAt': '2026-08-01 12:00:00',
          'updatedAt': '2026-08-01 12:00:00',
        },
      ],
      'meta': const {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
    });
    expect(response.data, hasLength(1));
    expect(response.data.first.status, ModerationRequestStatus.accepted);
    expect(response.meta.hasMore, isFalse);
  });
}
