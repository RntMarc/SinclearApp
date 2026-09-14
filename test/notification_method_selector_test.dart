import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/features/notifications/widgets/notification_method_selector.dart';
import 'package:sinclear_beyond/features/settings/models/notification_preference.dart';

Widget wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('rendert Optionen und öffnet die Info', (tester) async {
    NotificationMethod? selected;
    await tester.pumpWidget(
      wrap(
        NotificationMethodSelector(
          selected: NotificationMethod.polling,
          onSelect: (method) => selected = method,
        ),
      ),
    );

    expect(find.text('Polling'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Vorteile'), findsOneWidget);
    expect(find.text('Nachteile'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Polling').first);
    expect(selected, NotificationMethod.polling);
  });
}
