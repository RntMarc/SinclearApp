import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/config/notification_config.dart';

void main() {
  group('NotificationTypeLabel.route', () {
    test('travel.* Codes navigieren zum Trip-Detail (/reisen/{tripId})', () {
      expect(
        NotificationTypeLabel.route('travel.event_created', {
          'tripId': 'trip-1',
        }),
        '/reisen/trip-1',
      );
      expect(
        NotificationTypeLabel.route('travel.event_updated', {
          'tripId': 'trip-1',
        }),
        '/reisen/trip-1',
      );
      expect(
        NotificationTypeLabel.route('travel.ticket_created', {
          'tripId': 'trip-1',
        }),
        '/reisen/trip-1',
      );
      expect(
        NotificationTypeLabel.route('travel.member_added', {
          'tripId': 'trip-1',
        }),
        '/reisen/trip-1',
      );
      expect(NotificationTypeLabel.route('travel.unknown', {}), isNull);
      expect(NotificationTypeLabel.route('travel.event_created', {}), isNull);
    });

    test('calendar.* Codes navigieren zum Event-Detail (/kalender/{id})', () {
      expect(
        NotificationTypeLabel.route('calendar.event_created', {
          'calendarEventId': 'evt-1',
        }),
        '/kalender/evt-1',
      );
      expect(
        NotificationTypeLabel.route('calendar.event_updated', {
          'calendarEventId': 'evt-1',
        }),
        '/kalender/evt-1',
      );
      expect(
        NotificationTypeLabel.route('calendar.participant_added', {
          'calendarEventId': 'evt-1',
        }),
        '/kalender/evt-1',
      );
      expect(NotificationTypeLabel.route('calendar.event_created', {}), isNull);
    });

    test('forum.* Codes navigieren zum Forum/Beitrag', () {
      expect(
        NotificationTypeLabel.route('forum.post_created', {'forumId': 'f1'}),
        '/forum/f1',
      );
      expect(
        NotificationTypeLabel.route('forum.reply_created', {
          'forumId': 'f1',
          'postId': 'p1',
        }),
        '/forum/f1/beitrag/p1',
      );
      expect(
        NotificationTypeLabel.route('forum.mention', {
          'forumId': 'f1',
          'postId': 'p1',
        }),
        '/forum/f1/beitrag/p1',
      );
      expect(NotificationTypeLabel.route('forum.post_created', {}), isNull);
    });

    test('recipe.* Codes navigieren zum Rezept-Detail (/rezepte/{id})', () {
      expect(
        NotificationTypeLabel.route('recipe.comment', {'recipeId': 'r1'}),
        '/rezepte/r1',
      );
      expect(
        NotificationTypeLabel.route('recipe.fork', {'recipeId': 'r1'}),
        '/rezepte/r1',
      );
      expect(NotificationTypeLabel.route('recipe.comment', {}), isNull);
    });

    test('friend.request navigiert zum Profil (/kontakte/{actorId})', () {
      expect(
        NotificationTypeLabel.route('friend.request', {'actorId': 'user-123'}),
        '/kontakte/user-123',
      );
      expect(NotificationTypeLabel.route('friend.request', {}), isNull);
    });

    test('admin.* nutzt deepLink aus Payload (deutsche Pfade)', () {
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'home'}),
        '/home',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': '/reisen'}),
        '/reisen',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': '/kalender'}),
        '/kalender',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {
          'deepLink': '/einstellungen/profil',
        }),
        '/einstellungen/profil',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'feedback'}),
        '/feedback',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': '/forum'}),
        '/forum',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'rezepte'}),
        '/rezepte',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': '/abos'}),
        '/abos',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {
          'deepLink': 'einstellungen',
        }),
        '/einstellungen',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': '/entdecken'}),
        '/entdecken',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': '/kontakte'}),
        '/kontakte',
      );
      expect(NotificationTypeLabel.route('admin.custom', {}), isNull);
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': ''}),
        isNull,
      );
    });

    test('Codes ohne dedizierten Screen geben null (Inbox-Fallback)', () {
      expect(
        NotificationTypeLabel.route('changelog.new_entry', {
          'changelogId': 'c1',
        }),
        isNull,
      );
      expect(
        NotificationTypeLabel.route('like.received', {'postId': 'p1'}),
        isNull,
      );
      expect(
        NotificationTypeLabel.route('location_sharing.started', {
          'locationSharingSessionId': 's1',
        }),
        isNull,
      );
    });

    test('unbekannte Codes geben null', () {
      expect(NotificationTypeLabel.route('unbekannt.code', {}), isNull);
    });
  });

  group('NotificationTypeLabel Rendering', () {
    test('Travel-Codes rendern korrekt', () {
      expect(
        NotificationTypeLabel.title('travel.event_created', {}),
        'Neues Reise-Event',
      );
      expect(
        NotificationTypeLabel.title('travel.ticket_created', {}),
        'Neues Ticket',
      );
      expect(
        NotificationTypeLabel.body('travel.event_created', {
          'tripTitle': 'Berlin',
          'eventTitle': 'Museum',
        }),
        contains('Berlin'),
      );
      expect(
        NotificationTypeLabel.icon('travel.member_added', {}),
        Icons.person_add_rounded,
      );
    });

    test('Calendar-Codes rendern korrekt', () {
      expect(
        NotificationTypeLabel.title('calendar.event_created', {}),
        'Neues Kalender-Event',
      );
      expect(
        NotificationTypeLabel.body('calendar.participant_added', {
          'title': 'Team-Meeting',
        }),
        'Team-Meeting',
      );
    });

    test('Forum-Codes rendern korrekt', () {
      expect(
        NotificationTypeLabel.title('forum.post_created', {}),
        'Neuer Forumsbeitrag',
      );
      expect(
        NotificationTypeLabel.title('forum.reply_created', {}),
        'Neue Antwort',
      );
      expect(
        NotificationTypeLabel.body('forum.mention', {
          'actorDisplayName': 'Max',
        }),
        contains('Max'),
      );
    });

    test('Recipe-Codes rendern korrekt', () {
      expect(
        NotificationTypeLabel.title('recipe.comment', {}),
        'Neuer Kommentar',
      );
      expect(NotificationTypeLabel.title('recipe.fork', {}), 'Rezept geforkt');
      expect(
        NotificationTypeLabel.body('recipe.fork', {
          'actorDisplayName': 'Anna',
          'recipeTitle': 'Kuchen',
        }),
        contains('Anna'),
      );
    });

    test('Admin-Codes rendern korrekt', () {
      expect(
        NotificationTypeLabel.title('admin.system_update', {}),
        'System-Update',
      );
      expect(
        NotificationTypeLabel.title('admin.custom', {'title': 'Spezial'}),
        'Spezial',
      );
      expect(
        NotificationTypeLabel.icon('admin.maintenance', {}),
        Icons.build_rounded,
      );
    });

    test('Sonstige Codes rendern korrekt', () {
      expect(
        NotificationTypeLabel.title('location_sharing.started', {}),
        'Live-Standort wird geteilt',
      );
      expect(
        NotificationTypeLabel.title('changelog.new_entry', {}),
        'Neuer Changelog-Eintrag',
      );
      expect(NotificationTypeLabel.title('like.received', {}), 'Like erhalten');
      expect(
        NotificationTypeLabel.title('friend.request', {}),
        'Freundschaftsanfrage',
      );
      expect(
        NotificationTypeLabel.body('location_sharing.started', {
          'ownerDisplayName': 'Max',
        }),
        contains('Max'),
      );
      expect(
        NotificationTypeLabel.body('like.received', {
          'actorDisplayName': 'Anna',
        }),
        contains('Anna'),
      );
      expect(
        NotificationTypeLabel.body('friend.request', {
          'actorDisplayName': 'Tom',
        }),
        contains('Tom'),
      );
      expect(
        NotificationTypeLabel.icon('changelog.new_entry', {}),
        Icons.description_rounded,
      );
      expect(
        NotificationTypeLabel.icon('like.received', {}),
        Icons.favorite_rounded,
      );
      expect(
        NotificationTypeLabel.icon('friend.request', {}),
        Icons.person_add_rounded,
      );
    });
  });
}
