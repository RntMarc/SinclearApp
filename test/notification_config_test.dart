import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/config/notification_config.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';

void main() {
  /// Relation-Liste exakt so, wie die API sie für `forum_reply` liefert.
  const forumReplyData = [
    NotificationRelation(
      relation: 'reply_author',
      object: 'User',
      identifier: 'user-reply',
    ),
    NotificationRelation(
      relation: 'comment_author',
      object: 'User',
      identifier: 'user-comment',
    ),
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-post',
    ),
    NotificationRelation(
      relation: 'parent_comment',
      object: 'ForumPostComment',
      identifier: 'c1',
    ),
    NotificationRelation(
      relation: 'parent_post',
      object: 'ForumPost',
      identifier: 'p1',
    ),
    NotificationRelation(
      relation: 'parent_forum',
      object: 'Forum',
      identifier: 'f1',
    ),
  ];

  /// Relation-Liste exakt so, wie die API sie für `forum_comment` liefert
  /// (bewusst ohne `parent_comment` und `reply_author`).
  const forumCommentData = [
    NotificationRelation(
      relation: 'comment_author',
      object: 'User',
      identifier: 'user-comment',
    ),
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-post',
    ),
    NotificationRelation(
      relation: 'parent_post',
      object: 'ForumPost',
      identifier: 'p1',
    ),
    NotificationRelation(
      relation: 'parent_forum',
      object: 'Forum',
      identifier: 'f1',
    ),
  ];

  /// Relation-Liste exakt so, wie die API sie für `forum_post` liefert.
  const forumPostData = [
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-author',
    ),
    NotificationRelation(
      relation: 'parent_post',
      object: 'ForumPost',
      identifier: 'p1',
    ),
    NotificationRelation(
      relation: 'parent_forum',
      object: 'Forum',
      identifier: 'f1',
    ),
  ];

  /// Relation-Liste exakt so, wie die API sie für `forum_upvote` liefert.
  const forumUpvoteData = [
    NotificationRelation(
      relation: 'voter',
      object: 'User',
      identifier: 'user-voter',
    ),
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-author',
    ),
    NotificationRelation(
      relation: 'parent_post',
      object: 'ForumPost',
      identifier: 'p1',
    ),
    NotificationRelation(
      relation: 'parent_forum',
      object: 'Forum',
      identifier: 'f1',
    ),
  ];

  /// Relation-Liste exakt so, wie die API sie für `story_post` liefert.
  const storyPostData = [
    NotificationRelation(
      relation: 'story_author',
      object: 'User',
      identifier: 'user-story',
    ),
    NotificationRelation(relation: 'story', object: 'Story', identifier: 's1'),
  ];

  /// Relation-Liste für `trip_user_added` (Typ mit `trip` Relation).
  const tripUserData = [
    NotificationRelation(
      relation: 'added_user',
      object: 'User',
      identifier: 'u1',
    ),
    NotificationRelation(relation: 'trip', object: 'Trip', identifier: 't1'),
    NotificationRelation(
      relation: 'added_by',
      object: 'User',
      identifier: 'u2',
    ),
  ];

  /// Relation-Liste für `standalone_event_user_added` (Typ mit `event`
  /// Relation, ohne `trip`).
  const standaloneEventData = [
    NotificationRelation(
      relation: 'added_user',
      object: 'User',
      identifier: 'u1',
    ),
    NotificationRelation(relation: 'event', object: 'Event', identifier: 'e1'),
    NotificationRelation(
      relation: 'added_by',
      object: 'User',
      identifier: 'u2',
    ),
  ];

  /// Relation-Liste für `direct_message` (Sender + Konversation).
  const directMessageData = [
    NotificationRelation(
      relation: 'sender',
      object: 'User',
      identifier: 'user-sender',
    ),
    NotificationRelation(
      relation: 'conversation',
      object: 'ChatConversation',
      identifier: 'conv1',
    ),
    NotificationRelation(
      relation: 'message',
      object: 'DirectMessage',
      identifier: 'msg1',
    ),
  ];

  group('NotificationTypeLabel.route', () {
    test('forum_reply navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_reply', forumReplyData),
        '/forum/f1/beitrag/p1',
      );
    });

    test('forum_comment navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_comment', forumCommentData),
        '/forum/f1/beitrag/p1',
      );
    });

    test('forum_reply ohne parent_forum oder parent_post gibt null', () {
      final ohneForum = forumReplyData
          .where((e) => e.relation != 'parent_forum')
          .toList();
      final ohnePost = forumReplyData
          .where((e) => e.relation != 'parent_post')
          .toList();

      expect(NotificationTypeLabel.route('forum_reply', ohneForum), isNull);
      expect(NotificationTypeLabel.route('forum_reply', ohnePost), isNull);
      expect(NotificationTypeLabel.route('forum_reply', const []), isNull);
    });

    test('forum_comment ohne parent_forum oder parent_post gibt null', () {
      final ohneForum = forumCommentData
          .where((e) => e.relation != 'parent_forum')
          .toList();
      final ohnePost = forumCommentData
          .where((e) => e.relation != 'parent_post')
          .toList();

      expect(NotificationTypeLabel.route('forum_comment', ohneForum), isNull);
      expect(NotificationTypeLabel.route('forum_comment', ohnePost), isNull);
    });

    test('forum_post navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_post', forumPostData),
        '/forum/f1/beitrag/p1',
      );
    });

    test('forum_post ohne parent_forum oder parent_post gibt null', () {
      final ohneForum = forumPostData
          .where((e) => e.relation != 'parent_forum')
          .toList();
      final ohnePost = forumPostData
          .where((e) => e.relation != 'parent_post')
          .toList();

      expect(NotificationTypeLabel.route('forum_post', ohneForum), isNull);
      expect(NotificationTypeLabel.route('forum_post', ohnePost), isNull);
      expect(NotificationTypeLabel.route('forum_post', const []), isNull);
    });

    test('forum_upvote navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_upvote', forumUpvoteData),
        '/forum/f1/beitrag/p1',
      );
    });

    test('forum_upvote ohne parent_forum oder parent_post gibt null', () {
      final ohneForum = forumUpvoteData
          .where((e) => e.relation != 'parent_forum')
          .toList();
      final ohnePost = forumUpvoteData
          .where((e) => e.relation != 'parent_post')
          .toList();

      expect(NotificationTypeLabel.route('forum_upvote', ohneForum), isNull);
      expect(NotificationTypeLabel.route('forum_upvote', ohnePost), isNull);
      expect(NotificationTypeLabel.route('forum_upvote', const []), isNull);
    });

    test('story_post navigiert zur Story (/stories/{s})', () {
      expect(
        NotificationTypeLabel.route('story_post', storyPostData),
        '/stories/s1',
      );
    });

    test('story_post ohne story Relation gibt null', () {
      final ohneStory = storyPostData
          .where((e) => e.relation != 'story')
          .toList();

      expect(NotificationTypeLabel.route('story_post', ohneStory), isNull);
      expect(NotificationTypeLabel.route('story_post', const []), isNull);
    });

    test('trip_user_added navigiert zur Reise (/reisen/{t})', () {
      expect(
        NotificationTypeLabel.route('trip_user_added', tripUserData),
        '/reisen/t1',
      );
    });

    test('trip_user_added ohne trip Relation gibt null', () {
      final ohneTrip = tripUserData.where((e) => e.relation != 'trip').toList();

      expect(NotificationTypeLabel.route('trip_user_added', ohneTrip), isNull);
      expect(NotificationTypeLabel.route('trip_user_added', const []), isNull);
    });

    test('trip_event_added navigiert zur Reise (/reisen/{t})', () {
      expect(
        NotificationTypeLabel.route('trip_event_added', tripUserData),
        '/reisen/t1',
      );
    });

    test('trip_ticket_added navigiert zur Reise (/reisen/{t})', () {
      expect(
        NotificationTypeLabel.route('trip_ticket_added', tripUserData),
        '/reisen/t1',
      );
    });

    test('trip_accommodation_added navigiert zur Reise (/reisen/{t})', () {
      expect(
        NotificationTypeLabel.route('trip_accommodation_added', tripUserData),
        '/reisen/t1',
      );
    });

    test('trip_subscription_added navigiert zur Reise (/reisen/{t})', () {
      expect(
        NotificationTypeLabel.route('trip_subscription_added', tripUserData),
        '/reisen/t1',
      );
    });

    test('trip_info_changed navigiert zur Reise (/reisen/{t})', () {
      expect(
        NotificationTypeLabel.route('trip_info_changed', tripUserData),
        '/reisen/t1',
      );
    });

    test('standalone_event_user_added navigiert zum Einzelevent '
        '(/reisen/einzelevent/{e})', () {
      expect(
        NotificationTypeLabel.route(
          'standalone_event_user_added',
          standaloneEventData,
        ),
        '/reisen/einzelevent/e1',
      );
    });

    test('standalone_event_ticket_added navigiert zum Einzelevent', () {
      expect(
        NotificationTypeLabel.route(
          'standalone_event_ticket_added',
          standaloneEventData,
        ),
        '/reisen/einzelevent/e1',
      );
    });

    test('standalone_event_info_changed navigiert zum Einzelevent', () {
      expect(
        NotificationTypeLabel.route(
          'standalone_event_info_changed',
          standaloneEventData,
        ),
        '/reisen/einzelevent/e1',
      );
    });

    test('standalone_event_user_added_others navigiert zum Einzelevent', () {
      expect(
        NotificationTypeLabel.route(
          'standalone_event_user_added_others',
          standaloneEventData,
        ),
        '/reisen/einzelevent/e1',
      );
    });

    test('standalone_event_user_added ohne event Relation gibt null', () {
      final ohneEvent = standaloneEventData
          .where((e) => e.relation != 'event')
          .toList();

      expect(
        NotificationTypeLabel.route('standalone_event_user_added', ohneEvent),
        isNull,
      );
      expect(
        NotificationTypeLabel.route('standalone_event_user_added', const []),
        isNull,
      );
    });

    test('direct_message navigiert zum Chat (/chat/{conversation})', () {
      expect(
        NotificationTypeLabel.route('direct_message', directMessageData),
        '/chat/conv1',
      );
    });

    test('direct_message ohne conversation Relation gibt null', () {
      final ohneConversation = directMessageData
          .where((e) => e.relation != 'conversation')
          .toList();

      expect(
        NotificationTypeLabel.route('direct_message', ohneConversation),
        isNull,
      );
      expect(NotificationTypeLabel.route('direct_message', const []), isNull);
    });

    test('unbekannte Typen geben null (Inbox-Fallback)', () {
      expect(NotificationTypeLabel.route('unbekannt', forumReplyData), isNull);
      expect(NotificationTypeLabel.route('', const []), isNull);
    });
  });

  group('NotificationTypeLabel Fallback-Rendering', () {
    test('forum_reply rendert Titel, generalisierten Text und Icon', () {
      expect(
        NotificationTypeLabel.title('forum_reply'),
        'Neue Antwort auf deinen Kommentar',
      );
      expect(
        NotificationTypeLabel.fallbackBody('forum_reply'),
        'Jemand hat auf deinen Kommentar geantwortet.',
      );
      expect(NotificationTypeLabel.icon('forum_reply'), Icons.forum_rounded);
    });

    test('forum_comment rendert Titel, generalisierten Text und Icon', () {
      expect(
        NotificationTypeLabel.title('forum_comment'),
        'Neuer Kommentar zu deinem Beitrag',
      );
      expect(
        NotificationTypeLabel.fallbackBody('forum_comment'),
        'Jemand hat deinen Beitrag kommentiert.',
      );
      expect(NotificationTypeLabel.icon('forum_comment'), Icons.forum_rounded);
    });

    test('forum_post rendert Titel, generalisierten Text und Icon', () {
      expect(
        NotificationTypeLabel.title('forum_post'),
        'Neuer Beitrag im Forum',
      );
      expect(
        NotificationTypeLabel.fallbackBody('forum_post'),
        'Jemand hat einen neuen Beitrag im Forum veröffentlicht.',
      );
      expect(NotificationTypeLabel.icon('forum_post'), Icons.forum_rounded);
    });

    test('forum_upvote rendert Titel, generalisierten Text und Icon', () {
      expect(NotificationTypeLabel.title('forum_upvote'), 'Neue Bewertung');
      expect(
        NotificationTypeLabel.fallbackBody('forum_upvote'),
        'Jemand hat deinen Beitrag positiv bewertet.',
      );
      expect(NotificationTypeLabel.icon('forum_upvote'), Icons.forum_rounded);
    });

    test('story_post rendert Titel, generalisierten Text und Icon', () {
      expect(NotificationTypeLabel.title('story_post'), 'Neue Story');
      expect(
        NotificationTypeLabel.fallbackBody('story_post'),
        'Jemand hat eine neue Story veröffentlicht.',
      );
      expect(
        NotificationTypeLabel.icon('story_post'),
        Icons.auto_stories_rounded,
      );
    });

    test('direct_message rendert Titel, generalisierten Text und Icon', () {
      expect(NotificationTypeLabel.title('direct_message'), 'Neue Nachricht');
      expect(
        NotificationTypeLabel.fallbackBody('direct_message'),
        'Du hast eine neue Nachricht.',
      );
      expect(NotificationTypeLabel.icon('direct_message'), Icons.chat_rounded);
    });

    test('trip_user_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_user_added'),
        'Du wurdest zu einer Reise hinzugefügt',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_user_added'),
        'Du wurdest zu einer Reise hinzugefügt.',
      );
      expect(NotificationTypeLabel.icon('trip_user_added'), Icons.card_travel);
    });

    test('trip_user_added_others rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_user_added_others'),
        'Neuer Teilnehmer auf der Reise',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_user_added_others'),
        'Ein neuer Teilnehmer wurde zur Reise hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('trip_user_added_others'),
        Icons.card_travel,
      );
    });

    test('trip_event_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_event_added'),
        'Neues Event auf der Reise',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_event_added'),
        'Ein neues Event wurde zur Reise hinzugefügt.',
      );
      expect(NotificationTypeLabel.icon('trip_event_added'), Icons.event);
    });

    test('trip_event_user_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_event_user_added'),
        'Du wurdest zu einem Event hinzugefügt',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_event_user_added'),
        'Du wurdest zu einem Event hinzugefügt.',
      );
      expect(NotificationTypeLabel.icon('trip_event_user_added'), Icons.event);
    });

    test('trip_event_user_added_others rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_event_user_added_others'),
        'Neuer Teilnehmer beim Event',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_event_user_added_others'),
        'Ein neuer Teilnehmer wurde zum Event hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('trip_event_user_added_others'),
        Icons.event,
      );
    });

    test('trip_event_info_changed rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_event_info_changed'),
        'Event-Informationen geändert',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_event_info_changed'),
        'Die Event-Informationen wurden geändert.',
      );
      expect(
        NotificationTypeLabel.icon('trip_event_info_changed'),
        Icons.info_outline,
      );
    });

    test('trip_event_ticket_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_event_ticket_added'),
        'Neues Ticket für das Event',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_event_ticket_added'),
        'Ein neues Ticket wurde zum Event hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('trip_event_ticket_added'),
        Icons.confirmation_num,
      );
    });

    test('trip_ticket_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_ticket_added'),
        'Neues Ticket für die Reise',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_ticket_added'),
        'Ein neues Ticket wurde zur Reise hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('trip_ticket_added'),
        Icons.confirmation_num,
      );
    });

    test('trip_accommodation_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_accommodation_added'),
        'Hotel-Zuweisung',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_accommodation_added'),
        'Dir wurde ein Hotel zugewiesen.',
      );
      expect(
        NotificationTypeLabel.icon('trip_accommodation_added'),
        Icons.hotel,
      );
    });

    test('trip_subscription_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_subscription_added'),
        'Neues Abo verknüpft',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_subscription_added'),
        'Ein Abo wurde mit der Reise verknüpft.',
      );
      expect(
        NotificationTypeLabel.icon('trip_subscription_added'),
        Icons.receipt_long,
      );
    });

    test('trip_info_changed rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('trip_info_changed'),
        'Reise-Informationen geändert',
      );
      expect(
        NotificationTypeLabel.fallbackBody('trip_info_changed'),
        'Die Reise-Informationen wurden geändert.',
      );
      expect(
        NotificationTypeLabel.icon('trip_info_changed'),
        Icons.card_travel,
      );
    });

    test('standalone_event_user_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('standalone_event_user_added'),
        'Du wurdest zu einem Event hinzugefügt',
      );
      expect(
        NotificationTypeLabel.fallbackBody('standalone_event_user_added'),
        'Du wurdest zu einem Event hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('standalone_event_user_added'),
        Icons.event,
      );
    });

    test('standalone_event_user_added_others rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('standalone_event_user_added_others'),
        'Neuer Teilnehmer beim Event',
      );
      expect(
        NotificationTypeLabel.fallbackBody(
          'standalone_event_user_added_others',
        ),
        'Ein neuer Teilnehmer wurde zum Event hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('standalone_event_user_added_others'),
        Icons.event,
      );
    });

    test('standalone_event_info_changed rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('standalone_event_info_changed'),
        'Event-Informationen geändert',
      );
      expect(
        NotificationTypeLabel.fallbackBody('standalone_event_info_changed'),
        'Die Event-Informationen wurden geändert.',
      );
      expect(
        NotificationTypeLabel.icon('standalone_event_info_changed'),
        Icons.info_outline,
      );
    });

    test('standalone_event_ticket_added rendert Titel, Text und Icon', () {
      expect(
        NotificationTypeLabel.title('standalone_event_ticket_added'),
        'Neues Ticket für das Event',
      );
      expect(
        NotificationTypeLabel.fallbackBody('standalone_event_ticket_added'),
        'Ein neues Ticket wurde zum Event hinzugefügt.',
      );
      expect(
        NotificationTypeLabel.icon('standalone_event_ticket_added'),
        Icons.confirmation_num,
      );
    });

    test('unbekannte Typen rendern generische Standardwerte', () {
      expect(NotificationTypeLabel.title('unbekannt'), 'Neue Mitteilung');
      expect(NotificationTypeLabel.fallbackBody('unbekannt'), isNotEmpty);
      expect(
        NotificationTypeLabel.icon('unbekannt'),
        Icons.notifications_rounded,
      );
    });
  });

  group('NotificationTypeLabel.category', () {
    test('gruppiert alle Preference-Schlüssel', () {
      expect(NotificationTypeLabel.category('forum_reply'), 'Forum');
      expect(NotificationTypeLabel.category('forum_comment'), 'Forum');
      expect(NotificationTypeLabel.category('forum_post'), 'Forum');
      expect(NotificationTypeLabel.category('forum_upvote'), 'Forum');
      expect(NotificationTypeLabel.category('story_post'), 'Stories');
      expect(NotificationTypeLabel.category('direct_message'), 'Chat');
      expect(NotificationTypeLabel.category('trip_user_added'), 'Reisen');
      expect(
        NotificationTypeLabel.category('trip_user_added_others'),
        'Reisen',
      );
      expect(NotificationTypeLabel.category('trip_info_changed'), 'Reisen');
      expect(NotificationTypeLabel.category('trip_event_added'), 'Reisen');
      expect(NotificationTypeLabel.category('event_user_added'), 'Events');
      expect(
        NotificationTypeLabel.category('event_user_added_others'),
        'Events',
      );
      expect(NotificationTypeLabel.category('event_info_changed'), 'Events');
      expect(NotificationTypeLabel.category('event_ticket_added'), 'Tickets');
      expect(NotificationTypeLabel.category('trip_ticket_added'), 'Tickets');
      expect(
        NotificationTypeLabel.category('trip_accommodation_added'),
        'Unterkunft',
      );
      expect(NotificationTypeLabel.category('trip_subscription_added'), 'Abos');
    });

    test('interne Event-Typen haben keine Kategorie (nur in Präferenzen '
        'vereinheitlicht)', () {
      expect(
        NotificationTypeLabel.category('standalone_event_user_added'),
        isNull,
      );
      expect(
        NotificationTypeLabel.category('standalone_event_user_added_others'),
        isNull,
      );
      expect(
        NotificationTypeLabel.category('standalone_event_info_changed'),
        isNull,
      );
      expect(
        NotificationTypeLabel.category('standalone_event_ticket_added'),
        isNull,
      );
      expect(NotificationTypeLabel.category('trip_event_user_added'), isNull);
      expect(
        NotificationTypeLabel.category('trip_event_user_added_others'),
        isNull,
      );
      expect(NotificationTypeLabel.category('trip_event_info_changed'), isNull);
      expect(NotificationTypeLabel.category('trip_event_ticket_added'), isNull);
    });

    test('unbekannte Typen haben keine Kategorie (werden nicht angezeigt)', () {
      expect(NotificationTypeLabel.category('unbekannt'), isNull);
      expect(NotificationTypeLabel.category(''), isNull);
    });
  });

  group('NotificationTypeLabel vereinheitlichte Event-Keys', () {
    test('event_user_added rendert Titel und Icon', () {
      expect(
        NotificationTypeLabel.title('event_user_added'),
        'Du wurdest zu einem Event hinzugefügt',
      );
      expect(NotificationTypeLabel.icon('event_user_added'), Icons.event);
    });

    test('event_user_added_others rendert Titel und Icon', () {
      expect(
        NotificationTypeLabel.title('event_user_added_others'),
        'Neuer Teilnehmer beim Event',
      );
      expect(
        NotificationTypeLabel.icon('event_user_added_others'),
        Icons.event,
      );
    });

    test('event_info_changed rendert Titel und Icon', () {
      expect(
        NotificationTypeLabel.title('event_info_changed'),
        'Event-Informationen geändert',
      );
      expect(
        NotificationTypeLabel.icon('event_info_changed'),
        Icons.info_outline,
      );
    });

    test('event_ticket_added rendert Titel und Icon', () {
      expect(
        NotificationTypeLabel.title('event_ticket_added'),
        'Neues Ticket für das Event',
      );
      expect(
        NotificationTypeLabel.icon('event_ticket_added'),
        Icons.confirmation_num,
      );
    });
  });

  group('NotificationTypeLabel.customDataKey', () {
    test('Forum-Typen nutzen forumIds', () {
      expect(NotificationTypeLabel.customDataKey('forum_reply'), 'forumIds');
      expect(NotificationTypeLabel.customDataKey('forum_comment'), 'forumIds');
      expect(NotificationTypeLabel.customDataKey('forum_post'), 'forumIds');
    });

    test('forum_upvote unterstützt kein custom', () {
      expect(NotificationTypeLabel.customDataKey('forum_upvote'), isNull);
    });

    test('story_post nutzt userIds', () {
      expect(NotificationTypeLabel.customDataKey('story_post'), 'userIds');
    });

    test('direct_message nutzt userIds', () {
      expect(NotificationTypeLabel.customDataKey('direct_message'), 'userIds');
    });

    test('alle anderen Typen unterstützen kein custom', () {
      expect(NotificationTypeLabel.customDataKey('trip_user_added'), isNull);
      expect(NotificationTypeLabel.customDataKey('trip_ticket_added'), isNull);
      expect(NotificationTypeLabel.customDataKey('unbekannt'), isNull);
    });
  });
}
