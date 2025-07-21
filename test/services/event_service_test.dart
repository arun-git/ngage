import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/models/models.dart';
import '../../lib/services/event_service.dart';
import '../../lib/repositories/event_repository.dart';

import 'event_service_test.mocks.dart';

@GenerateMocks([EventRepository])
void main() {
  group('EventService', () {
    late EventService eventService;
    late MockEventRepository mockRepository;

    setUp(() {
      mockRepository = MockEventRepository();
      eventService = EventService(eventRepository: mockRepository);
    });

    group('createEvent', () {
      test('should create event successfully with valid data', () async {
        // Arrange
        const groupId = 'group_123';
        const title = 'Test Event';
        const description = 'Test Description';
        const eventType = EventType.competition;
        const createdBy = 'member_123';

        when(mockRepository.createEvent(any)).thenAnswer((_) async {});

        // Act
        final result = await eventService.createEvent(
          groupId: groupId,
          title: title,
          description: description,
          eventType: eventType,
          createdBy: createdBy,
        );

        // Assert
        expect(result.groupId, equals(groupId));
        expect(result.title, equals(title));
        expect(result.description, equals(description));
        expect(result.eventType, equals(eventType));
        expect(result.createdBy, equals(createdBy));
        expect(result.status, equals(EventStatus.draft));
        verify(mockRepository.createEvent(any)).called(1);
      });

      test('should throw ValidationException for empty title', () async {
        // Arrange
        const groupId = 'group_123';
        const title = '';
        const description = 'Test Description';
        const eventType = EventType.competition;
        const createdBy = 'member_123';

        // Act & Assert
        expect(
          () => eventService.createEvent(
            groupId: groupId,
            title: title,
            description: description,
            eventType: eventType,
            createdBy: createdBy,
          ),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(mockRepository.createEvent(any));
      });

      test('should throw ValidationException for empty description', () async {
        // Arrange
        const groupId = 'group_123';
        const title = 'Test Event';
        const description = '';
        const eventType = EventType.competition;
        const createdBy = 'member_123';

        // Act & Assert
        expect(
          () => eventService.createEvent(
            groupId: groupId,
            title: title,
            description: description,
            eventType: eventType,
            createdBy: createdBy,
          ),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(mockRepository.createEvent(any));
      });

      test('should create event with scheduling information', () async {
        // Arrange
        const groupId = 'group_123';
        const title = 'Test Event';
        const description = 'Test Description';
        const eventType = EventType.competition;
        const createdBy = 'member_123';
        final startTime = DateTime.now().add(const Duration(hours: 1));
        final endTime = startTime.add(const Duration(hours: 2));
        final submissionDeadline = endTime.subtract(const Duration(minutes: 30));

        when(mockRepository.createEvent(any)).thenAnswer((_) async {});

        // Act
        final result = await eventService.createEvent(
          groupId: groupId,
          title: title,
          description: description,
          eventType: eventType,
          createdBy: createdBy,
          startTime: startTime,
          endTime: endTime,
          submissionDeadline: submissionDeadline,
        );

        // Assert
        expect(result.startTime, equals(startTime));
        expect(result.endTime, equals(endTime));
        expect(result.submissionDeadline, equals(submissionDeadline));
        verify(mockRepository.createEvent(any)).called(1);
      });
    });

    group('scheduleEvent', () {
      test('should schedule draft event successfully', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);
        final startTime = DateTime.now().add(const Duration(hours: 1));
        final endTime = startTime.add(const Duration(hours: 2));

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);
        when(mockRepository.updateEvent(any)).thenAnswer((_) async {});

        // Act
        final result = await eventService.scheduleEvent(
          event.id,
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result.status, equals(EventStatus.scheduled));
        expect(result.startTime, equals(startTime));
        expect(result.endTime, equals(endTime));
        verify(mockRepository.updateEvent(any)).called(1);
      });

      test('should throw EventNotFoundException for non-existent event', () async {
        // Arrange
        const eventId = 'non_existent';
        final startTime = DateTime.now().add(const Duration(hours: 1));
        final endTime = startTime.add(const Duration(hours: 2));

        when(mockRepository.getEventById(eventId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.scheduleEvent(
            eventId,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<EventNotFoundException>()),
        );
        verifyNever(mockRepository.updateEvent(any));
      });

      test('should throw EventOperationException for non-draft event', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.active);
        final startTime = DateTime.now().add(const Duration(hours: 1));
        final endTime = startTime.add(const Duration(hours: 2));

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.scheduleEvent(
            event.id,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<EventOperationException>()),
        );
        verifyNever(mockRepository.updateEvent(any));
      });

      test('should throw EventValidationException for invalid times', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);
        final startTime = DateTime.now().add(const Duration(hours: 2));
        final endTime = DateTime.now().add(const Duration(hours: 1)); // End before start

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.scheduleEvent(
            event.id,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<EventValidationException>()),
        );
        verifyNever(mockRepository.updateEvent(any));
      });

      test('should throw EventValidationException for events shorter than 1 hour', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);
        final startTime = DateTime.now().add(const Duration(hours: 1));
        final endTime = startTime.add(const Duration(minutes: 30)); // Only 30 minutes

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.scheduleEvent(
            event.id,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<EventValidationException>()),
        );
        verifyNever(mockRepository.updateEvent(any));
      });

      test('should throw EventValidationException for past events', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);
        final startTime = DateTime.now().subtract(const Duration(hours: 1)); // Past time
        final endTime = DateTime.now().add(const Duration(hours: 1));

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.scheduleEvent(
            event.id,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<EventValidationException>()),
        );
        verifyNever(mockRepository.updateEvent(any));
      });
    });

    group('updateEventStatus', () {
      test('should update status from draft to scheduled', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);
        const newStatus = EventStatus.scheduled;

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);
        when(mockRepository.updateEventStatus(event.id, newStatus)).thenAnswer((_) async {});

        // Act
        final result = await eventService.updateEventStatus(event.id, newStatus);

        // Assert
        expect(result.status, equals(newStatus));
        verify(mockRepository.updateEventStatus(event.id, newStatus)).called(1);
      });

      test('should throw EventOperationException for invalid status transition', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.completed);
        const newStatus = EventStatus.active; // Invalid transition

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.updateEventStatus(event.id, newStatus),
          throwsA(isA<EventOperationException>()),
        );
        verifyNever(mockRepository.updateEventStatus(any, any));
      });

      test('should throw EventOperationException when activating event without start time', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.scheduled, startTime: null);
        const newStatus = EventStatus.active;

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.updateEventStatus(event.id, newStatus),
          throwsA(isA<EventOperationException>()),
        );
        verifyNever(mockRepository.updateEventStatus(any, any));
      });
    });

    group('deleteEvent', () {
      test('should delete draft event successfully', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);
        when(mockRepository.deleteEvent(event.id)).thenAnswer((_) async {});

        // Act
        await eventService.deleteEvent(event.id);

        // Assert
        verify(mockRepository.deleteEvent(event.id)).called(1);
      });

      test('should throw EventNotFoundException for non-existent event', () async {
        // Arrange
        const eventId = 'non_existent';

        when(mockRepository.getEventById(eventId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.deleteEvent(eventId),
          throwsA(isA<EventNotFoundException>()),
        );
        verifyNever(mockRepository.deleteEvent(any));
      });

      test('should throw EventOperationException for non-draft event', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.active);

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act & Assert
        expect(
          () => eventService.deleteEvent(event.id),
          throwsA(isA<EventOperationException>()),
        );
        verifyNever(mockRepository.deleteEvent(any));
      });
    });

    group('cloneEvent', () {
      test('should clone event successfully', () async {
        // Arrange
        final originalEvent = _createTestEvent();
        const newTitle = 'Cloned Event';

        when(mockRepository.getEventById(originalEvent.id)).thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any)).thenAnswer((_) async {});

        // Act
        final result = await eventService.cloneEvent(
          originalEvent.id,
          newTitle: newTitle,
        );

        // Assert
        expect(result.title, equals(newTitle));
        expect(result.description, equals(originalEvent.description));
        expect(result.eventType, equals(originalEvent.eventType));
        expect(result.groupId, equals(originalEvent.groupId));
        expect(result.status, equals(EventStatus.draft));
        expect(result.id, isNot(equals(originalEvent.id)));
        verify(mockRepository.createEvent(any)).called(1);
      });

      test('should throw EventNotFoundException for non-existent event', () async {
        // Arrange
        const eventId = 'non_existent';

        when(mockRepository.getEventById(eventId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.cloneEvent(eventId),
          throwsA(isA<EventNotFoundException>()),
        );
        verifyNever(mockRepository.createEvent(any));
      });
    });

    group('getGroupEvents', () {
      test('should return list of events for group', () async {
        // Arrange
        const groupId = 'group_123';
        final events = [
          _createTestEvent(id: 'event_1'),
          _createTestEvent(id: 'event_2'),
        ];

        when(mockRepository.getGroupEvents(groupId)).thenAnswer((_) async => events);

        // Act
        final result = await eventService.getGroupEvents(groupId);

        // Assert
        expect(result, equals(events));
        verify(mockRepository.getGroupEvents(groupId)).called(1);
      });
    });

    group('areSubmissionsOpen', () {
      test('should return true for active event within time window', () async {
        // Arrange
        final now = DateTime.now();
        final event = _createTestEvent(
          status: EventStatus.active,
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 1)),
          submissionDeadline: now.add(const Duration(minutes: 30)),
        );

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act
        final result = await eventService.areSubmissionsOpen(event.id);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for inactive event', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act
        final result = await eventService.areSubmissionsOpen(event.id);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for event past submission deadline', () async {
        // Arrange
        final now = DateTime.now();
        final event = _createTestEvent(
          status: EventStatus.active,
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.add(const Duration(hours: 1)),
          submissionDeadline: now.subtract(const Duration(minutes: 30)), // Past deadline
        );

        when(mockRepository.getEventById(event.id)).thenAnswer((_) async => event);

        // Act
        final result = await eventService.areSubmissionsOpen(event.id);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}

/// Helper function to create test events
Event _createTestEvent({
  String? id,
  String? groupId,
  String? title,
  String? description,
  EventType? eventType,
  EventStatus? status,
  DateTime? startTime,
  DateTime? endTime,
  DateTime? submissionDeadline,
  String? createdBy,
}) {
  final now = DateTime.now();
  return Event(
    id: id ?? 'test_event_123',
    groupId: groupId ?? 'group_123',
    title: title ?? 'Test Event',
    description: description ?? 'Test Description',
    eventType: eventType ?? EventType.competition,
    status: status ?? EventStatus.draft,
    startTime: startTime,
    endTime: endTime,
    submissionDeadline: submissionDeadline,
    createdBy: createdBy ?? 'member_123',
    createdAt: now,
    updatedAt: now,
  );
}