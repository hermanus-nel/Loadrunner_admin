import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log_lib;

import '../utils/app_config.dart';

/// Application logging service
/// Provides structured logging with different levels
class LoggerService {
  LoggerService._();

  static final LoggerService _instance = LoggerService._();
  static LoggerService get instance => _instance;

  late final log_lib.Logger _logger;
  bool _initialized = false;

  /// Initialize the logger
  void initialize() {
    if (_initialized) return;

    _logger = log_lib.Logger(
      printer: log_lib.PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: log_lib.DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: AppConfig.instance.isDebugMode
          ? log_lib.Level.trace
          : log_lib.Level.warning,
      filter: _AppLogFilter(),
    );

    _initialized = true;
  }

  /// Log trace level message (most verbose)
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log debug level message
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info level message
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning level message
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error level message
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal level message (most severe)
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }
}

/// Custom log filter
class _AppLogFilter extends log_lib.LogFilter {
  @override
  bool shouldLog(log_lib.LogEvent event) {
    // In release mode, only log warnings and above
    if (kReleaseMode) {
      return event.level.index >= log_lib.Level.warning.index;
    }

    // In debug mode, log based on config
    if (AppConfig.instance.isDebugMode) {
      return true;
    }

    return event.level.index >= log_lib.Level.info.index;
  }
}

/// Global logger instance for convenience
final logger = LoggerService.instance;

/// Quick logging functions
void logTrace(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
    logger.trace(message, error, stackTrace);

void logDebug(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
    logger.debug(message, error, stackTrace);

void logInfo(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
    logger.info(message, error, stackTrace);

void logWarning(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
    logger.warning(message, error, stackTrace);

void logError(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
    logger.error(message, error, stackTrace);

void logFatal(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
    logger.fatal(message, error, stackTrace);
