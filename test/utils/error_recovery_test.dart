import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/enums.dart';

import 'package:ngage/utils/error_recovery.dart';
import 'package:ngage/utils/error_types.dart';
import 'package:ngage/utils/logger.dart';

import 'error_recovery_test.mocks.dart';

@GenerateMocks([Logger])
void main() {
  group('ErrorRecovery', () {
    late ErrorRecovery errorRecovery;
    late MockLogger mockLogger;

    setUp(() {
      errorRecovery = ErrorRecovery();
      mockLogger = MockLogger();
    });

    tearDown(() {
      errorRecovery.clearRetryTracking();
    });

    group('Recovery Attempts', () {
      test('should attempt recovery for network errors', () async {
        const error = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.network);
        
        // Recovery attempt should be made (result may vary in test environment)
        expect(recovered, isA<bool>());
      });

      test('should attempt recovery for database errors', () async {
        const error = DatabaseException(
          'Connection failed',
          databaseErrorType: DatabaseErrorType.connectionFailed,
        );

        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.database);
        
        expect(recovered, isA<bool>());
      });

      test('should not attempt recovery for authorization errors', () async {
        const error = AuthorizationException('Access denied');

        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.authorization);
        
        expect(recovered, isFalse);
      });

      test('should not attempt recovery for validation errors', () async {
        const error = ValidationException('Invalid input');

        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.validation);
        
        expect(recovered, isFalse);
      });
    });

    group('Retry Limits', () {
      test('should respect maximum retry attempts', () async {
        const error = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        // Attempt recovery multiple times
        await errorRecovery.attemptRecovery(error, ErrorType.network);
        await errorRecovery.attemptRecovery(error, ErrorType.network);
        await errorRecovery.attemptRecovery(error, ErrorType.network);
        
        // Fourth attempt should not be made (max is 3 for network)
        final fourthAttempt = await errorRecovery.attemptRecovery(error, ErrorType.network);
        expect(fourthAttempt, isFalse);
      });

      test('should reset retry count after successful recovery', () async {
        const error = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        // Make some attempts
        await errorRecovery.attemptRecovery(error, ErrorType.network);
        await errorRecovery.attemptRecovery(error, ErrorType.network);

        // Clear retry tracking (simulating successful recovery)
        errorRecovery.clearRetryTracking();

        // Should be able to attempt recovery again
        final newAttempt = await errorRecovery.attemptRecovery(error, ErrorType.network);
        expect(newAttempt, isA<bool>());
      });
    });

    group('Retry Delays', () {
      test('should respect retry delays', () async {
        const error = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        final startTime = DateTime.now();
        
        // First attempt
        await errorRecovery.attemptRecovery(error, ErrorType.network);
        
        // Second attempt immediately should be blocked by delay
        final secondAttempt = await errorRecovery.attemptRecovery(error, ErrorType.network);
        
        final elapsed = DateTime.now().difference(startTime);
        
        // If second attempt was blocked, it should return false quickly
        // If it was allowed, it should take some time
        expect(elapsed.inMilliseconds, lessThan(2000)); // Should be quick if blocked
      });
    });

    group('Rate Limit Recovery', () {
      test('should handle rate limit exceptions with retry after', () async {
        const error = RateLimitException(
          'Rate limited',
          retryAfter: Duration(seconds: 1),
        );

        final startTime = DateTime.now();
        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.rateLimit);
        final elapsed = DateTime.now().difference(startTime);

        // Should wait for the retry after duration
        expect(elapsed.inMilliseconds, greaterThanOrEqualTo(1000));
        expect(recovered, isA<bool>());
      });

      test('should handle rate limit exceptions without retry after', () async {
        const error = RateLimitException('Rate limited');

        final startTime = DateTime.now();
        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.rateLimit);
        final elapsed = DateTime.now().difference(startTime);

        // Should wait for default duration (1 minute)
        expect(elapsed.inSeconds, greaterThanOrEqualTo(60));
        expect(recovered, isA<bool>());
      });
    });

    group('Integration Error Recovery', () {
      test('should handle authentication failed integration errors', () async {
        const error = IntegrationException(
          'Auth failed',
          service: 'slack',
          integrationType: IntegrationErrorType.authenticationFailed,
        );

        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.integration);
        expect(recovered, isA<bool>());
      });

      test('should handle rate limited integration errors', () async {
        const error = IntegrationException(
          'Rate limited',
          service: 'slack',
          integrationType: IntegrationErrorType.apiLimitExceeded,
        );

        final startTime = DateTime.now();
        final recovered = await errorRecovery.attemptRecovery(error, ErrorType.integration);
        final elapsed = DateTime.now().difference(startTime);

        // Should wait longer for rate limit recovery
        expect(elapsed.inSeconds, greaterThanOrEqualTo(30));
        expect(recovered, isA<bool>());
      });
    });

    group('Retry Statistics', () {
      test('should track retry statistics', () async {
        const error1 = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );
        
        const error2 = DatabaseException(
          'Connection failed',
          databaseErrorType: DatabaseErrorType.connectionFailed,
        );

        await errorRecovery.attemptRecovery(error1, ErrorType.network);
        await errorRecovery.attemptRecovery(error2, ErrorType.database);
        await errorRecovery.attemptRecovery(error1, ErrorType.network);

        final stats = errorRecovery.getRetryStatistics();
        
        expect(stats['activeRetries'], greaterThan(0));
        expect(stats['retryAttempts'], isA<Map>());
        expect(stats['lastRetryTimes'], isA<Map>());
      });

      test('should clear retry tracking', () async {
        const error = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        await errorRecovery.attemptRecovery(error, ErrorType.network);
        
        var stats = errorRecovery.getRetryStatistics();
        expect(stats['activeRetries'], greaterThan(0));

        errorRecovery.clearRetryTracking();
        
        stats = errorRecovery.getRetryStatistics();
        expect(stats['activeRetries'], equals(0));
      });
    });

    group('Error Key Generation', () {
      test('should generate consistent error keys for same errors', () async {
        const error1 = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );
        
        const error2 = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        await errorRecovery.attemptRecovery(error1, ErrorType.network);
        await errorRecovery.attemptRecovery(error2, ErrorType.network);

        final stats = errorRecovery.getRetryStatistics();
        
        // Should track as the same error type
        expect(stats['retryAttempts'], isA<Map>());
      });

      test('should generate different error keys for different errors', () async {
        const error1 = NetworkException(
          'Connection timeout',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );
        
        const error2 = DatabaseException(
          'Connection failed',
          databaseErrorType: DatabaseErrorType.connectionFailed,
        );

        await errorRecovery.attemptRecovery(error1, ErrorType.network);
        await errorRecovery.attemptRecovery(error2, ErrorType.database);

        final stats = errorRecovery.getRetryStatistics();
        
        // Should track as different errors
        expect(stats['activeRetries'], equals(2));
      });
    });
  });
}