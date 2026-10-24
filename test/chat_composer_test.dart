import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_chat_composer.dart';

Widget wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

String fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

/// Minimaler Parent, der den Vertrag von [DesignChatComposer] nachbildet:
/// Edit-Modus über `editInitialText`, Erfolg beendet den Modus.
class Harness extends StatefulWidget {
  final Future<bool> Function(String) onSend;

  const Harness({required this.onSend, super.key});

  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  String? editing;

  void startEdit(String text) => setState(() => editing = text);

  void stopEdit() => setState(() => editing = null);

  Future<bool> _handleSend(String text) async {
    final sent = await widget.onSend(text);
    if (sent && mounted) stopEdit();
    return sent;
  }

  @override
  Widget build(BuildContext context) => DesignChatComposer(
    editInitialText: editing,
    onSend: _handleSend,
    onCancelEdit: stopEdit,
  );
}

void main() {
  testWidgets('nach dem Speichern einer Bearbeitung ist das Feld leer', (
    tester,
  ) async {
    final key = GlobalKey<HarnessState>();
    await tester.pumpWidget(wrap(Harness(key: key, onSend: (_) async => true)));

    key.currentState!.startEdit('Bearbeitet');
    await tester.pump();
    expect(fieldText(tester), 'Bearbeitet');

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(fieldText(tester), '');
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('Abbrechen stellt den vorherigen Entwurf wieder her', (
    tester,
  ) async {
    final key = GlobalKey<HarnessState>();
    await tester.pumpWidget(wrap(Harness(key: key, onSend: (_) async => true)));

    await tester.enterText(find.byType(TextField), 'Entwurf');
    key.currentState!.startEdit('Bearbeitet');
    await tester.pump();
    expect(fieldText(tester), 'Bearbeitet');

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'Entwurf');
  });

  testWidgets('Wechsel des Bearbeitungsziels füllt den neuen Text ein', (
    tester,
  ) async {
    final key = GlobalKey<HarnessState>();
    await tester.pumpWidget(wrap(Harness(key: key, onSend: (_) async => true)));

    key.currentState!.startEdit('Nachricht A');
    await tester.pump();
    key.currentState!.startEdit('Nachricht B');
    await tester.pump();

    expect(fieldText(tester), 'Nachricht B');
  });

  testWidgets('fehlgeschlagenes Speichern lässt Text und Modus stehen', (
    tester,
  ) async {
    final key = GlobalKey<HarnessState>();
    await tester.pumpWidget(
      wrap(Harness(key: key, onSend: (_) async => false)),
    );

    key.currentState!.startEdit('Bearbeitet');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'Bearbeitet');
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('während des Sendens ist ein zweiter Versand gesperrt', (
    tester,
  ) async {
    final completer = Completer<bool>();
    var calls = 0;
    final key = GlobalKey<HarnessState>();
    await tester.pumpWidget(
      wrap(
        Harness(
          key: key,
          onSend: (_) {
            calls++;
            return completer.future;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hallo');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.tap(find.byIcon(Icons.send_rounded));
    expect(calls, 1);

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    completer.complete(true);
    await tester.pumpAndSettle();
    expect(fieldText(tester), '');
  });
}
