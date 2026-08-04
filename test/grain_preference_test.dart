import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/effects/grain_painter.dart'
    show GrainOverlay;
import 'package:sinclear_beyond/design/theme/design_preferences.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/foundation/design_surface.dart';

void main() {
  group('DesignPreferences', () {
    test('grain opacity defaults to 0 and roundtrips', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await DesignPreferences.loadGrainOpacity(), 0.0);

      await DesignPreferences.saveGrainOpacity(0.5);
      expect(await DesignPreferences.loadGrainOpacity(), 0.5);

      await DesignPreferences.saveGrainOpacity(0.0);
      expect(await DesignPreferences.loadGrainOpacity(), 0.0);
    });

    test('theme mode defaults to system and roundtrips', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await DesignPreferences.loadThemeMode(), ThemeMode.system);

      await DesignPreferences.saveThemeMode(ThemeMode.dark);
      expect(await DesignPreferences.loadThemeMode(), ThemeMode.dark);

      await DesignPreferences.saveThemeMode(ThemeMode.light);
      expect(await DesignPreferences.loadThemeMode(), ThemeMode.light);

      await DesignPreferences.saveThemeMode(ThemeMode.system);
      expect(await DesignPreferences.loadThemeMode(), ThemeMode.system);
    });
  });

  group('GrainController', () {
    test('clamps value to 0..1', () {
      final c = GrainController(0.5);
      c.value = 1.5;
      expect(c.value, 1.0);

      c.value = -0.3;
      expect(c.value, 0.0);
    });

    test('does not notify when value unchanged', () {
      final c = GrainController(0.5);
      var notifyCount = 0;
      c.addListener(() => notifyCount++);
      c.value = 0.5;
      expect(notifyCount, 0);
    });
  });

  group('DesignSurface', () {
    testWidgets('hides grain when opacity is 0', (tester) async {
      final grain = ValueNotifier<double>(0.0);
      await tester.pumpWidget(
        MaterialApp(
          home: DesignScope(
            variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
            grain: grain,
            child: const DesignSurface(child: SizedBox()),
          ),
        ),
      );
      expect(find.byType(GrainOverlay), findsNothing);
    });

    testWidgets('shows grain when opacity > 0', (tester) async {
      final grain = ValueNotifier<double>(0.5);
      await tester.pumpWidget(
        MaterialApp(
          home: DesignScope(
            variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
            grain: grain,
            child: const DesignSurface(child: SizedBox()),
          ),
        ),
      );
      expect(find.byType(GrainOverlay), findsOneWidget);
    });

    testWidgets('hides grain when toggled off', (tester) async {
      final grain = ValueNotifier<double>(0.5);
      await tester.pumpWidget(
        MaterialApp(
          home: DesignScope(
            variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
            grain: grain,
            child: const DesignSurface(child: SizedBox()),
          ),
        ),
      );
      expect(find.byType(GrainOverlay), findsOneWidget);

      grain.value = 0.0;
      await tester.pump();
      expect(find.byType(GrainOverlay), findsNothing);
    });
  });

  group('ThemeMode persistence', () {
    testWidgets('DesignScope.themeModeOf returns the active mode', (
      tester,
    ) async {
      final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
      ThemeMode? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: DesignScope(
            variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
            themeMode: mode,
            child: Builder(
              builder: (context) {
                captured = DesignScope.themeModeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(captured, ThemeMode.dark);

      mode.value = ThemeMode.light;
      await tester.pump();
      expect(captured, ThemeMode.light);
    });
  });
}
