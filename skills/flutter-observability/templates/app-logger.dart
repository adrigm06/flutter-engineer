// App logger template — structured logging with Crashlytics integration
// Replace with your crash reporting tool (Sentry also shown as alternative)

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_logger.g.dart';

// ===========================================================================
// GLOBAL INIT (call in bootstrap before runApp)
// ===========================================================================

Future<void> initLogging({required bool isDebug}) async {
  Logger.root.level = isDebug ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen(_handleLogRecord);

  // Flutter framework errors → Crashlytics
  FlutterError.onError = (details) {
    // Log to console in debug
    FlutterError.presentError(details);
    // Send to Crashlytics in production
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Async errors outside Flutter framework → Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  // Disable Crashlytics in debug to avoid noise
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
}

void _handleLogRecord(LogRecord record) {
  // ── Debug console output
  if (kDebugMode) {
    final emoji = switch (record.level) {
      Level.SEVERE => '🔴',
      Level.WARNING => '🟡',
      Level.INFO => '🔵',
      Level.FINE => '⚪',
      _ => '⚫',
    };
    debugPrint(
      '$emoji [${record.loggerName}] ${record.message}'
      '${record.error != null ? '\n  Error: ${record.error}' : ''}'
      '${record.stackTrace != null ? '\n  Stack: ${record.stackTrace}' : ''}',
    );
    return;
  }

  // ── Production: send to Crashlytics breadcrumbs
  if (record.level >= Level.WARNING) {
    // ❌ NEVER include: record.error message if it may contain PII
    // ✅ Safe: level, logger name, sanitized message
    FirebaseCrashlytics.instance.log(
      '[${record.level.name}] ${record.loggerName}: ${_sanitize(record.message)}',
    );
  }

  // Send errors to Crashlytics as non-fatal
  if (record.level >= Level.SEVERE && record.error != null) {
    FirebaseCrashlytics.instance.recordError(
      record.error,
      record.stackTrace,
      fatal: false,
      reason: '${record.loggerName}: ${_sanitize(record.message)}',
    );
  }
}

// ❌ Strip potential PII from log messages before sending remotely
String _sanitize(String message) {
  return message
      .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[email]')
      .replaceAll(RegExp(r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'), '[card]')
      .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [redacted]');
}

// ===========================================================================
// FEATURE LOGGERS (per module)
// ===========================================================================

// Usage: create a logger per class/module
// final _log = Logger('AuthRepository');
// _log.info('Login attempt');
// _log.warning('Refresh token expired');
// _log.severe('Authentication failed', error, stackTrace);

// ===========================================================================
// RIVERPOD PROVIDER
// ===========================================================================

@riverpod
Logger featureLogger(Ref ref, String name) {
  // Returns a named logger for the given feature/class name
  return Logger(name);
}

// ===========================================================================
// USER CONTEXT (non-PII only)
// ===========================================================================

Future<void> setUserContext({required String anonymizedUserId}) async {
  // ✅ Use anonymized/hashed ID — NEVER email, name, or raw user ID if it's PII
  await FirebaseCrashlytics.instance.setUserIdentifier(anonymizedUserId);
}

Future<void> setAppContext({
  required String flavor,
  required String version,
}) async {
  await Future.wait([
    FirebaseCrashlytics.instance.setCustomKey('flavor', flavor),
    FirebaseCrashlytics.instance.setCustomKey('app_version', version),
  ]);
}

Future<void> clearUserContext() async {
  await FirebaseCrashlytics.instance.setUserIdentifier('');
}
