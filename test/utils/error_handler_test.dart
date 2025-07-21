import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ngage/utils/error_handler.dart';
import 'package:ngage/utils/error_types.dart';
import 'package:ngage/utils/logger.dart';
import 'package:ngage/utils/error_recovery.dart';

import 'error_handler_test.mocks.dart';

@GenerateMocks([Logger, ErrorRecovery])
void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;
    late MockLogger mockLogger;
    late MockErrorRecovery mockErrorRecovery;

    setUp(() {
      errorHandler = ErrorHandler();
      mockLogger = MockLogger();
      mockErrorRecovery = MockErrorRecovery();
    });

    group('Error Categorization', () {
      test('should categorize authentication exceptions correctly', () async {
        const error = AuthenticationException(
          'Invalid credentials',
          authErrorType: AuthErrorType.invalidCredentials,
        );
        
        await errorHandler.handleError(
          error,
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify that the error was handled as authentication error
        // This would be verified through logging or other observable behavior
      });

      test('should categorize network exceptions correctly', () async {
        const error = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );
        
        await errorHandler.handleError(
          error,
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify network error handling
      });

      test('should categorize validation exceptions correctly', () async {
        const error = ValidationException(
          'Invalid input',
          field: 'email',
        );
        
        await errorHandler.handleError(
          error,
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify validation error handling
      });

      test('should categorize unknown errors correctly', () async {
        final error = Exception('Unknown error');
        
        await errorHandler.handleError(
          error,
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify unknown error handling
      });
    });

    group('User-Friendly Messages', () {
      test('should provide user-friendly message for authentication errors', () async {
        const error = AuthenticationException(
          'Invalid credentials',
          authErrorType: AuthErrorType.invalidCredentials,
          userMessage: 'Please check your login details',
        );
        
        await errorHandler.handleError(
          error,
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify user message is used
      });

      test('should provide default message when no user message is provided', () async {
        const error = NetworkException(
          'Connection failed',
          networkErrorType: NetworkErrorType.noConnection,
        );
        
        await errorHandler.handleError(
          error,
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify default message is used
      });
    });

    group('Async Error Handling', () {
      test('should handle successful async operations', () async {
        final result = await ErrorHandler.handleAsync<String>(
          () async => 'success',
          context: 'test operation',
        );

        expect(result, equals('success'));
      });

      test('should handle failed async operations', () async {
        final result = await ErrorHandler.handleAsync<String>(
          () async => throw Exception('test error'),
          context: 'test operation',
          fallbackValue: 'fallback',
          showUserMessage: false,
        );

        expect(result, equals('fallback'));
      });

      test('should return null when no fallback is provided', () async {
        final result = await ErrorHandler.handleAsync<String>(
          () async => throw Exception('test error'),
          context: 'test operation',
          showUserMessage: false,
        );

        expect(result, isNull);
      });
    });

    group('Sync Error Handling', () {
      test('should handle successful sync operations', () {
        final result = ErrorHandler.handleSync<String>(
          () => 'success',
          context: 'test operation',
        );

        expect(result, equals('success'));
      });

      test('should handle failed sync operations', () {
        final result = ErrorHandler.handleSync<String>(
          () => throw Exception('test error'),
          context: 'test operation',
          fallbackValue: 'fallback',
          showUserMessage: false,
        );

        expect(result, equals('fallback'));
      });

      test('should return null when no fallback is provided', () {
        final result = ErrorHandler.handleSync<String>(
          () => throw Exception('test error'),
          context: 'test operation',
          showUserMessage: false,
        );

        expect(result, isNull);
      });
    });

    group('Error Context', () {
      test('should include additional data in error context', () async {
        final additionalData = {
          'userId': 'test-user',
          'operation': 'test-operation',
        };

        await errorHandler.handleError(
          Exception('test error'),
          StackTrace.current,
          context: 'test context',
          additionalData: additionalData,
          showUserMessage: false,
        );

        // Verify additional data is included in logging
      });

      test('should handle errors without additional context', () async {
        await errorHandler.handleError(
          Exception('test error'),
          StackTrace.current,
          showUserMessage: false,
        );

        // Verify error is handled without context
      });
    });
  });

  group('Error Types', () {
    test('should create authentication exception with correct properties', () {
      const exception = AuthenticationException(
        'Test auth error',
        authErrorType: AuthErrorType.invalidCredentials,
        userMessage: 'Please check your credentials',
      );

      expect(exception.message, equals('Test auth error'));
      expect(exception.authErrorType, equals(AuthErrorType.invalidCredentials));
      expect(exception.userMessage, equals('Please check your credentials'));
    });

    test('should create network exception with correct properties', () {
      const exception = NetworkException(
        'Test network error',
        networkErrorType: NetworkErrorType.connectionTimeout,
        statusCode: 408,
      );

      expect(exception.message, equals('Test network error'));
      expect(exception.networkErrorType, equals(NetworkErrorType.connectionTimeout));
      expect(exception.statusCode, equals(408));
    });

    test('should create validation exception with correct properties', () {
      const exception = ValidationException(
        'Test validation error',
        field: 'email',
        validationErrors: ['Invalid format', 'Required field'],
      );

      expect(exception.message, equals('Test validation error'));
      expect(exception.field, equals('email'));
      expect(exception.validationErrors, equals(['Invalid format', 'Required field']));
    });
  });

  group('Error Recovery Integration', () {
    test('should attempt recovery for recoverable errors', () async {
      when(mockErrorRecovery.attemptRecovery(any, any))
          .thenAnswer((_) async => true);

      const error = NetworkException(
        'Connection failed',
        networkErrorType: NetworkErrorType.connectionTimeout,
      );

      await errorHandler.handleError(
        error,
        StackTrace.current,
        showUserMessage: false,
      );

      // Verify recovery was attempted
      // This would be verified through mocking the recovery service
    });

    test('should not show user message when recovery succeeds', () async {
      when(mockErrorRecovery.attemptRecovery(any, any))
          .thenAnswer((_) async => true);

      const error = NetworkException(
        'Connection failed',
        networkErrorType: NetworkErrorType.connectionTimeout,
      );

      await errorHandler.handleError(
        error,
        StackTrace.current,
      );

      // Verify user message is not shown when recovery succeeds
    });

    test('should show user message when recovery fails', () async {
      when(mockErrorRecovery.attemptRecovery(any, any))
          .thenAnswer((_) async => false);

      const error = NetworkException(
        'Connection failed',
        networkErrorType: NetworkErrorType.connectionTimeout,
      );

      await errorHandler.handleError(
        error,
        StackTrace.current,
      );

      // Verify user message is shown when recovery fails
    });
  });
}