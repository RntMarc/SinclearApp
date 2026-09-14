import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/primitives/design_fab.dart';

Widget wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('zeigt das Icon und löst Taps ohne loading aus', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        DesignFab(icon: Icons.arrow_forward_rounded, onPressed: () => taps++),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(DesignFab));
    expect(taps, 1);
  });

  testWidgets('loading: Spinner statt Icon, Taps gesperrt', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        DesignFab(
          icon: Icons.arrow_forward_rounded,
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(DesignFab));
    expect(taps, 0);
  });
}
