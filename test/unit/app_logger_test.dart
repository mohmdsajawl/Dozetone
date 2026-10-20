import 'package:dozetone/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger tests', () {
    test('AppLogger methods execute without throwing', () {
      expect(
        () => AppLogger.d(
          'Debug message',
          tag: 'TestTag',
          error: Exception('debug err'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );

      expect(
        () => AppLogger.i(
          'Info message',
          tag: 'TestTag',
        ),
        returnsNormally,
      );

      expect(
        () => AppLogger.w(
          'Warning message',
          tag: 'TestTag',
          error: 'Warning string',
        ),
        returnsNormally,
      );

      expect(
        () => AppLogger.e(
          'Error message',
          tag: 'TestTag',
          error: Exception('critical failure'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });
}
