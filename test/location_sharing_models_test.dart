import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/location_sharing/models/location_sharing_models.dart';

void main() {
  group('LocationSharingSession.fromJson', () {
    test('parst Session inkl. Detail-Feldern', () {
      final json = {
        'id': 's1',
        'token': 'a1b2c3d4e5f678901234567890abcdef',
        'ownerId': 'u1',
        'sharingMode': 'route',
        'durationSeconds': 3600,
        'frequencySeconds': 600,
        'isActive': true,
        'startedAt': '2026-07-03 12:00:00',
        'expiresAt': '2026-07-03 13:00:00',
        'createdAt': '2026-07-03 12:00:00',
        'updatedAt': '2026-07-03 12:00:00',
        'recipients': [
          {'userId': 'u2', 'displayName': 'User 2', 'image': null},
        ],
        'lastLocation': {
          'id': 'l1',
          'latitude': 48.137154,
          'longitude': 11.576124,
          'accuracy': 10.5,
          'recordedAt': '2026-07-03 12:05:00',
          'createdAt': '2026-07-03 12:05:00',
        },
        'locationCount': 1,
        'integrationUrls': {'osmand': 'https://example.invalid/osmand/token'},
      };

      final session = LocationSharingSession.fromJson(json);

      expect(session.id, 's1');
      expect(session.sharingMode, SharingMode.route);
      expect(session.isActive, isTrue);
      expect(session.durationSeconds, 3600);
      expect(session.expiresAt, isNotNull);
      expect(session.recipients.single.displayName, 'User 2');
      expect(session.lastLocation?.latitude, 48.137154);
      expect(session.locationCount, 1);
      expect(session.integrationUrls['osmand'], contains('osmand'));
    });

    test('behandelt unbegrenzte Dauer und fehlende Extras', () {
      final json = {
        'id': 's2',
        'token': 'a1b2c3d4e5f678901234567890abcdef',
        'ownerId': 'u1',
        'sharingMode': 'location',
        'durationSeconds': null,
        'frequencySeconds': 600,
        'isActive': true,
        'startedAt': '2026-07-03 12:00:00',
        'expiresAt': null,
        'createdAt': '2026-07-03 12:00:00',
        'updatedAt': '2026-07-03 12:00:00',
      };

      final session = LocationSharingSession.fromJson(json);

      expect(session.sharingMode, SharingMode.location);
      expect(session.durationSeconds, isNull);
      expect(session.expiresAt, isNull);
      expect(session.recipients, isEmpty);
      expect(session.lastLocation, isNull);
    });
  });

  group('ActiveLocationSharing.fromJson', () {
    test('parst owner und lastLocation', () {
      final json = {
        'session': {
          'id': 's3',
          'token': 'a1b2c3d4e5f678901234567890abcdef',
          'ownerId': 'owner1',
          'sharingMode': 'location',
          'durationSeconds': null,
          'frequencySeconds': 600,
          'isActive': true,
          'startedAt': '2026-07-03 12:00:00',
          'expiresAt': null,
          'createdAt': '2026-07-03 12:00:00',
          'updatedAt': '2026-07-03 12:00:00',
        },
        'owner': {'id': 'owner1', 'displayName': 'Owner', 'image': null},
        'lastLocation': {
          'id': 'l2',
          'latitude': 52.52,
          'longitude': 13.405,
          'accuracy': null,
          'recordedAt': '2026-07-03 12:30:00',
          'createdAt': '2026-07-03 12:30:00',
        },
      };

      final active = ActiveLocationSharing.fromJson(json);

      expect(active.ownerDisplayName, 'Owner');
      expect(active.lastLocation?.longitude, 13.405);
      expect(active.session.ownerId, 'owner1');
    });
  });
}
