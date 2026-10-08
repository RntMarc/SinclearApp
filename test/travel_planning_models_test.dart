import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/travel/models/travel_planning_models.dart';

void main() {
  group('PlanningTrip.fromJson', () {
    test('parst Zustand, Fortschritt und fehlendes Datum', () {
      final trip = PlanningTrip.fromJson({
        'id': 'p1',
        'name': 'Sommerurlaub',
        'state': 'planning',
        'allDay': true,
        'timezone': 'Europe/Berlin',
        'startDate': null,
        'endDate': null,
        'role': 'leader',
        'memberStatus': 'accepted',
        'canManage': true,
        'memberCount': 3,
        'topicStatus': {'participants': 'completed', 'travel': 'pending'},
      });

      expect(trip.hasDate, isFalse);
      expect(trip.canManage, isTrue);
      expect(trip.memberCount, 3);
      expect(trip.topicStatusFor('participants'), 'completed');
      expect(trip.topicStatusFor('program'), 'pending');
      expect(trip.isLeader, isTrue);
    });

    test('parst ganzzahlige Booleans und ISO-Daten', () {
      final trip = PlanningTrip.fromJson({
        'id': 'p1',
        'name': 'X',
        'allDay': 1,
        'canManage': 0,
        'startDate': '2026-09-01',
        'endDate': '2026-09-05',
      });

      expect(trip.allDay, isTrue);
      expect(trip.canManage, isFalse);
      expect(trip.hasDate, isTrue);
      expect(trip.startDate, DateTime(2026, 9, 1));
    });
  });

  group('PlanningTripDetail.fromJson', () {
    test('parst verschachtelte Listen', () {
      final detail = PlanningTripDetail.fromJson({
        'id': 'p1',
        'name': 'Reise',
        'state': 'planning',
        'topics': [
          {
            'id': 't1',
            'tripId': 'p1',
            'topic': 'participants',
            'status': 'in_progress',
          },
        ],
        'members': [
          {
            'memberId': 'm1',
            'tripId': 'p1',
            'userId': 'u1',
            'status': 'accepted',
            'role': 'leader',
            'displayName': 'Max',
          },
        ],
        'dateOptions': [
          {
            'id': 'd1',
            'tripId': 'p1',
            'allDay': true,
            'timezone': 'UTC',
            'isFinal': true,
            'responses': [
              {'userId': 'u1', 'availability': 'yes'},
            ],
          },
        ],
        'transport': [
          {
            'id': 'tr1',
            'tripId': 'p1',
            'userId': 'u1',
            'direction': 'outbound',
            'offersRide': 1,
            'availableSeats': 2,
          },
        ],
        'accommodationOptions': [
          {
            'id': 'a1',
            'tripId': 'p1',
            'name': 'Hotel',
            'pricePerPersonPerNight': '42.50',
            'currency': 'EUR',
            'isSelected': true,
          },
        ],
        'eventSuggestions': [
          {
            'id': 'e1',
            'tripId': 'p1',
            'name': 'Museum',
            'allDay': false,
            'timezone': 'UTC',
            'isConfirmed': true,
            'interests': [
              {'userId': 'u1', 'interest': 'maybe'},
            ],
          },
        ],
      });

      expect(detail.topics.single.topic, 'participants');
      expect(detail.members.single.isLeader, isTrue);
      expect(detail.dateOptions.single.isFinal, isTrue);
      expect(detail.dateOptions.single.responses.single.availability, 'yes');
      expect(detail.transport.single.offersRide, isTrue);
      expect(detail.transport.single.availableSeats, 2);
      expect(
        detail.accommodationOptions.single.pricePerPersonPerNight,
        '42.50',
      );
      expect(detail.accommodationOptions.single.isSelected, isTrue);
      expect(detail.eventSuggestions.single.isConfirmed, isTrue);
      expect(detail.eventSuggestions.single.interests.single.interest, 'maybe');
    });
  });

  group('PlanningPhase', () {
    test('feste Reihenfolge und deutsche Labels', () {
      expect(PlanningPhase.order, ['participants', 'travel', 'program']);
      expect(PlanningPhase.label('participants'), 'Wann und wer?');
      expect(PlanningPhase.label('travel'), 'Wo und wie?');
      expect(PlanningPhase.label('program'), 'Was machen wir?');
    });

    test(
      'jede Phase hat eine Erklärung, unbekannte Topics fallen leer aus',
      () {
        expect(PlanningPhase.explanation('participants'), isNotEmpty);
        expect(PlanningPhase.explanation('travel'), isNotEmpty);
        expect(PlanningPhase.explanation('program'), isNotEmpty);
        expect(PlanningPhase.explanation('unbekannt'), isEmpty);
      },
    );

    test('allResolved: abgeschlossen oder übersprungen zählt', () {
      expect(
        PlanningPhase.allResolved({
          'participants': 'completed',
          'travel': 'skipped',
          'program': 'completed',
        }),
        isTrue,
      );
    });

    test('allResolved: offene oder begonnene Phase blockiert', () {
      expect(
        PlanningPhase.allResolved({
          'participants': 'completed',
          'travel': 'in_progress',
          'program': 'skipped',
        }),
        isFalse,
      );
      expect(
        PlanningPhase.allResolved({
          'participants': 'completed',
          'travel': 'skipped',
        }),
        isFalse,
      );
      expect(PlanningPhase.allResolved(const {}), isFalse);
    });
  });

  group('PlanningTrip.allPhasesResolved', () {
    test('leitet sich aus topicStatus ab', () {
      final resolved = PlanningTrip.fromJson({
        'id': 'p1',
        'name': 'X',
        'topicStatus': {
          'participants': 'completed',
          'travel': 'skipped',
          'program': 'completed',
        },
      });
      final open = PlanningTrip.fromJson({
        'id': 'p2',
        'name': 'Y',
        'topicStatus': {'participants': 'completed'},
      });

      expect(resolved.allPhasesResolved, isTrue);
      expect(open.allPhasesResolved, isFalse);
    });
  });

  group('PlanEventSuggestion.fromJson', () {
    test('fehlende Zeitfelder bleiben null', () {
      final suggestion = PlanEventSuggestion.fromJson({
        'id': 'e1',
        'tripId': 'p1',
        'name': 'Spaziergang',
        'allDay': false,
        'timezone': 'UTC',
        'startAt': null,
        'endAt': null,
      });

      expect(suggestion.startAt, isNull);
      expect(suggestion.startDate, isNull);
      expect(suggestion.dayIndex, 0);
    });
  });
}
