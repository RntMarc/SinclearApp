import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/features/travel/models/travel_models.dart';
import 'package:sinclear_beyond/features/travel/widgets/trip_detail_widgets.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: DesignScope(
      variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
      child: Scaffold(body: child),
    ),
  );
}

TravelEventTicket ticket(String id, String type) => TravelEventTicket(
  id: id,
  type: type,
  title: 'Ticket $id',
);

void main() {
  testWidgets('löschbares Ticket zeigt nur bei user-Typ den Löschen-Button', (
    tester,
  ) async {
    TravelEventTicket? deleted;
    await tester.pumpWidget(
      wrap(
        TripTicketsTab(
          tickets: [ticket('1', 'user'), ticket('2', 'event')],
          events: const [],
          onDelete: (t) async => deleted = t,
        ),
      ),
    );

    final deleteIcons = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIcons, findsOneWidget);

    await tester.tap(deleteIcons);
    await tester.pumpAndSettle();
    expect(deleted?.id, '1');
  });

  testWidgets('ohne onDelete-Callback erscheint kein Löschen-Button', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TripTicketsTab(
          tickets: [ticket('1', 'user')],
          events: const [],
        ),
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });
}