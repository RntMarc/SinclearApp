import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_plan_phase_progress.dart';
import 'package:sinclear_beyond/design/widgets/primitives/design_button.dart';
import 'package:sinclear_beyond/design/widgets/primitives/design_chip.dart';
import 'package:sinclear_beyond/features/travel/models/travel_planning_models.dart';
import 'package:sinclear_beyond/features/travel/screens/planning_create_screen.dart';
import 'package:sinclear_beyond/features/travel/widgets/planning_widgets.dart';

Widget wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Widget wrapFull(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

PlanMember member({
  required String userId,
  String status = 'invited',
  String role = 'member',
  String name = 'Person',
}) {
  return PlanMember(
    memberId: 'm-$userId',
    tripId: 'p1',
    userId: userId,
    status: status,
    role: role,
    displayName: name,
  );
}

PlanDateOption dateOption({
  String id = 'd1',
  String? label = 'Woche 1',
  bool isFinal = false,
  String? proposedBy = 'u1',
  List<PlanDateResponse> responses = const [],
}) {
  return PlanDateOption(
    id: id,
    tripId: 'p1',
    label: label,
    allDay: true,
    timezone: 'Europe/Berlin',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 7),
    isFinal: isFinal,
    proposedBy: proposedBy,
    responses: responses,
  );
}

void main() {
  group('Adapter', () {
    test('planningPhases bildet den Themenstatus ab', () {
      final trip = PlanningTrip.fromJson({
        'id': 'p1',
        'name': 'T',
        'topicStatus': {
          'participants': 'completed',
          'travel': 'in_progress',
          'program': 'skipped',
        },
      });

      final phases = planningPhases(trip);
      expect(phases.map((p) => p.label), [
        'Wann und wer?',
        'Wo und wie?',
        'Was machen wir?',
      ]);
      expect(phases[0].status, DesignPlanPhaseStatus.completed);
      expect(phases[1].status, DesignPlanPhaseStatus.inProgress);
      expect(phases[2].status, DesignPlanPhaseStatus.skipped);
    });

    test('planningDateLabel nutzt Label, sonst Zeitraum, sonst Hinweis', () {
      expect(planningDateLabel(dateOption()), 'Woche 1');

      final noLabel = PlanDateOption(
        id: 'd2',
        tripId: 'p1',
        allDay: true,
        timezone: 'Europe/Berlin',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 2),
      );
      expect(planningDateLabel(noLabel), contains('01.07.2026'));

      final empty = const PlanDateOption(id: 'd3', tripId: 'p1');
      expect(planningDateLabel(empty), 'Ohne Datum');
    });
  });

  group('DesignPlanPhaseProgress', () {
    testWidgets('zeigt Status als Text, nicht nur Farbe', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DesignPlanPhaseProgress(
            phases: [
              DesignPlanPhase(
                label: 'Wann und wer?',
                status: DesignPlanPhaseStatus.completed,
              ),
              DesignPlanPhase(
                label: 'Wo und wie?',
                status: DesignPlanPhaseStatus.pending,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Wann und wer?'), findsOneWidget);
      expect(find.text('Abgeschlossen'), findsOneWidget);
      expect(find.text('Ausstehend'), findsOneWidget);
    });
  });

  group('PlanningInviteBanner', () {
    testWidgets('löst Zusagen/Ablehnen aus', (tester) async {
      var accepted = 0;
      var declined = 0;
      await tester.pumpWidget(
        wrap(
          PlanningInviteBanner(
            busy: false,
            onAccept: () => accepted++,
            onDecline: () => declined++,
          ),
        ),
      );

      await tester.tap(find.text('Zusagen'));
      await tester.tap(find.text('Ablehnen'));
      expect(accepted, 1);
      expect(declined, 1);
    });
  });

  group('PlanningMembersSection', () {
    testWidgets('zeigt Leitung/Status und Einladen nur für die Leitung', (
      tester,
    ) async {
      var invited = 0;
      PlanMember? managed;
      await tester.pumpWidget(
        wrap(
          PlanningMembersSection(
            members: [
              member(
                userId: 'leader',
                role: 'leader',
                status: 'accepted',
                name: 'Lena',
              ),
              member(userId: 'u2', status: 'declined', name: 'Ben'),
            ],
            canManage: true,
            onInvite: () => invited++,
            onManageMember: (m) => managed = m,
          ),
        ),
      );

      expect(find.text('Leitung'), findsOneWidget);
      expect(find.text('Zugesagt'), findsOneWidget);
      expect(find.text('Abgelehnt'), findsOneWidget);

      await tester.tap(find.text('Einladen'));
      expect(invited, 1);

      await tester.tap(find.text('Ben'));
      expect(managed?.userId, 'u2');
    });

    testWidgets('blendet Leitungsaktionen für Mitglieder aus', (tester) async {
      await tester.pumpWidget(
        wrap(
          PlanningMembersSection(
            members: [member(userId: 'u2', name: 'Ben')],
            canManage: false,
            onInvite: () {},
            onManageMember: (_) {},
          ),
        ),
      );

      expect(find.text('Einladen'), findsNothing);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });
  });

  group('PlanningPhaseSection', () {
    testWidgets('Begonnene Phase ist offen, Inhalt sichtbar', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PlanningPhaseSection(
            label: 'Wann und wer?',
            status: 'in_progress',
            child: Text('Inhalt'),
          ),
        ),
      );

      expect(find.text('Inhalt'), findsOneWidget);
      expect(find.text('Begonnen'), findsOneWidget);
    });

    testWidgets('Ausstehende Phase bleibt zu und ohne Inhalt', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PlanningPhaseSection(
            label: 'Wo und wie?',
            status: 'pending',
            child: Text('Inhalt'),
          ),
        ),
      );

      expect(find.text('Inhalt'), findsNothing);
      expect(find.text('Ausstehend'), findsOneWidget);
    });

    testWidgets('Abgeschlossene Phase lässt sich ausklappen', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PlanningPhaseSection(
            label: 'Was machen wir?',
            status: 'completed',
            child: Text('Inhalt'),
          ),
        ),
      );

      expect(find.text('Inhalt'), findsNothing);
      await tester.tap(find.text('Was machen wir?'));
      await tester.pumpAndSettle();
      expect(find.text('Inhalt'), findsOneWidget);
    });
  });

  group('PlanningDateOptionsSection', () {
    testWidgets('markiert festgelegten Termin und erlaubt Festlegen', (
      tester,
    ) async {
      String? finalized;
      await tester.pumpWidget(
        wrap(
          PlanningDateOptionsSection(
            options: [
              dateOption(id: 'd1', label: 'Woche 1', isFinal: true),
              dateOption(id: 'd2', label: 'Woche 2'),
            ],
            canManage: true,
            currentUserId: 'leader',
            onRespond: (_, _) {},
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onFinalize: (option) => finalized = option.id,
          ),
        ),
      );

      // Der Zeitraum ist der Titel, die Bezeichnung steht kleiner darunter.
      expect(find.text('Festgelegt'), findsOneWidget);
      expect(find.text('Woche 1'), findsOneWidget);
      expect(find.text('Woche 2'), findsOneWidget);

      // Die Leitungsaktion liegt im Drei-Punkte-Menü der zweiten Karte.
      await tester.tap(find.byIcon(Icons.more_vert_rounded).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Festlegen'));
      await tester.pumpAndSettle();
      expect(finalized, 'd2');
    });

    testWidgets('zeigt Leitungsaktionen nicht für einfache Mitglieder', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PlanningDateOptionsSection(
            options: [dateOption(id: 'd1', proposedBy: 'someone-else')],
            canManage: false,
            currentUserId: 'u1',
            onRespond: (_, _) {},
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onFinalize: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
      expect(find.text('Noch keine Terminvorschläge.'), findsNothing);
    });
  });

  group('PlanningAccommodationSection', () {
    testWidgets('zeigt Preis, Gewählt-Badge und Auswählen für die Leitung', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          PlanningAccommodationSection(
            options: const [
              PlanAccommodationOption(
                id: 'a1',
                tripId: 'p1',
                name: 'Hotel Alpen',
                pricePerPersonPerNight: '42.50',
                currency: 'EUR',
                isSelected: true,
              ),
              PlanAccommodationOption(
                id: 'a2',
                tripId: 'p1',
                name: 'Hostel Tal',
              ),
            ],
            canManage: true,
            currentUserId: 'leader',
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onSelect: (option) => selected = option.id,
          ),
        ),
      );

      expect(find.text('Gewählt'), findsOneWidget);
      expect(find.text('42.50 EUR pro Person/Nacht'), findsOneWidget);

      await tester.tap(find.widgetWithText(DesignButton, 'Auswählen'));
      expect(selected, 'a2');
    });
  });

  group('PlanningEventsSection', () {
    testWidgets('zeigt Interesse, Bestätigen und Zusammenfassung', (
      tester,
    ) async {
      String? interest;
      var confirmed = false;
      await tester.pumpWidget(
        wrap(
          PlanningEventsSection(
            suggestions: [
              PlanEventSuggestion(
                id: 'e1',
                tripId: 'p1',
                name: 'Wanderung',
                allDay: true,
                timezone: 'Europe/Berlin',
                startDate: DateTime(2026, 7, 2),
                endDate: DateTime(2026, 7, 2),
                interests: const [
                  PlanEventInterest(userId: 'u2', interest: 'yes'),
                  PlanEventInterest(userId: 'u3', interest: 'maybe'),
                ],
              ),
            ],
            canManage: true,
            currentUserId: 'leader',
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onConfirm: (_, value) => confirmed = value,
            onInterest: (_, value) => interest = value,
          ),
        ),
      );

      expect(find.textContaining('1 Ja'), findsOneWidget);
      expect(find.textContaining('1 Vielleicht'), findsOneWidget);

      await tester.tap(find.widgetWithText(DesignChip, 'Ja'));
      expect(interest, 'yes');

      await tester.tap(find.widgetWithText(DesignButton, 'Bestätigen'));
      expect(confirmed, isTrue);
    });
  });

  group('PlanningCreateScreen', () {
    testWidgets('zeigt die drei Phasen und validiert den Namen', (
      tester,
    ) async {
      await tester.pumpWidget(wrapFull(const PlanningCreateScreen()));

      expect(find.text('Reise gemeinsam planen'), findsOneWidget);
      expect(find.text('Wann und wer?'), findsOneWidget);
      expect(find.text('Wo und wie?'), findsOneWidget);
      expect(find.text('Was machen wir?'), findsOneWidget);

      // Leerer Name: Validierung greift, bevor die API gerufen wird.
      final button = find.widgetWithText(DesignButton, 'Planung erstellen');
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bitte gib einen Namen an.'), findsOneWidget);
    });
  });
}
