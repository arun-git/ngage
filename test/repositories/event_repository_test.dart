import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/event_repository.dart';

void main() {
  group('EventRepository', () {
    late EventRepository eventRepository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      eventRepository = EventRepository(firestore: fakeFirestore);
    });

    group('createEvent', () {
      test('should create event successfully', () async {
        // Arrange
        final event = _createTestEvent();

        // Act
        await eventRepository.createEvent(event);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(event.id).get();
        expect(doc.exists, isTrue);
        
        final data = doc.data()!;
        expect(data['title'], equals(event.title));
        expect(data['description'], equals(event.description));
        expect(data['eventType'], equals(event.eventType.value));
        expect(data['status'], equals(event.status.value));
        expect(data['groupId'], equals(event.groupId));
        expect(data['createdBy'], equals(event.createdBy));
      });

      test('should handle creation error gracefully', () async {
        // Arrange
        final event = _createTestEvent();
        
        // Create a repository with a null firestore to simulate error
        final errorRepository = EventRepository(firestore: null);

        // Act & Assert
        expect(
          () => errorRepository.createEvent(event),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getEventById', () {
      test('should return event when it exists', () async {
        // Arrange
        final event = _createTestEvent();
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Act
        final result = await eventRepository.getEventById(event.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(event.id));
        expect(result.title, equals(event.title));
        expect(result.description, equals(event.description));
        expect(result.eventType, equals(event.eventType));
        expect(result.status, equals(event.status));
      });

      test('should return null when event does not exist', () async {
        // Arrange
        const nonExistentId = 'non_existent_event';

        // Act
        final result = await eventRepository.getEventById(nonExistentId);

        // Assert
        expect(result, isNull);
      });
    });

    group('updateEvent', () {
      test('should update event successfully', () async {
        // Arrange
        final originalEvent = _createTestEvent();
        await fakeFirestore.collection('events').doc(originalEvent.id).set(originalEvent.toJson());

        final updatedEvent = originalEvent.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
          status: EventStatus.scheduled,
        );

        // Act
        await eventRepository.updateEvent(updatedEvent);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(originalEvent.id).get();
        final data = doc.data()!;
        
        expect(data['title'], equals('Updated Title'));
        expect(data['description'], equals('Updated Description'));
        expect(data['status'], equals(EventStatus.scheduled.value));
        expect(data.containsKey('updatedAt'), isTrue);
      });
    });

    group('deleteEvent', () {
      test('should delete event successfully', () async {
        // Arrange
        final event = _createTestEvent();
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Verify event exists
        var doc = await fakeFirestore.collection('events').doc(event.id).get();
        expect(doc.exists, isTrue);

        // Act
        await eventRepository.deleteEvent(event.id);

        // Assert
        doc = await fakeFirestore.collection('events').doc(event.id).get();
        expect(doc.exists, isFalse);
      });
    });

    group('getGroupEvents', () {
      test('should return events for specific group ordered by creation date', () async {
        // Arrange
        const groupId = 'group_123';
        const otherGroupId = 'group_456';
        
        final event1 = _createTestEvent(
          id: 'event_1',
          groupId: groupId,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
        final event2 = _createTestEvent(
          id: 'event_2',
          groupId: groupId,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final event3 = _createTestEvent(
          id: 'event_3',
          groupId: otherGroupId,
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('events').doc(event1.id).set(event1.toJson());
        await fakeFirestore.collection('events').doc(event2.id).set(event2.toJson());
        await fakeFirestore.collection('events').doc(event3.id).set(event3.toJson());

        // Act
        final result = await eventRepository.getGroupEvents(groupId);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].id, equals(event2.id)); // Most recent first
        expect(result[1].id, equals(event1.id));
        
        // Verify no events from other group
        expect(result.any((e) => e.id == event3.id), isFalse);
      });

      test('should return empty list when no events exist for group', () async {
        // Arrange
        const groupId = 'empty_group';

        // Act
        final result = await eventRepository.getGroupEvents(groupId);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getEventsByStatus', () {
      test('should return events with specific status', () async {
        // Arrange
        const groupId = 'group_123';
        
        final draftEvent = _createTestEvent(
          id: 'draft_event',
          groupId: groupId,
          status: EventStatus.draft,
        );
        final activeEvent = _createTestEvent(
          id: 'active_event',
          groupId: groupId,
          status: EventStatus.active,
        );
        final completedEvent = _createTestEvent(
          id: 'completed_event',
          groupId: groupId,
          status: EventStatus.completed,
        );

        await fakeFirestore.collection('events').doc(draftEvent.id).set(draftEvent.toJson());
        await fakeFirestore.collection('events').doc(activeEvent.id).set(activeEvent.toJson());
        await fakeFirestore.collection('events').doc(completedEvent.id).set(completedEvent.toJson());

        // Act
        final result = await eventRepository.getEventsByStatus(groupId, EventStatus.active);

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals(activeEvent.id));
        expect(result[0].status, equals(EventStatus.active));
      });
    });

    group('getTeamEligibleEvents', () {
      test('should return events that team is eligible for', () async {
        // Arrange
        const groupId = 'group_123';
        const teamId = 'team_123';
        
        final openEvent = _createTestEvent(
          id: 'open_event',
          groupId: groupId,
          eligibleTeamIds: null, // Open to all
        );
        final restrictedEligibleEvent = _createTestEvent(
          id: 'restricted_eligible_event',
          groupId: groupId,
          eligibleTeamIds: [teamId, 'team_456'],
        );
        final restrictedIneligibleEvent = _createTestEvent(
          id: 'restricted_ineligible_event',
          groupId: groupId,
          eligibleTeamIds: ['team_456', 'team_789'],
        );

        await fakeFirestore.collection('events').doc(openEvent.id).set(openEvent.toJson());
        await fakeFirestore.collection('events').doc(restrictedEligibleEvent.id).set(restrictedEligibleEvent.toJson());
        await fakeFirestore.collection('events').doc(restrictedIneligibleEvent.id).set(restrictedIneligibleEvent.toJson());

        // Act
        final result = await eventRepository.getTeamEligibleEvents(groupId, teamId);

        // Assert
        expect(result.length, equals(2));
        expect(result.any((e) => e.id == openEvent.id), isTrue);
        expect(result.any((e) => e.id == restrictedEligibleEvent.id), isTrue);
        expect(result.any((e) => e.id == restrictedIneligibleEvent.id), isFalse);
      });
    });

    group('getEventsWithUpcomingDeadlines', () {
      test('should return events with deadlines within specified days', () async {
        // Arrange
        const groupId = 'group_123';
        final now = DateTime.now();
        
        final upcomingEvent = _createTestEvent(
          id: 'upcoming_event',
          groupId: groupId,
          status: EventStatus.active,
          submissionDeadline: now.add(const Duration(days: 3)),
        );
        final farFutureEvent = _createTestEvent(
          id: 'far_future_event',
          groupId: groupId,
          status: EventStatus.active,
          submissionDeadline: now.add(const Duration(days: 10)),
        );
        final pastEvent = _createTestEvent(
          id: 'past_event',
          groupId: groupId,
          status: EventStatus.active,
          submissionDeadline: now.subtract(const Duration(days: 1)),
        );

        await fakeFirestore.collection('events').doc(upcomingEvent.id).set(upcomingEvent.toJson());
        await fakeFirestore.collection('events').doc(farFutureEvent.id).set(farFutureEvent.toJson());
        await fakeFirestore.collection('events').doc(pastEvent.id).set(pastEvent.toJson());

        // Act
        final result = await eventRepository.getEventsWithUpcomingDeadlines(groupId, daysAhead: 7);

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals(upcomingEvent.id));
      });
    });

    group('updateEventStatus', () {
      test('should update event status successfully', () async {
        // Arrange
        final event = _createTestEvent(status: EventStatus.draft);
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Act
        await eventRepository.updateEventStatus(event.id, EventStatus.scheduled);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(event.id).get();
        final data = doc.data()!;
        
        expect(data['status'], equals(EventStatus.scheduled.value));
        expect(data.containsKey('updatedAt'), isTrue);
      });
    });

    group('updateEventSchedule', () {
      test('should update event schedule successfully', () async {
        // Arrange
        final event = _createTestEvent();
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        final newStartTime = DateTime.now().add(const Duration(hours: 1));
        final newEndTime = DateTime.now().add(const Duration(hours: 3));
        final newDeadline = DateTime.now().add(const Duration(hours: 2));

        // Act
        await eventRepository.updateEventSchedule(
          event.id,
          startTime: newStartTime,
          endTime: newEndTime,
          submissionDeadline: newDeadline,
        );

        // Assert
        final doc = await fakeFirestore.collection('events').doc(event.id).get();
        final data = doc.data()!;
        
        expect(data['startTime'], equals(newStartTime.toIso8601String()));
        expect(data['endTime'], equals(newEndTime.toIso8601String()));
        expect(data['submissionDeadline'], equals(newDeadline.toIso8601String()));
        expect(data.containsKey('updatedAt'), isTrue);
      });
    });

    group('eventExists', () {
      test('should return true when event exists', () async {
        // Arrange
        final event = _createTestEvent();
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Act
        final result = await eventRepository.eventExists(event.id);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when event does not exist', () async {
        // Arrange
        const nonExistentId = 'non_existent_event';

        // Act
        final result = await eventRepository.eventExists(nonExistentId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('searchEventsByTitle', () {
      test('should return events matching search term', () async {
        // Arrange
        const groupId = 'group_123';
        
        final matchingEvent1 = _createTestEvent(
          id: 'matching_1',
          groupId: groupId,
          title: 'Flutter Competition',
          description: 'A great competition',
        );
        final matchingEvent2 = _createTestEvent(
          id: 'matching_2',
          groupId: groupId,
          title: 'Dart Challenge',
          description: 'Learn Flutter basics',
        );
        final nonMatchingEvent = _createTestEvent(
          id: 'non_matching',
          groupId: groupId,
          title: 'Java Workshop',
          description: 'Learn Java programming',
        );

        await fakeFirestore.collection('events').doc(matchingEvent1.id).set(matchingEvent1.toJson());
        await fakeFirestore.collection('events').doc(matchingEvent2.id).set(matchingEvent2.toJson());
        await fakeFirestore.collection('events').doc(nonMatchingEvent.id).set(nonMatchingEvent.toJson());

        // Act
        final result = await eventRepository.searchEventsByTitle(groupId, 'flutter');

        // Assert
        expect(result.length, equals(2));
        expect(result.any((e) => e.id == matchingEvent1.id), isTrue);
        expect(result.any((e) => e.id == matchingEvent2.id), isTrue);
        expect(result.any((e) => e.id == nonMatchingEvent.id), isFalse);
      });

      test('should return empty list when no events match', () async {
        // Arrange
        const groupId = 'group_123';
        
        final event = _createTestEvent(
          groupId: groupId,
          title: 'Java Workshop',
          description: 'Learn Java programming',
        );

        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Act
        final result = await eventRepository.searchEventsByTitle(groupId, 'python');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('streamGroupEvents', () {
      test('should stream events for group', () async {
        // Arrange
        const groupId = 'group_123';
        final event = _createTestEvent(groupId: groupId);

        // Act
        final stream = eventRepository.streamGroupEvents(groupId);
        
        // Add event to firestore
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<Event>>((events) => 
            events.length == 1 && events[0].id == event.id
          )),
        );
      });
    });

    group('streamEvent', () {
      test('should stream single event', () async {
        // Arrange
        final event = _createTestEvent();

        // Act
        final stream = eventRepository.streamEvent(event.id);
        
        // Add event to firestore
        await fakeFirestore.collection('events').doc(event.id).set(event.toJson());

        // Assert
        await expectLater(
          stream,
          emits(predicate<Event?>((e) => e?.id == event.id)),
        );
      });

      test('should stream null for non-existent event', () async {
        // Arrange
        const nonExistentId = 'non_existent_event';

        // Act
        final stream = eventRepository.streamEvent(nonExistentId);

        // Assert
        await expectLater(stream, emits(isNull));
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
  List<String>? eligibleTeamIds,
  String? createdBy,
  DateTime? createdAt,
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
    eligibleTeamIds: eligibleTeamIds,
    createdBy: createdBy ?? 'member_123',
    createdAt: createdAt ?? now,
    updatedAt: now,
  );
}