import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_color_picker.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: DesignScope(
        variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: 300, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('reports the initial color and hex value', (tester) async {
    Color? picked;
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF0064EA),
          onChanged: (c) => picked = c,
        ),
      ),
    );
    expect(find.text('#0064EA'), findsOneWidget);
    expect(picked, isNull);
  });

  testWidgets('hex input drives the preview live', (tester) async {
    Color? picked;
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF0064EA),
          onChanged: (c) => picked = c,
        ),
      ),
    );
    final field = find.byType(TextField);
    await tester.enterText(field, '#E53935');
    await tester.pump();
    expect(picked, const Color(0xFFE53935));
  });

  testWidgets('sat/value pan updates the picked color', (tester) async {
    Color? picked;
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF0000FF), // hue = 240
          onChanged: (c) => picked = c,
        ),
      ),
    );
    // Pan in the sat/value pane (top-most area) towards bottom-right.
    await tester.drag(find.byType(GestureDetector).first, const Offset(100, 60));
    await tester.pump();
    expect(picked, isNotNull);
  });
}