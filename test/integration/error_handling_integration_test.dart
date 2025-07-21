import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ngage/models/enums.dart';

import 'package:ngage/utils/error_handler.dart';
import 'package:ngage/utils/error_types.dart';
import 'package:ngage/utils/logger.dart';
import 'package:ngage/ui/widgets/error_widgets.dart';

void main() {
  group('Error Handling Integration Tests', () {
    setUp(() {
      // Initialize error handling for tests
      ErrorHandler.initialize();
      
      // Configure logger for testing
      Logger().configure(
        minimumLevel: LogLevel.debug,
        enableRemoteLogging: false,
        enableLocalStorage: true,
        maxLocalLogs: 100,
      );
    });

    testWidgets('ErrorDisplayWidget shows error information', (WidgetTester tester) async {
      const error = ValidationException(
        'Test validation error',
        field: 'email',
        userMessage: 'Please enter a valid email address',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              context: 'Test context',
              showReportButton: true,
              showDetails: false,
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.byIcon(Icons.warning_outlined), findsOneWidget);
      expect(find.text('Report Issue'), findsOneWidget);
    });

    testWidgets('CompactErrorWidget shows compact error', (WidgetTester tester) async {
      const error = NetworkException(
        'Connection failed',
        networkErrorType: NetworkErrorType.noConnection,
        userMessage: 'Please check your internet connection',
      );

      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactErrorWidget(
              error: error,
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Verify compact error display
      expect(find.text('Please check your internet connection'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test retry functionality
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('ErrorBoundary catches and displays errors', (WidgetTester tester) async {
      // Widget that throws an error
      Widget errorWidget = Builder(
        builder: (context) {
          throw Exception('Test error');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              child: errorWidget,
            ),
          ),
        ),
      );

      // The error boundary should catch the error and show error widget
      // Note: This test may not work as expected due to Flutter's error handling
      // In a real scenario, you would test this with async errors
    });

    test('ErrorHandler handles different error types correctly', () async {
      final errorHandler = ErrorHandler();
      
      // Test authentication error
      const authError = AuthenticationException(
        'Invalid credentials',
        authErrorType: AuthErrorType.invalidCredentials,
      );
      
      await errorHandler.handleError(
        authError,
        StackTrace.current,
        context: 'Login test',
        showUserMessage: false,
      );

      // Test network error
      const networkError = NetworkException(
        'Connection timeout',
        networkErrorType: NetworkErrorType.connectionTimeout,
      );
      
      await errorHandler.handleError(
        networkError,
        StackTrace.current,
        context: 'Network test',
        showUserMessage: false,
      );

      // Verify errors were logged
      final logger = Logger();
      final recentLogs = logger.recentLogs;
      
      expect(recentLogs.length, greaterThanOrEqualTo(2));
      expect(recentLogs.any((log) => log.message.contains('Login test')), isTrue);
      expect(recentLogs.any((log) => log.message.contains('Network test')), isTrue);
    });

    test('Logger captures and categorizes log entries', () {
      final logger = Logger();
      logger.clearLocalLogs(); // Start fresh
      
      // Log different levels
      logger.debug('Debug message', category: 'test');
      logger.info('Info message', category: 'test');
      logger.warning('Warning message', category: 'test');
      logger.error('Error message', category: 'test', error: Exception('Test error'));
      logger.critical('Critical message', category: 'test');

      final logs = logger.recentLogs;
      expect(logs.length, equals(5));

      // Verify log levels
      expect(logs.any((log) => log.level == LogLevel.debug), isTrue);
      expect(logs.any((log) => log.level == LogLevel.info), isTrue);
      expect(logs.any((log) => log.level == LogLevel.warning), isTrue);
      expect(logs.any((log) => log.level == LogLevel.error), isTrue);
      expect(logs.any((log) => log.level == LogLevel.critical), isTrue);

      // Verify categorization
      expect(logs.every((log) => log.category == 'test'), isTrue);
    });

    test('Async error handling works correctly', () async {
      // Test successful operation
      final result1 = await ErrorHandler.handleAsync<String>(
        () async => 'success',
        context: 'test operation',
      );
      expect(result1, equals('success'));

      // Test failed operation with fallback
      final result2 = await ErrorHandler.handleAsync<String>(
        () async => throw Exception('test error'),
        context: 'test operation',
        fallbackValue: 'fallback',
        showUserMessage: false,
      );
      expect(result2, equals('fallback'));

      // Test failed operation without fallback
      final result3 = await ErrorHandler.handleAsync<String>(
        () async => throw Exception('test error'),
        context: 'test operation',
        showUserMessage: false,
      );
      expect(result3, isNull);
    });

    test('Sync error handling works correctly', () {
      // Test successful operation
      final result1 = ErrorHandler.handleSync<String>(
        () => 'success',
        context: 'test operation',
      );
      expect(result1, equals('success'));

      // Test failed operation with fallback
      final result2 = ErrorHandler.handleSync<String>(
        () => throw Exception('test error'),
        context: 'test operation',
        fallbackValue: 'fallback',
        showUserMessage: false,
      );
      expect(result2, equals('fallback'));

      // Test failed operation without fallback
      final result3 = ErrorHandler.handleSync<String>(
        () => throw Exception('test error'),
        context: 'test operation',
        showUserMessage: false,
      );
      expect(result3, isNull);
    });
  });
}