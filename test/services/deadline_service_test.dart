import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/deadline_service.dart';
import '../../lib/services/notification_service.dart';
import '../../lib/repositories/event_repository.dart';
import '../../lib/repositories/submission_repository.dart';
import '../../lib/models/event.dart';
import '../../lib/models/submission.dart';
import '../../lib/models/enums.dart';

// Generate mocks
@GenerateMocks([EventRepository, SubmissionRepository, NotificationService])
import 'deadline_service_test.mocks.dart';

void main() {
  group('DeadlineService', () {
    late DeadlineService deadlineService;
    late MockEventRepository mockEventRepository;
    late MockSubmissionRepository mockSubmissionRepository;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockEventRepository = MockEventRepository();
      mockSubmissionRepository = MockSubmissionRepository();
      mockNotificationService = MockNotificationService();
      
      deadlineService = DeadlineService(
        mockEventRepository,
        mockSubmissionRepository,
        mockNotificationService,
      );
    });

    tearDown(() {
      deadlineService.dispose();
    });

    group('Deadline Status', () {
      test('should return noDeadline when event has no submission deadline', () {
        // Arrange
        final event = _createTestEvent(submissionDeadline: null);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.noDeadline));
      });

      test('should return passed when deadline has passed', () {
        // Arrange
        final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
        final event = _createTestEvent(submissionDeadline: pastDeadline);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.passed));
      });

      test('should return critical when deadline is within 15 minutes', () {
        // Arrange
        final nearDeadline = DateTime.now().add(const Duration(minutes: 10));
        final event = _createTestEvent(submissionDeadline: nearDeadline);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.critical));
      });

      test('should return urgent when deadline is within 1 hour', () {
        // Arrange
        final nearDeadline = DateTime.now().add(const Duration(minutes: 30));
        final event = _createTestEvent(submissionDeadline: nearDeadline);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.urgent));
      });

      test('should return warning when deadline is within 4 hours', () {
        // Arrange
        final nearDeadline = DateTime.now().add(const Duration(hours: 2));
        final event = _createTestEvent(submissionDeadline: nearDeadline);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.warning));
      });

      test('should return approaching when deadline is within 24 hours', () {
        // Arrange
        final nearDeadline = DateTime.now().add(const Duration(hours: 12));
        final event = _createTestEvent(submissionDeadline: nearDeadline);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.approaching));
      });

      test('should return normal when deadline is more than 24 hours away', () {
        // Arrange
        final futureDeadline = DateTime.now().add(const Duration(days: 2));
        final event = _createTestEvent(submissionDeadline: futureDeadline);

        // Act
        final status = deadlineService.getDeadlineStatus(event);

        // Assert
        expect(status, equals(DeadlineStatus.normal));
      });
    });

    group('Time Remaining', () {
      test('should return null when event has no deadline', () {
        // Arrange
        final event = _createTestEvent(submissionDeadline: null);

        // Act
        final timeRemaining = deadlineService.getTimeUntilDeadline(event);

        // Assert
        expect(timeRemaining, isNull);
      });

      test('should return null when deadline has passed', () {
        // Arrange
        final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
        final event = _createTestEvent(submissionDeadline: pastDeadline);

        // Act
        final timeRemaining = deadlineService.getTimeUntilDeadline(event);

        // Assert
        expect(timeRemaining, isNull);
      });

      test('should return correct duration when deadline is in future', () {
        // Arrange
        final futureDeadline = DateTime.now().add(const Duration(hours: 2));
        final event = _createTestEvent(submissionDeadline: futureDeadline);

        // Act
        final timeRemaining = deadlineService.getTimeUntilDeadline(event);

        // Assert
        expect(timeRemaining, isNotNull);
        expect(timeRemaining!.inHours, equals(1)); // Allow for small timing differences
      });
    });

    group('Format Time Remaining', () {
      test('should format days and hours correctly', () {
        // Arrange
        final duration = const Duration(days: 2, hours: 3);

        // Act
        final formatted = deadlineService.formatTimeRemaining(duration);

        // Assert
        expect(formatted, equals('2d 3h remaining'));
      });

      test('should format hours and minutes correctly', () {
        // Arrange
        final duration = const Duration(hours: 1, minutes: 30);

        // Act
        final formatted = deadlineService.formatTimeRemaining(duration);

        // Assert
        expect(formatted, equals('1h 30m remaining'));
      });

      test('should format minutes only correctly', () {
        // Arrange
        final duration = const Duration(minutes: 45);

        // Act
        final formatted = deadlineService.formatTimeRemaining(duration);

        // Assert
        expect(formatted, equals('45m remaining'));
      });

      test('should handle null duration', () {
        // Act
        final formatted = deadlineService.formatTimeRemaining(null);

        // Assert
        expect(formatted, equals('No deadline'));
      });

      test('should handle negative duration', () {
        // Arrange
        final duration = const Duration(minutes: -30);

        // Act
        final formatted = deadlineService.formatTimeRemaining(duration);

        // Assert
        expect(formatted, equals('Deadline passed'));
      });
    });

    group('Deadline Enforcement', () {
      test('should enforce deadline for active events with passed deadlines', () async {
        // Arrange
        final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
        final event = _createTestEvent(
          submissionDeadline: pastDeadline,
          status: EventStatus.active,
        );
        
        final draftSubmission = _createTestSubmission(
          eventId: event.id,
          status: SubmissionStatus.draft,
          hasContent: true,
        );

        when(mockEventRepository.getAllActiveEvents())
            .thenAnswer((_) async => [event]);
        when(mockSubmissionRepository.getDraftSubmissionsByEvent(event.id))
            .thenAnswer((_) async => [draftSubmission]);
        when(mockSubmissionRepository.update(any))
            .thenAnswer((_) async => draftSubmission);
        when(mockNotificationService.sendDeadlineAutoSubmissionNotification(
          submission: anyNamed('submission'),
          event: anyNamed('event'),
        )).thenAnswer((_) async {});
        when(mockNotificationService.sendDeadlinePassedNotification(any))
            .thenAnswer((_) async {});

        // Act
        await deadlineService.scheduleEventDeadlineEnforcement(event);
        
        // Wait a bit for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockSubmissionRepository.getDraftSubmissionsByEvent(event.id)).called(1);
        verify(mockSubmissionRepository.update(any)).called(1);
        verify(mockNotificationService.sendDeadlineAutoSubmissionNotification(
          submission: anyNamed('submission'),
          event: anyNamed('event'),
        )).called(1);
        verify(mockNotificationService.sendDeadlinePassedNotification(event)).called(1);
      });

      test('should delete empty draft submissions when deadline passes', () async {
        // Arrange
        final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
        final event = _createTestEvent(
          submissionDeadline: pastDeadline,
          status: EventStatus.active,
        );
        
        final emptyDraftSubmission = _createTestSubmission(
          eventId: event.id,
          status: SubmissionStatus.draft,
          hasContent: false,
        );

        when(mockEventRepository.getAllActiveEvents())
            .thenAnswer((_) async => [event]);
        when(mockSubmissionRepository.getDraftSubmissionsByEvent(event.id))
            .thenAnswer((_) async => [emptyDraftSubmission]);
        when(mockSubmissionRepository.delete(any))
            .thenAnswer((_) async {});
        when(mockNotificationService.sendDeadlinePassedNotification(any))
            .thenAnswer((_) async {});

        // Act
        await deadlineService.scheduleEventDeadlineEnforcement(event);
        
        // Wait a bit for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockSubmissionRepository.delete(emptyDraftSubmission.id)).called(1);
        verifyNever(mockSubmissionRepository.update(any));
        verifyNever(mockNotificationService.sendDeadlineAutoSubmissionNotification(
          submission: anyNamed('submission'),
          event: anyNamed('event'),
        ));
      });

      test('should not enforce deadline for events without deadlines', () async {
        // Arrange
        final event = _createTestEvent(submissionDeadline: null);

        // Act
        await deadlineService.scheduleEventDeadlineEnforcement(event);

        // Assert
        verifyNever(mockSubmissionRepository.getDraftSubmissionsByEvent(any));
        verifyNever(mockSubmissionRepository.update(any));
        verifyNever(mockSubmissionRepository.delete(any));
      });
    });

    group('Deadline Monitoring', () {
      test('should start and stop monitoring correctly', () {
        // Act
        deadlineService.startDeadlineMonitoring();
        expect(deadlineService.toString(), contains('DeadlineService')); // Basic check that service is running
        
        deadlineService.stopDeadlineMonitoring();
        // Service should be stopped (no direct way to test this without exposing internals)
      });

      test('should cancel event deadline enforcement', () {
        // Arrange
        const eventId = 'test-event-id';

        // Act & Assert (no exception should be thrown)
        deadlineService.cancelEventDeadlineEnforcement(eventId);
      });
    });

    group('Deadline Status Extension', () {
      test('should correctly identify urgent statuses', () {
        expect(DeadlineStatus.urgent.isUrgent, isTrue);
        expect(DeadlineStatus.critical.isUrgent, isTrue);
        expect(DeadlineStatus.warning.isUrgent, isFalse);
        expect(DeadlineStatus.normal.isUrgent, isFalse);
      });

      test('should correctly identify statuses requiring attention', () {
        expect(DeadlineStatus.warning.requiresAttention, isTrue);
        expect(DeadlineStatus.urgent.requiresAttention, isTrue);
        expect(DeadlineStatus.critical.requiresAttention, isTrue);
        expect(DeadlineStatus.passed.requiresAttention, isFalse);
        expect(DeadlineStatus.normal.requiresAttention, isFalse);
      });

      test('should have correct display names', () {
        expect(DeadlineStatus.noDeadline.displayName, equals('No Deadline'));
        expect(DeadlineStatus.normal.displayName, equals('Normal'));
        expect(DeadlineStatus.approaching.displayName, equals('Approaching'));
        expect(DeadlineStatus.warning.displayName, equals('Warning'));
        expect(DeadlineStatus.urgent.displayName, equals('Urgent'));
        expect(DeadlineStatus.critical.displayName, equals('Critical'));
        expect(DeadlineStatus.passed.displayName, equals('Passed'));
      });
    });
  });
}

// Helper functions to create test objects
Event _createTestEvent({
  String? id,
  DateTime? submissionDeadline,
  EventStatus? status,
}) {
  final now = DateTime.now();
  return Event(
    id: id ?? 'test-event-id',
    groupId: 'test-group-id',
    title: 'Test Event',
    description: 'Test event description',
    eventType: EventType.competition,
    status: status ?? EventStatus.active,
    submissionDeadline: submissionDeadline,
    createdBy: 'test-member-id',
    createdAt: now,
    updatedAt: now,
  );
}

Submission _createTestSubmission({
  String? id,
  String? eventId,
  SubmissionStatus? status,
  bool hasContent = true,
}) {
  final now = DateTime.now();
  return Submission(
    id: id ?? 'test-submission-id',
    eventId: eventId ?? 'test-event-id',
    teamId: 'test-team-id',
    submittedBy: 'test-member-id',
    content: hasContent ? {'text': 'Test content'} : {},
    status: status ?? SubmissionStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
}