import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging utility for Dozetone.
///
/// Routes logs through [developer.log] with standard log levels, preserving
/// structured tags, error objects, and stack traces for easy filtering in DevTools.
class AppLogger {
  const AppLogger._();

  /// Logs a debug-level message.
  static void d(
    String message, {
    String tag = 'Dozetone',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag,
        level: 500,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs an info-level message.
  static void i(
    String message, {
    String tag = 'Dozetone',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a warning-level message.
  static void w(
    String message, {
    String tag = 'Dozetone',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs an error-level message with optional exception and stack trace.
  static void e(
    String message, {
    String tag = 'Dozetone',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
