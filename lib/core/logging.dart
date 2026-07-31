import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    final msg = record.message;
    final error = record.error;
    final stack = record.stackTrace;
    if (error != null) {
      debugPrint('[${record.loggerName}] ${record.level.name}: $msg\n$error');
      if (stack != null) debugPrint('$stack');
    } else {
      debugPrint('[${record.loggerName}] ${record.level.name}: $msg');
    }
  });
}

/// Routes uncaught framework errors through the `logging` package.
///
/// Keeps the default console dump ([FlutterError.presentError]) and adds a
/// structured `Logger('flutter')` record so errors are visible in DevTools.
void setupGlobalErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Logger('flutter').severe(
      'Flutter error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };
}

/// Logs errors that escape the app zone (e.g. from timers or event
/// handlers) as severe `Logger('main')` records.
void reportUncaughtError(Object error, StackTrace stackTrace) {
  Logger('main').severe('Uncaught error', error, stackTrace);
}
