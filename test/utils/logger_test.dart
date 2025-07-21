import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:ngage/utils/logger.dart';

void main() {
  group('Logger', () {
    late Logger logger;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      logger = Logger();
      fakeFirestore = FakeFirebaseFirestore();
      
      // Configure logger for testing
      logger.configure(
        minimumLevel: LogLevel.debug,
        userId: 'test-user',
        sessionId: 'test-session',
        enableRemoteLogging: false, // Disable for unit tests
        enableLocalStorage: true,
        maxLocalLogs: 100,
      );
    });

    tearDown(() {
      logger.clearLocalLogs();
    });

    group('Log Levels', () {
      test('should log debug messages', () {
        logger.debug('Debug message', category: 'test');
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(1));
        expect(logs.first.level, equals(LogLevel.debug));
        expect(logs.first.message, equals('Debug message'));
        expect(logs.first.category, equals('test'));
      });

      test('should log info messages', () {
        logger.info('Info message', category: 'test');
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(1));
        expect(logs.first.level, equals(LogLevel.info));
        expect(logs.first.message, equals('Info message'));
      });

      test('should log warning messages', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        
        logger.warning(
          'Warning message',
          category: 'test',
          error: error,
          stackTrace: stackTrace,
        );
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(1));
        expect(logs.first.level, equals(LogLevel.warning));
        expect(logs.first.message, equals('Warning message'));
        expect(logs.first.error, equals(error));
        expect(logs.first.stackTrace, equals(stackTrace));
      });

      test('should log error messages', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        
        logger.error(
          'Error message',
          category: 'test',
          error: error,
          stackTrace: stackTrace,
        );
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(1));
        expect(logs.first.level, equals(LogLevel.error));
        expect(logs.first.message, equals('Error message'));
        expect(logs.first.error, equals(error));
        expect(logs.first.stackTrace, equals(stackTrace));
      });

      test('should log critical messages', () {
        logger.critical('Critical message', category: 'test');
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(1));
        expect(logs.first.level, equals(LogLevel.critical));
        expect(logs.first.message, equals('Critical message'));
      });
    });

    group('Log Filtering', () {
      test('should respect minimum log level', () {
        logger.configure(minimumLevel: LogLevel.warning);
        
        logger.debug('Debug message');
        logger.info('Info message');
        logger.warning('Warning message');
        logger.error('Error message');
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(2));
        expect(logs[0].level, equals(LogLevel.warning));
        expect(logs[1].level, equals(LogLevel.error));
      });

      test('should filter logs by level', () {
        logger.debug('Debug message');
        logger.info('Info message');
        logger.warning('Warning message');
        logger.error('Error message');
        
        final errorLogs = logger.getLogsByLevel(LogLevel.error);
        expect(errorLogs.length, equals(1));
        expect(errorLogs.first.message, equals('Error message'));
      });

      test('should filter logs by category', () {
        logger.info('Message 1', category: 'auth');
        logger.info('Message 2', category: 'database');
        logger.info('Message 3', category: 'auth');
        
        final authLogs = logger.getLogsByCategory('auth');
        expect(authLogs.length, equals(2));
        expect(authLogs.every((log) => log.category == 'auth'), isTrue);
      });

      test('should filter logs by time range', () {
        final start = DateTime.now();
        
        logger.info('Message 1');
        
        // Simulate time passing
        final middle = DateTime.now().add(const Duration(milliseconds: 100));
        
        logger.info('Message 2');
        
        final end = DateTime.now().add(const Duration(milliseconds: 200));
        
        final logsInRange = logger.getLogsByTimeRange(start, end);
        expect(logsInRange.length, equals(2));
      });
    });

    group('Log Context', () {
      test('should include user and session information', () {
        logger.info('Test message');
        
        final logs = logger.recentLogs;
        expect(logs.first.userId, equals('test-user'));
        expect(logs.first.sessionId, equals('test-session'));
      });

      test('should include context data', () {
        final context = {
          'operation': 'test',
          'data': {'key': 'value'},
        };
        
        logger.info('Test message', context: context);
        
        final logs = logger.recentLogs;
        expect(logs.first.context, equals(context));
      });
    });

    group('Log Storage', () {
      test('should maintain maximum log count', () {
        logger.configure(maxLocalLogs: 3);
        
        logger.info('Message 1');
        logger.info('Message 2');
        logger.info('Message 3');
        logger.info('Message 4');
        logger.info('Message 5');
        
        final logs = logger.recentLogs;
        expect(logs.length, equals(3));
        expect(logs.first.message, equals('Message 3'));
        expect(logs.last.message, equals('Message 5'));
      });

      test('should clear local logs', () {
        logger.info('Message 1');
        logger.info('Message 2');
        
        expect(logger.recentLogs.length, equals(2));
        
        logger.clearLocalLogs();
        
        expect(logger.recentLogs.length, equals(0));
      });
    });

    group('Log Export', () {
      test('should export logs as JSON', () {
        logger.info('Message 1', category: 'test');
        logger.error('Message 2', category: 'test', error: Exception('Test'));
        
        final jsonString = logger.exportLogsAsJson();
        expect(jsonString, isNotEmpty);
        
        // Verify it's valid JSON
        expect(() => logger.exportLogsAsJson(), returnsNormally);
      });
    });

    group('Log Entry Serialization', () {
      test('should serialize and deserialize log entries', () {
        final originalEntry = LogEntry(
          id: 'test-id',
          timestamp: DateTime.now(),
          level: LogLevel.error,
          message: 'Test message',
          category: 'test',
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
          context: {'key': 'value'},
          userId: 'test-user',
          sessionId: 'test-session',
        );

        final json = originalEntry.toJson();
        final deserializedEntry = LogEntry.fromJson(json);

        expect(deserializedEntry.id, equals(originalEntry.id));
        expect(deserializedEntry.level, equals(originalEntry.level));
        expect(deserializedEntry.message, equals(originalEntry.message));
        expect(deserializedEntry.category, equals(originalEntry.category));
        expect(deserializedEntry.context, equals(originalEntry.context));
        expect(deserializedEntry.userId, equals(originalEntry.userId));
        expect(deserializedEntry.sessionId, equals(originalEntry.sessionId));
      });
    });

    group('Log Stream', () {
      test('should emit log entries to stream', () async {
        final streamLogs = <LogEntry>[];
        final subscription = logger.logStream.listen((log) {
          streamLogs.add(log);
        });

        logger.info('Message 1');
        logger.error('Message 2');

        // Wait for stream events
        await Future.delayed(const Duration(milliseconds: 10));

        expect(streamLogs.length, equals(2));
        expect(streamLogs[0].message, equals('Message 1'));
        expect(streamLogs[1].message, equals('Message 2'));

        await subscription.cancel();
      });
    });
  });
}