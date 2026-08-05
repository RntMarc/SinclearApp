import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/effects/grain_painter.dart'
    show GrainOverlay;
import 'package:sinclear_beyond/design/theme/design_preferences.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/tokens/custom_tokens.dart';
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

    test('custom accent defaults to blue and roundtrips', () async {
      SharedPreferences.setMockInitialValues({});
      final loaded = await DesignPreferences.loadCustomAccent();
      expect(loaded.toARGB32(), const Color(0xFF0064EA).toARGB32());

      const red = Color(0xFFE53935);
      await DesignPreferences.saveCustomAccent(red);
      final loaded2 = await DesignPreferences.loadCustomAccent();
      expect(loaded2.toARGB32(), red.toARGB32());
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

  group('CustomTokens contrast', () {
    test('black on white has high contrast (not blocked)', () {
      expect(CustomTokens.isBlocked(Colors.black, Colors.white), isFalse);
    });

    test('white on white is blocked', () {
      expect(CustomTokens.isBlocked(Colors.white, Colors.white), isTrue);
    });

    test('contrast ratio for black on white is ~21:1', () {
      final ratio = CustomTokens.contrastRatio(Colors.black, Colors.white);
      expect(ratio, closeTo(21.0, 0.5));
    });

    test('bestOnColor picks white for dark accent', () {
      final result = CustomTokens.bestOnColor(const Color(0xFF1A1A2E));
      expect(result, Colors.white);
    });

    test('bestOnColor picks dark for light accent', () {
      final result = CustomTokens.bestOnColor(const Color(0xFFFFCA28));
      expect(result, const Color(0xFF1A1A2E));
    });
  });

  group('CustomAccentController', () {
    test('does not notify when color unchanged', () {
      final c = CustomAccentController(const Color(0xFF0064EA));
      var notifyCount = 0;
      c.addListener(() => notifyCount++);
      c.value = const Color(0xFF0064EA);
      expect(notifyCount, 0);
    });

    test('notifies when color changes', () {
      final c = CustomAccentController(const Color(0xFF0064EA));
      var notifyCount = 0;
      c.addListener(() => notifyCount++);
      c.value = const Color(0xFFE53935);
      expect(notifyCount, 1);
    });
  });
}
