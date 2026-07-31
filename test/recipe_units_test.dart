import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/recipes/models/recipes_models.dart';

void main() {
  test('recipeUnits enthält die kanonischen, kleingeschriebenen Einheiten', () {
    for (final unit in ['g', 'kg', 'ml', 'l', 'tl', 'el', 'prise', 'stk']) {
      expect(
        recipeUnits.containsKey(unit),
        isTrue,
        reason: 'Einheit "$unit" fehlt',
      );
      expect(recipeUnits[unit], isNotEmpty);
    }
  });

  test('recipeUnitLabel fällt auf den Rohwert zurück', () {
    expect(recipeUnitLabel('g'), 'Gramm');
    expect(recipeUnitLabel('tl'), 'Teelöffel');
    expect(recipeUnitLabel('unbekannt'), 'unbekannt');
  });

  group('parseAmount', () {
    test('akzeptiert ganze Zahlen und Dezimalzahlen mit Punkt', () {
      expect(parseAmount('250'), 250.0);
      expect(parseAmount('0.5'), 0.5);
    });

    test('akzeptiert Komma als Dezimaltrenner', () {
      expect(parseAmount('0,5'), 0.5);
    });

    test('lehnt leere, ungültige und nicht-positive Werte ab', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('0'), isNull);
      expect(parseAmount('-3'), isNull);
    });
  });
}
