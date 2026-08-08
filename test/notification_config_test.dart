import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/config/notification_config.dart';

void main() {
  group('NotificationTypeLabel.route', () {
    test('mappt Admin-Deep-Link-Werte auf deutsche Routen', () {
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'home'}),
        '/home',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'travel'}),
        '/reisen',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'events'}),
        '/kalender',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'profile'}),
        '/einstellungen/profil',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'settings'}),
        '/einstellungen',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'friends'}),
        '/kontakte',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'discover'}),
        '/entdecken',
      );
      expect(
        NotificationTypeLabel.route('admin.test', {'deepLink': 'feedback'}),
        '/feedback',
      );
    });

    test('liefert null für unbekannte Admin-Ziele', () {
      expect(
        NotificationTypeLabel.route('admin.custom', {'deepLink': 'news'}),
        isNull,
      );
      expect(
        NotificationTypeLabel.route('admin.custom', {'deepLink': 'chat'}),
        isNull,
      );
      expect(NotificationTypeLabel.route('admin.test', {}), isNull);
    });

    test('leitet Kalender-Codes mit Event-Id auf die Event-Detailseite', () {
      expect(
        NotificationTypeLabel.route('calendar.event_created', {
          'calendarEventId': 'event-1',
        }),
        '/kalender/event-1',
      );
      expect(
        NotificationTypeLabel.route('calendar.event_updated', {
          'calendarEventId': 'event-1',
        }),
        '/kalender/event-1',
      );
      expect(
        NotificationTypeLabel.route('calendar.participant_added', {
          'calendarEventId': 'event-1',
        }),
        '/kalender/event-1',
      );
    });

    test('liefert null ohne Id oder für unbekannte Codes', () {
      expect(NotificationTypeLabel.route('calendar.event_created', {}), isNull);
      expect(
        NotificationTypeLabel.route('location_sharing.started', {
          'locationSharingSessionId': 's1',
        }),
        isNull,
      );
      expect(NotificationTypeLabel.route('unbekannt.code', {}), isNull);
    });
  });

  group('NotificationTypeLabel Rendering', () {
    test('rendert die neuen Aktivitäts-Codes', () {
      expect(
        NotificationTypeLabel.title('calendar.event_created', {}),
        'Neues Kalender-Event',
      );
      expect(
        NotificationTypeLabel.title('location_sharing.started', {}),
        'Live-Standort wird geteilt',
      );
      expect(
        NotificationTypeLabel.body('location_sharing.started', {
          'ownerDisplayName': 'Max',
        }),
        contains('Max'),
      );
    });
  });

  test('locale Anzeige ist von der Route-Auflösung unabhängig', () {
    expect(
      NotificationTypeLabel.body('location_sharing.started', {}),
      contains('teilt seinen Live-Standort'),
    );
  });
}
