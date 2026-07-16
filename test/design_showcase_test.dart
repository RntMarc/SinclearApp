import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_segmented_switch.dart';
import 'package:sinclear_beyond/features/showcase/screens/design_showcase_screen.dart';

void main() {
  testWidgets('Design-Switcher wechselt die aktive Variante', (tester) async {
    final notifier = ValueNotifier<DesignVariant>(DesignVariant.materiaPop);
    await tester.pumpWidget(
      MaterialApp(
        home: DesignScope(
          variant: notifier,
          child: Scaffold(body: Center(child: DesignSegmentedSwitch())),
        ),
      ),
    );

    expect(notifier.value, DesignVariant.materiaPop);

    await tester.tap(find.text('Aurora Glass'));
    await tester.pumpAndSettle();
    expect(notifier.value, DesignVariant.auroraGlass);

    await tester.tap(find.text('Liquid Pulse'));
    await tester.pumpAndSettle();
    expect(notifier.value, DesignVariant.liquidPulse);

    await tester.tap(find.text('Materia Pop'));
    await tester.pumpAndSettle();
    expect(notifier.value, DesignVariant.materiaPop);
  });

  testWidgets('Showcase-Screen baut mit aktivem Design', (tester) async {
    final notifier = ValueNotifier<DesignVariant>(DesignVariant.materiaPop);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesignScope(
            variant: notifier,
            child: const DesignShowcaseScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beyond'), findsWidgets);
    expect(find.text('Materia Pop'), findsWidgets);
    expect(find.byType(DesignSegmentedSwitch), findsOneWidget);
  });
}
