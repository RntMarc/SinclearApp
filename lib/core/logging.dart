import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    final msg = record.message;
    final error = record.error;
    final stack = record.stackTrace;
    if (error != null) {
      debugPrint(
        '[${record.loggerName}] ${record.level.name}: $msg\n$error',
      );
      if (stack != null) debugPrint('$stack');
    } else {
      debugPrint('[${record.loggerName}] ${record.level.name}: $msg');
    }
  });
}
