import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:sinclear_beyond/core/logging.dart';

void main() {
  test('FlutterError.onError routes framework errors to the logger', () {
    final records = <LogRecord>[];
    Logger.root.level = Level.ALL;
    final sub = Logger.root.onRecord.listen(records.add);

    setupGlobalErrorHandling();
    FlutterError.reportError(
      FlutterErrorDetails(exception: StateError('boom'), library: 'test'),
    );

    sub.cancel();
    expect(records, isNotEmpty);
    final record = records.last;
    expect(record.level, Level.SEVERE);
    expect(record.loggerName, 'flutter');
    expect(record.message, contains('boom'));
  });

  test('reportUncaughtError logs uncaught zone errors as severe', () async {
    final records = <LogRecord>[];
    Logger.root.level = Level.ALL;
    final sub = Logger.root.onRecord.listen(records.add);

    runZonedGuarded(
      () async => throw StateError('zone boom'),
      reportUncaughtError,
    );
    await Future<void>.delayed(Duration.zero);

    sub.cancel();
    expect(records, isNotEmpty);
    final record = records.last;
    expect(record.level, Level.SEVERE);
    expect(record.loggerName, 'main');
    expect(record.error, isA<StateError>());
  });
}
