import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/utils/date_utils.dart';
import 'package:sinclear_beyond/features/polls/models/poll_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('Enums', () {
    test('PollType parst API-Werte mit Fallback form', () {
      expect(PollType.fromApi('form'), PollType.form);
      expect(PollType.fromApi('appointment'), PollType.appointment);
      expect(PollType.fromApi('vote'), PollType.vote);
      expect(PollType.fromApi('unbekannt'), PollType.form);
      expect(PollType.fromApi(null), PollType.form);
    });

    test('weitere Enums parsen ihre API-Werte', () {
      expect(PollStatus.fromApi('closed'), PollStatus.closed);
      expect(PollAccessMode.fromApi('all_users'), PollAccessMode.allUsers);
      expect(
        PollSubmissionMode.fromApi('multiple'),
        PollSubmissionMode.multiple,
      );
      expect(
        PollResultsVisibility.fromApi('participants'),
        PollResultsVisibility.participants,
      );
      expect(PollAvailability.fromApi('maybe'), PollAvailability.maybe);
      expect(PollAvailability.fromApi('quatsch'), isNull);
    });

    test('alle 13 Fragetypen sind definiert', () {
      expect(PollQuestionType.values.length, 13);
      expect(
        PollQuestionType.fromApi('multiple_choice'),
        PollQuestionType.multipleChoice,
      );
      expect(PollQuestionType.singleChoice.hasOptions, isTrue);
      expect(PollQuestionType.text.hasOptions, isFalse);
    });
  });

  group('Antwortwert-Semantik', () {
    test('boolean: "1"/"0"', () {
      expect(encodeBooleanAnswer(true), '1');
      expect(encodeBooleanAnswer(false), '0');
      expect(parseBooleanAnswer('1'), isTrue);
      expect(parseBooleanAnswer('0'), isFalse);
      expect(parseBooleanAnswer(true), isTrue);
      expect(parseBooleanAnswer('nope'), isNull);
    });

    test('coordinates: "lat,lon"', () {
      expect(encodeCoordinatesAnswer(52.5, 13.4), '52.5,13.4');
      final parsed = parseCoordinatesAnswer('52.5,13.4');
      expect(parsed?.latitude, 52.5);
      expect(parsed?.longitude, 13.4);
      expect(parseCoordinatesAnswer('kaputt'), isNull);
      expect(parseCoordinatesAnswer(null), isNull);
    });

    test('multiple_choice: JSON-Array oder einzelner String', () {
      expect(parseMultipleChoiceAnswer(['a', 'b']), ['a', 'b']);
      expect(parseMultipleChoiceAnswer('["a","b"]'), ['a', 'b']);
      expect(parseMultipleChoiceAnswer('a'), ['a']);
      expect(parseMultipleChoiceAnswer(null), isEmpty);
    });
  });

  group('Poll.fromJson', () {
    test('parst Felder und RFC-3339-Frist', () {
      final poll = Poll.fromJson({
        'id': 'p1',
        'type': 'appointment',
        'creatorId': 'u1',
        'creatorDisplayName': 'Tom',
        'title': 'Radtour',
        'description': null,
        'status': 'open',
        'closesAt': '2026-08-20T18:00:00+02:00',
        'accessMode': 'invited',
        'submissionMode': 'single',
        'resultsVisibility': 'creator',
        'allowCounterProposals': true,
        'finalizedOptionId': null,
        'isCreator': true,
        'createdAt': '2026-08-01T08:00:00Z',
        'updatedAt': '2026-08-01T08:00:00Z',
      });

      expect(poll.type, PollType.appointment);
      expect(poll.allowCounterProposals, isTrue);
      expect(poll.isCreator, isTrue);
      expect(poll.closesAt, toApiInstantDateTime('2026-08-20T16:00:00Z'));
      expect(poll.isClosed, isFalse);
      expect(poll.allowMultiple, isFalse);
    });

    test('allowMultiple wird aus der API gelesen', () {
      final poll = Poll.fromJson({
        'id': 'p2',
        'type': 'vote',
        'creatorId': 'u1',
        'title': 'Abstimmung',
        'status': 'open',
        'accessMode': 'all_users',
        'submissionMode': 'single',
        'resultsVisibility': 'creator',
        'allowCounterProposals': false,
        'allowMultiple': true,
        'isCreator': false,
        'createdAt': '2026-08-01T08:00:00Z',
        'updatedAt': '2026-08-01T08:00:00Z',
      });

      expect(poll.allowMultiple, isTrue);
    });
  });

  group('PollDetail.fromJson', () {
    test('parst Fragen, Optionen und Teilnahmestatus', () {
      final detail = PollDetail.fromJson({
        'id': 'p1',
        'type': 'form',
        'creatorId': 'u1',
        'title': 'Feedback',
        'status': 'open',
        'accessMode': 'all_users',
        'submissionMode': 'single',
        'resultsVisibility': 'creator',
        'allowCounterProposals': false,
        'isCreator': false,
        'createdAt': '2026-08-01T08:00:00Z',
        'updatedAt': '2026-08-01T08:00:00Z',
        'isInvited': true,
        'questions': [
          {
            'id': 'q1',
            'pollId': 'p1',
            'type': 'multiple_choice',
            'title': 'Auswahl',
            'isRequired': true,
            'position': 0,
            'config': {'minSelected': 1, 'maxSelected': 2},
          },
        ],
        'options': [
          {
            'id': 'o1',
            'pollId': 'p1',
            'questionId': 'q1',
            'label': 'A',
            'allDay': false,
            'timezone': 'Europe/Berlin',
            'isCounterProposal': false,
            'position': 0,
          },
        ],
        'participantStatus': {'hasResponded': true, 'hasAvailability': false},
      });

      expect(detail.isInvited, isTrue);
      expect(detail.questions.single.type, PollQuestionType.multipleChoice);
      expect(detail.questions.single.intConfig('maxSelected'), 2);
      expect(detail.optionsFor('q1').single.label, 'A');
      expect(detail.participantStatus.hasResponded, isTrue);
    });
  });

  group('PollOption Date/Time', () {
    test('allDay option parst zivile Tage ohne Verschiebung', () {
      final option = PollOption.fromJson({
        'id': 'o1',
        'pollId': 'p1',
        'allDay': true,
        'timezone': 'Europe/Berlin',
        'startDate': '2026-08-20',
        'endDate': '2026-08-21',
        'isCounterProposal': false,
        'position': 0,
      });

      expect(option.startDate, DateTime(2026, 8, 20));
      expect(option.endDate, DateTime(2026, 8, 21));
      expect(option.displayLabel, '20.08.2026 – 21.08.2026');
    });

    test('getaktete Option parst RFC-3339-Instant', () {
      final option = PollOption.fromJson({
        'id': 'o2',
        'pollId': 'p1',
        'allDay': false,
        'timezone': 'Europe/Berlin',
        'startAt': '2026-08-20T18:00:00+02:00',
        'endAt': '2026-08-20T20:00:00+02:00',
        'isCounterProposal': false,
        'position': 0,
      });

      expect(option.startAt, DateTime.utc(2026, 8, 20, 16));
      expect(option.displayLabel, '20.08.2026 18:00 – 20:00');
    });

    test('gespeicherte Bezeichnung wird bei Terminvorschlägen ignoriert', () {
      final option = PollOption.fromJson({
        'id': 'o3',
        'pollId': 'p1',
        'label': 'Nachmittag',
        'allDay': false,
        'timezone': 'Europe/Berlin',
        'startAt': '2026-08-20T18:00:00+02:00',
        'endAt': '2026-08-20T20:00:00+02:00',
        'isCounterProposal': false,
        'position': 0,
      });

      expect(option.displayLabel, '20.08.2026 18:00 – 20:00');
    });
  });

  group('PollOptionInput.toJson', () {
    test('ganztägig sendet nur Datumsfelder samt Zeitzone', () {
      final json = PollOptionInput(
        label: 'Tag',
        allDay: true,
        timezone: 'Europe/Berlin',
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 21),
      ).toJson();

      expect(json['allDay'], isTrue);
      expect(json['startDate'], '2026-08-20');
      expect(json['endDate'], '2026-08-21');
      expect(json.containsKey('startAt'), isFalse);
      expect(json.containsKey('endAt'), isFalse);
    });

    test('getaktet sendet nur RFC-3339-Felder', () {
      final json = PollOptionInput(
        allDay: false,
        timezone: 'Europe/Berlin',
        startAt: DateTime.utc(2026, 8, 20, 16),
        endAt: DateTime.utc(2026, 8, 20, 18),
      ).toJson();

      expect(json['startAt'], '2026-08-20T18:00:00+02:00');
      expect(json['endAt'], '2026-08-20T20:00:00+02:00');
      expect(json.containsKey('startDate'), isFalse);
    });
  });

  group('PollCreateRequest.toJson', () {
    test('form sendet submission/results, appointment Options', () {
      final form = const PollCreateRequest(
        type: PollType.form,
        title: 'Feedback',
        submissionMode: PollSubmissionMode.multiple,
        resultsVisibility: PollResultsVisibility.participants,
        questions: [
          PollQuestionInput(
            type: PollQuestionType.singleChoice,
            title: 'Wahl',
            optionLabels: ['A', 'B'],
            config: {},
          ),
        ],
      ).toJson();

      expect(form['submissionMode'], 'multiple');
      expect(form['resultsVisibility'], 'participants');
      expect(form.containsKey('allowCounterProposals'), isFalse);
      expect((form['questions'] as List).single['options'], isA<List>());

      final appointment = const PollCreateRequest(
        type: PollType.appointment,
        title: 'Termin',
        allowCounterProposals: true,
      ).toJson();
      expect(appointment['allowCounterProposals'], isTrue);
      expect(appointment.containsKey('submissionMode'), isFalse);
    });

    test('vote sendet allowMultiple, andere Typen nicht', () {
      final vote = const PollCreateRequest(
        type: PollType.vote,
        title: 'Abstimmung',
        allowMultiple: true,
      ).toJson();
      expect(vote['allowMultiple'], isTrue);
      expect(vote.containsKey('allowCounterProposals'), isFalse);

      final single = const PollCreateRequest(
        type: PollType.vote,
        title: 'Abstimmung',
      ).toJson();
      expect(single['allowMultiple'], isFalse);

      final appointment = const PollCreateRequest(
        type: PollType.appointment,
        title: 'Termin',
      ).toJson();
      expect(appointment.containsKey('allowMultiple'), isFalse);
    });
  });
}

/// Hilfsvergleich für einen RFC-3339-String als UTC-Instant.
DateTime toApiInstantDateTime(String value) => parseApiInstant(value);
