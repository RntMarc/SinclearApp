import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/features/travel/models/travel_models.dart';
import 'package:sinclear_beyond/features/travel/widgets/accommodation_picker_sheet.dart';
import 'package:sinclear_beyond/features/travel/widgets/planning_sheets.dart';

Widget wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// Harness-Button, der eine Sheet-Funktion öffnet und den Rückgabewert ablegt.
Widget opener(Future<void> Function(BuildContext) open) {
  return Builder(
    builder: (context) => Center(
      child: ElevatedButton(
        onPressed: () => open(context),
        child: const Text('öffnen'),
      ),
    ),
  );
}

TravelAccommodation accommodation(String id, String name, {String? address}) =>
    TravelAccommodation(id: id, name: name, address: address, ishotel: 1);

void main() {
  group('PlanningInvitePicker', () {
    testWidgets(
      'zeigt kein Einladen-Badge und macht die ganze Zeile klickbar',
      (tester) async {
        String? picked;
        await tester.pumpWidget(
          wrap(
            PlanningInvitePicker(
              candidates: const [
                (id: 'u1', displayName: 'Lena', image: null),
                (id: 'u2', displayName: 'Ben', image: null),
              ],
              onPick: (id) => picked = id,
            ),
          ),
        );

        expect(find.text('Zur Planung einladen'), findsOneWidget);
        expect(find.text('Lena'), findsOneWidget);
        expect(find.text('Ben'), findsOneWidget);

        // Der Button wurde durch einen dezenten Tipp-Hinweis ersetzt.
        expect(find.text('Einladen'), findsNothing);
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));

        await tester.tap(find.text('Ben'));
        expect(picked, 'u2');
      },
    );

    testWidgets('zeigt bei leerer Auswahl einen Hinweis', (tester) async {
      await tester.pumpWidget(
        wrap(PlanningInvitePicker(candidates: const [], onPick: (_) {})),
      );

      expect(find.text('Keine weiteren Nutzer verfügbar.'), findsOneWidget);
    });
  });

  group('showAccommodationPicker', () {
    testWidgets('zeigt Erklärung, filtert client-seitig und liefert die ID', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        wrap(
          opener((context) async {
            picked = await showAccommodationPicker(
              context,
              options: [
                accommodation('a1', 'Hotel Alpen', address: 'Zermatt'),
                accommodation('a2', 'Hostel Tal', address: 'Interlaken'),
              ],
              title: 'Gespeicherte Unterkünfte',
              description: 'Unterkünfte aus früheren Reisen.',
              searchable: true,
            );
          }),
        ),
      );

      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();

      expect(find.text('Gespeicherte Unterkünfte'), findsOneWidget);
      expect(find.text('Unterkünfte aus früheren Reisen.'), findsOneWidget);
      expect(find.text('Hotel Alpen'), findsOneWidget);
      expect(find.text('Hostel Tal'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'alpen');
      await tester.pumpAndSettle();

      expect(find.text('Hotel Alpen'), findsOneWidget);
      expect(find.text('Hostel Tal'), findsNothing);

      await tester.tap(find.text('Hotel Alpen'));
      await tester.pumpAndSettle();
      expect(picked, 'a1');
    });

    testWidgets('ohne searchable fehlt das Suchfeld', (tester) async {
      await tester.pumpWidget(
        wrap(
          opener((context) async {
            await showAccommodationPicker(
              context,
              options: [accommodation('a1', 'Hotel Alpen')],
            );
          }),
        ),
      );

      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Hotel Alpen'), findsOneWidget);
    });
  });

  group('showPlanningAccommodationSheet', () {
    testWidgets('nutzt einen Button statt der Inline-Suche', (tester) async {
      await tester.pumpWidget(
        wrap(
          opener((context) => showPlanningAccommodationSheet(context: context)),
        ),
      );

      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();

      expect(find.text('Unterkunft vorschlagen'), findsOneWidget);
      expect(find.text('Gespeicherte Unterkünfte wählen'), findsOneWidget);
      expect(find.text('Name der Unterkunft'), findsNothing);
    });
  });
}
