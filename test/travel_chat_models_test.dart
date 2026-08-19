import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/chat/models/chat_models.dart';
import 'package:sinclear_beyond/features/travel/models/travel_models.dart';

void main() {
  group('ChatConversation group parsing', () {
    test('parses group type with name and null otherUser', () {
      final json = <String, dynamic>{
        'id': 'conv-1',
        'type': 'group',
        'name': 'Sommerurlaub 2025',
        'otherUser': null,
        'lastMessage': null,
        'unreadCount': 3,
        'lastSeenAt': null,
        'lastReadSeq': 42,
        'otherLastReadSeq': null,
        'createdAt': '2025-06-01 09:00:00',
        'updatedAt': '2025-06-15 14:00:00',
      };

      final conversation = ChatConversation.fromJson(json);

      expect(conversation.id, 'conv-1');
      expect(conversation.type, 'group');
      expect(conversation.name, 'Sommerurlaub 2025');
      expect(conversation.otherUser, isNull);
      expect(conversation.unreadCount, 3);
      expect(conversation.lastSeenAt, isNull);
    });

    test('group with null name falls back gracefully', () {
      final json = <String, dynamic>{
        'id': 'conv-2',
        'type': 'group',
        'name': null,
        'otherUser': null,
        'lastMessage': null,
        'unreadCount': 0,
        'lastSeenAt': null,
        'lastReadSeq': 0,
        'otherLastReadSeq': null,
        'createdAt': '2025-06-01 09:00:00',
        'updatedAt': '2025-06-15 14:00:00',
      };

      final conversation = ChatConversation.fromJson(json);

      expect(conversation.type, 'group');
      expect(conversation.name, isNull);
      expect(conversation.otherUser, isNull);
    });
  });

  group('TravelTrip conversationId', () {
    test('parses conversationId from JSON', () {
      final trip = TravelTrip.fromJson({
        'id': 'trip-1',
        'name': 'Urlaub',
        'description': null,
        'start': '2025-08-01 10:00:00',
        'end': '2025-08-15 18:00:00',
        'hastickets': '1',
        'ticket': null,
        'ticketUrl': null,
        'forumId': null,
        'forum': null,
        'conversationId': 'chat-abc',
        'subscriptionCount': 0,
      });

      expect(trip.conversationId, 'chat-abc');
    });

    test('conversationId defaults to null when absent', () {
      final trip = TravelTrip.fromJson({
        'id': 'trip-2',
        'name': 'Reise',
        'description': null,
        'start': '2025-08-01 10:00:00',
        'end': '2025-08-15 18:00:00',
        'hastickets': '0',
      });

      expect(trip.conversationId, isNull);
    });
  });

  group('TravelEvent conversationId', () {
    test('parses conversationId from JSON', () {
      final event = TravelEvent.fromJson({
        'ID': 'evt-1',
        'trip': 'trip-1',
        'name': 'Konzert',
        'description': null,
        'start': '2025-08-10 20:00:00',
        'end': '2025-08-10 23:00:00',
        'hastickets': '0',
        'conversationId': 'chat-def',
      });

      expect(event.conversationId, 'chat-def');
    });

    test('conversationId defaults to null when absent', () {
      final event = TravelEvent.fromJson({
        'ID': 'evt-2',
        'trip': 'trip-1',
        'name': 'Event',
        'start': '2025-08-10 20:00:00',
        'end': '2025-08-10 23:00:00',
        'hastickets': '0',
      });

      expect(event.conversationId, isNull);
    });
  });
}
