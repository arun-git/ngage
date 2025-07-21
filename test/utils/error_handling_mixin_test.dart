import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ngage/utils/error_handling_mixin.dart';
import 'package:ngage/utils/error_types.dart';

// Test widget that uses the error handling mixin
class TestWidget extends StatefulWidget {
  final VoidCallback? onError;
  
  const TestWidget({super.key, this.onError});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> with WidgetErrorHandlingMixin {
  String? lastError;

  void triggerError() {
    try {
      throw const ValidationException('Test error', field: 'test');
    } catch (error, stackTrace) {
      handleErrorWithUI(
        error,
        stackTrace,
        context: 'test context',
        onRetry: widget.onError,
      );
    }
  }

  void triggerAsyncError() async {
    await handleAsyncOperation<String>(
      () async => throw Exception('Async error'),
      context: 'async test',
      fallbackValue: 'fallback',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: triggerError,
            child: const Text('Trigger Error'),
          ),
          ElevatedButton(
            onPressed: triggerAsyncError,
            child: const Text('Trigger Async Error'),
          ),
        ],
      ),
    );
  }
}

// Test service that uses the error handling mixin
class TestService with ErrorHandlingMixin {
  Future<String> performAsyncOperation() async {
    return await handleAsyncOperation<String>(
      () async => throw Exception('Service error'),
      context: 'service operation',
      fallbackValue: 'service fallback',
    ) ?? 'default';
  }

  String performSyncOperation() {
    return handleSyncOperation<String>(
      () => throw Exception('Sync error'),
      context: 'sync operation',
      fallbackValue: 'sync fallback',
    ) ?? 'default';
  }
}

void main() {
  group('ErrorHandlingMixin', () {
    late TestService testService;

    setUp(() {
      testService = TestService();
    });

    group('Async Operations', () {
      test('should handle successful async operations', () async {
        final result = await testService.handleAsyncOperation<String>(
          () async => 'success',
          context: 'test operation',
        );

        expect(result, equals('success'));
      });

      test('should handle failed async operations with fallback', () async {
        final result = await testService.handleAsyncOperation<String>(
          () async => throw Exception('test error'),
          context: 'test operation',
          fallbackValue: 'fallback',
          showUserMessage: false,
        );

        expect(result, equals('fallback'));
      });

      test('should return null when no fallback is provided', () async {
        final result = await testService.handleAsyncOperation<String>(
          () async => throw Exception('test error'),
          context: 'test operation',
          showUserMessage: false,
        );

        expect(result, isNull);
      });
    });

    group('Sync Operations', () {
      test('should handle successful sync operations', () {
        final result = testService.handleSyncOperation<String>(
          () => 'success',
          context: 'test operation',
        );

        expect(result, equals('success'));
      });

      test('should handle failed sync operations with fallback', () {
        final result = testService.handleSyncOperation<String>(
          () => throw Exception('test error'),
          context: 'test operation',
          fallbackValue: 'fallback',
          showUserMessage: false,
        );

        expect(result, equals('fallback'));
      });

      test('should return null when no fallback is provided', () {
        final result = testService.handleSyncOperation<String>(
          () => throw Exception('test error'),
          context: 'test operation',
          showUserMessage: false,
        );

        expect(result, isNull);
      });
    });

    group('Service Integration', () {
      test('should handle async service operations', () async {
        final result = await testService.performAsyncOperation();
        expect(result, equals('service fallback'));
      });

      test('should handle sync service operations', () {
        final result = testService.performSyncOperation();
        expect(result, equals('sync fallback'));
      });
    });
  });

  group('WidgetErrorHandlingMixin', () {
    testWidgets('should handle widget errors', (WidgetTester tester) async {
      bool errorCallbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            onError: () => errorCallbackCalled = true,
          ),
        ),
      );

      // Trigger error
      await tester.tap(find.text('Trigger Error'));
      await tester.pump();

      // Verify widget is still rendered (error was handled)
      expect(find.byType(TestWidget), findsOneWidget);
    });

    testWidgets('should handle async widget errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidget(),
        ),
      );

      // Trigger async error
      await tester.tap(find.text('Trigger Async Error'));
      await tester.pump();

      // Verify widget is still rendered (error was handled)
      expect(find.byType(TestWidget), findsOneWidget);
    });
  });

  group('ErrorHandlingUtils', () {
    group('Validation', () {
      test('should validate required fields', () {
        expect(
          () => ErrorHandlingUtils.validateRequired(null, 'test'),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateRequired('', 'test'),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateRequired('  ', 'test'),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateRequired('value', 'test'),
          returnsNormally,
        );
      });

      test('should validate email format', () {
        expect(
          () => ErrorHandlingUtils.validateEmail(null),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateEmail(''),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateEmail('invalid-email'),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateEmail('test@example.com'),
          returnsNormally,
        );
      });

      test('should validate phone number format', () {
        // Phone is optional, so null/empty should not throw
        expect(
          () => ErrorHandlingUtils.validatePhone(null),
          returnsNormally,
        );

        expect(
          () => ErrorHandlingUtils.validatePhone(''),
          returnsNormally,
        );

        expect(
          () => ErrorHandlingUtils.validatePhone('invalid-phone'),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validatePhone('+1234567890'),
          returnsNormally,
        );

        expect(
          () => ErrorHandlingUtils.validatePhone('(555) 123-4567'),
          returnsNormally,
        );
      });

      test('should validate string length', () {
        expect(
          () => ErrorHandlingUtils.validateLength('ab', 'test', minLength: 3),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateLength('abcdef', 'test', maxLength: 5),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => ErrorHandlingUtils.validateLength('abc', 'test', minLength: 3, maxLength: 5),
          returnsNormally,
        );

        expect(
          () => ErrorHandlingUtils.validateLength(null, 'test', minLength: 3),
          returnsNormally,
        );
      });
    });

    group('Safe Callbacks', () {
      test('should create safe callback that handles errors', () {
        bool callbackExecuted = false;
        bool errorHandled = false;

        final safeCallback = ErrorHandlingUtils.safeCallback(
          () {
            callbackExecuted = true;
            throw Exception('test error');
          },
          context: 'test callback',
          onError: () => errorHandled = true,
        );

        safeCallback();

        expect(callbackExecuted, isTrue);
        expect(errorHandled, isTrue);
      });

      test('should create safe async callback that handles errors', () async {
        bool callbackExecuted = false;
        bool errorHandled = false;

        final safeCallback = ErrorHandlingUtils.safeAsyncCallback(
          () async {
            callbackExecuted = true;
            throw Exception('test error');
          },
          context: 'test async callback',
          onError: () => errorHandled = true,
        );

        await safeCallback();

        expect(callbackExecuted, isTrue);
        expect(errorHandled, isTrue);
      });
    });

    group('Wrapper Functions', () {
      test('should wrap async operations', () async {
        final result = await ErrorHandlingUtils.wrapAsync<String>(
          () async => throw Exception('test error'),
          context: 'test wrap',
          fallbackValue: 'wrapped fallback',
          showUserMessage: false,
        );

        expect(result, equals('wrapped fallback'));
      });

      test('should wrap sync operations', () {
        final result = ErrorHandlingUtils.wrapSync<String>(
          () => throw Exception('test error'),
          context: 'test wrap',
          fallbackValue: 'wrapped fallback',
          showUserMessage: false,
        );

        expect(result, equals('wrapped fallback'));
      });
    });
  });

  group('ConsumerWidgetErrorHandlingMixin', () {
    // Test consumer widget with error handling
    class TestConsumerWidget extends ConsumerWidget with ConsumerWidgetErrorHandlingMixin {
      const TestConsumerWidget({super.key});

      @override
      Widget build(BuildContext context, WidgetRef ref) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              await handleAsyncWithUI<String>(
                context,
                () async => throw Exception('Consumer error'),
                operationContext: 'consumer test',
                fallbackValue: 'consumer fallback',
                showSnackBar: false, // Disable for testing
              );
            },
            child: const Text('Trigger Consumer Error'),
          ),
        );
      }
    }

    testWidgets('should handle consumer widget errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestConsumerWidget(),
          ),
        ),
      );

      // Trigger error
      await tester.tap(find.text('Trigger Consumer Error'));
      await tester.pump();

      // Verify widget is still rendered (error was handled)
      expect(find.byType(TestConsumerWidget), findsOneWidget);
    });
  });
}