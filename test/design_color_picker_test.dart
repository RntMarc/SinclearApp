import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_color_picker.dart';
import 'package:sinclear_beyond/design/widgets/primitives/design_slider.dart';

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

  testWidgets('renders three labeled sliders and the hex readout', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF0064EA),
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(DesignSlider), findsNWidgets(3));
    expect(find.text('Farbton'), findsOneWidget);
    expect(find.text('Sättigung'), findsOneWidget);
    expect(find.text('Helligkeit'), findsOneWidget);
    expect(find.text('#0064EA'), findsOneWidget);
  });

  /// Center of the 18px track at the bottom of the [DesignSlider] box.
  double trackY(Rect slider) => slider.bottom - 9;

  testWidgets('dragging the lightness slider stays in the readable range', (
    tester,
  ) async {
    Color? picked;
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF0064EA),
          onChanged: (c) => picked = c,
        ),
      ),
    );

    // Tap the far right of the lightness slider (third slider) -> max lightness.
    final slider = tester.getRect(find.byType(DesignSlider).at(2));
    await tester.tapAt(Offset(slider.right - 4, trackY(slider)));
    await tester.pump();

    expect(picked, isNotNull);
    final pickedLightness = HSLColor.fromColor(picked!).lightness;
    expect(
      pickedLightness,
      lessThanOrEqualTo(DesignColorPicker.maxLightness + 0.001),
    );
    expect(
      pickedLightness,
      greaterThanOrEqualTo(DesignColorPicker.minLightness - 0.001),
    );
    expect(pickedLightness, closeTo(DesignColorPicker.maxLightness, 0.02));
  });

  testWidgets('a near-white initial color is clamped into the readable range', (
    tester,
  ) async {
    Color? picked;
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF000000),
          onChanged: (c) => picked = c,
        ),
      ),
    );

    // Drag the hue slider across its track; lightness must stay clamped.
    final slider = tester.getRect(find.byType(DesignSlider).at(0));
    await tester.dragFrom(
      Offset(slider.left + 10, trackY(slider)),
      const Offset(200, 0),
    );
    await tester.pump();

    expect(picked, isNotNull);
    final lightness = HSLColor.fromColor(picked!).lightness;
    expect(lightness, lessThanOrEqualTo(DesignColorPicker.maxLightness + 0.005));
    expect(lightness, greaterThanOrEqualTo(DesignColorPicker.minLightness - 0.005));
  });

  testWidgets('hue tap in the middle reports a hue near 180', (tester) async {
    Color? picked;
    await tester.pumpWidget(
      wrap(
        DesignColorPicker(
          initialColor: const Color(0xFF0064EA),
          onChanged: (c) => picked = c,
        ),
      ),
    );

    // Tap the horizontal center of the hue slider -> fraction 0.5 -> 180°.
    final slider = tester.getRect(find.byType(DesignSlider).at(0));
    await tester.tapAt(Offset(slider.center.dx, trackY(slider)));
    await tester.pump();

    expect(picked, isNotNull);
    final hue = HSLColor.fromColor(picked!).hue;
    expect(hue, closeTo(180, 20));
  });
}