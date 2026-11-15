import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// Structured application logger avoiding bare prints.
class LoggerService {
  LoggerService._();

  static void debug(String message, {String tag = 'MINDVERSE'}) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, {String tag = 'MINDVERSE'}) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, {String tag = 'MINDVERSE'}) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(
    String message, {
    String tag = 'MINDVERSE',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '[ERROR] $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void _log(LogLevel level, String message, String tag) {
    developer.log(
      '[${level.name.toUpperCase()}] $message',
      name: tag,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }
}
