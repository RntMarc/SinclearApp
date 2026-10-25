import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/utils/url_helper.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/foundation/design_text.dart';

Widget wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

String reassemble(List<UrlSegment> segments) =>
    segments.map((segment) => segment.text).join();

List<String> urlsOf(String text) => [
  for (final segment in splitUrlSegments(text)) ?segment.url,
];

void main() {
  group('splitUrlSegments', () {
    test('erkennt eine URL im laufenden Text', () {
      const text = 'Schau https://example.com/a?b=1 mal an';
      expect(urlsOf(text), ['https://example.com/a?b=1']);
      expect(reassemble(splitUrlSegments(text)), text);
    });

    test('Satzzeichen am Ende bleiben Klartext', () {
      const text = 'Siehe https://example.com.';
      expect(urlsOf(text), ['https://example.com']);
      expect(reassemble(splitUrlSegments(text)), text);
    });

    test('balancierte Klammern bleiben Teil der URL', () {
      const url = 'https://de.wikipedia.org/wiki/Alpha_(Begriff)';
      expect(urlsOf('$url im Wiki'), [url]);
    });

    test('unbalancierte Klammer wird abgeschnitten', () {
      const text = 'Text (https://example.com/foo)';
      expect(urlsOf(text), ['https://example.com/foo']);
      expect(reassemble(splitUrlSegments(text)), text);
    });

    test('erkennt mehrere URLs', () {
      const text = 'https://a.de eins https://b.de/zwei';
      expect(urlsOf(text), ['https://a.de', 'https://b.de/zwei']);
      expect(reassemble(splitUrlSegments(text)), text);
    });

    test('www. und nackte Domains bleiben Klartext', () {
      const text = 'www.example.com und example.com und HTTP://';
      expect(urlsOf(text), isEmpty);
      expect(splitUrlSegments(text).single.url, isNull);
      expect(firstUrlIn(text), isNull);
    });

    test('leerer Text liefert keine Segmente', () {
      expect(splitUrlSegments(''), isEmpty);
    });

    test('firstUrlIn liefert die erste URL', () {
      expect(firstUrlIn('zwei https://a.de und https://b.de'), 'https://a.de');
    });
  });

  group('DesignText', () {
    testWidgets('rendert URLs im Fließtext als antippbare Links', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const DesignText('Mehr: https://example.com')),
      );
      final root = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      final link = root.children!.whereType<TextSpan>().singleWhere(
        (span) => span.recognizer != null,
      );
      expect(link.text, 'https://example.com');
      expect(link.recognizer, isA<TapGestureRecognizer>());
    });

    testWidgets('lässt Text ohne URL unverändert', (tester) async {
      await tester.pumpWidget(wrap(const DesignText('Nur Text')));
      expect(tester.widget<Text>(find.byType(Text)).data, 'Nur Text');
    });

    testWidgets('ignoriert URLs in Titeln und abgeschaltetem Fließtext', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              DesignText('https://example.com', style: DesignTextStyle.title),
              DesignText('https://example.com', linkify: false),
            ],
          ),
        ),
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts.every((text) => text.data == 'https://example.com'), isTrue);
    });
  });
}
