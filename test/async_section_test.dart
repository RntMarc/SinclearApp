import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/widgets/async_section.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/primitives/design_card.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: DesignScope(
      variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Minimal memoizing controller mirroring how screens wire retry: the retry
/// callback invalidates the future and notifies, so the section gets a new
/// future instance.
class _MemoController extends ChangeNotifier {
  int _attempts = 0;
  Future<String>? _future;

  Future<String> get future => _future ??= _load();

  Future<String> _load() async {
    _attempts++;
    if (_attempts == 1) throw Exception('kaputt');
    return 'ok';
  }

  void refresh() {
    _future = null;
    notifyListeners();
  }
}

class _Harness extends StatelessWidget {
  final _MemoController controller;

  const _Harness(this.controller);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AsyncSection<String>(
        future: controller.future,
        onRetry: () async => controller.refresh(),
        builder: (context, data) => Text(data),
      ),
    );
  }
}

void main() {
  testWidgets('zeigt erst nach der Verzögerung ein Skeleton, dann Inhalt', (
    tester,
  ) async {
    final completer = Completer<String>();
    await tester.pumpWidget(
      wrap(
        AsyncSection<String>(
          future: completer.future,
          builder: (context, data) => Text(data),
        ),
      ),
    );

    // Solange die Verzögerung nicht abgelaufen ist, ist nichts sichtbar.
    expect(find.byType(DesignCard), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DesignCard), findsOneWidget);

    completer.complete('geladen');
    await tester.pumpAndSettle();

    expect(find.byType(DesignCard), findsNothing);
    expect(find.text('geladen'), findsOneWidget);
  });

  testWidgets('schnelle Futures zeigen nie ein Skeleton', (tester) async {
    final completer = Completer<String>();
    await tester.pumpWidget(
      wrap(
        AsyncSection<String>(
          future: completer.future,
          builder: (context, data) => Text(data),
        ),
      ),
    );

    completer.complete('sofort');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('sofort'), findsOneWidget);

    // Auch nach Ablauf der Verzögerung bleibt das Skeleton aus.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DesignCard), findsNothing);
    expect(find.text('sofort'), findsOneWidget);
  });

  testWidgets('zeigt Fehlerkarte bei Fehler und lädt nach Retry neu', (
    tester,
  ) async {
    final controller = _MemoController();
    await tester.pumpWidget(wrap(_Harness(controller)));
    await tester.pumpAndSettle();

    expect(
      find.text('Dieser Abschnitt konnte nicht geladen werden.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(find.text('ok'), findsOneWidget);
  });

  testWidgets('ignoriert veraltete Antworten einer vorherigen Future', (
    tester,
  ) async {
    final stale = Completer<String>();
    final fresh = Completer<String>();

    await tester.pumpWidget(
      wrap(
        AsyncSection<String>(
          future: stale.future,
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pumpWidget(
      wrap(
        AsyncSection<String>(
          future: fresh.future,
          builder: (context, data) => Text(data),
        ),
      ),
    );

    fresh.complete('neu');
    await tester.pumpAndSettle();
    expect(find.text('neu'), findsOneWidget);

    stale.complete('alt');
    await tester.pumpAndSettle();
    expect(find.text('neu'), findsOneWidget);
    expect(find.text('alt'), findsNothing);
  });
}
