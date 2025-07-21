import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/services/event_service.dart';
import 'package:ngage/repositories/event_repository.dart';

import 'event_prerequisites_test.mocks.dart';

@GenerateMocks([EventRepository])
void main() {
  group('Event Prerequisites Tests', () {
    late EventService eventService;
    late MockEventRepository mockRepository;
    late Event testEvent;
    late Event prerequisiteEvent;

    setUp(() {
      mockRepository = MockEventRepository();
      eventService = EventService(eventRepository: mockRepository);
      
      prerequisiteEvent = Event(
        id: 'prereq_event_1',
        groupId: 'group_1',
        title: 'Prerequisite Event',
        description: 'Must complete this first',
        eventType: EventType.competition,
        status: EventStatus.completed,
        createdBy: 'member_1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      
      testEvent = Event(
        id: 'event_1',
        groupId: 'group_1',
        title: 'Test Event',
        description: 'Test event description',
        eventType: EventType.competition,
        status: EventStatus.active,
        createdBy: 'member_1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    group('Set Event Prerequisites', () {
      test('should set prerequisites for event', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.getEventById('prereq_event_1'))
            .thenAnswer((_) async => prerequisiteEvent);
        when(mockRepository.updateEvent(any))
            .thenAnswer((_) async {});

        // Act
        final updatedEvent = await eventService.setEventPrerequisites(
          'event_1',
          prerequisiteEventIds: ['prereq_event_1'],
        );

        // Assert
        final prerequisites = updatedEvent.getJudgingCriterion<List<dynamic>>('prerequisites');
        expect(prerequisites, ['prereq_event_1']);
        verify(mockRepository.updateEvent(any)).called(1);
      });

      test('should set multiple prerequisites', () async {
        // Arrange
        final prereq2 = prerequisiteEvent.copyWith(id: 'prereq_event_2');
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.getEventById('prereq_event_1'))
            .thenAnswer((_) async => prerequisiteEvent);
        when(mockRepository.getEventById('prereq_event_2'))
            .thenAnswer((_) async => prereq2);
        when(mockRepository.updateEvent(any))
            .thenAnswer((_) async {});

        // Act
        final updatedEvent = await eventService.setEventPrerequisites(
          'event_1',
          prerequisiteEventIds: ['prereq_event_1', 'prereq_event_2'],
        );

        // Assert
        final prerequisites = updatedEvent.getJudgingCriterion<List<dynamic>>('prerequisites');
        expect(prerequisites, ['prereq_event_1', 'prereq_event_2']);
      });

      test('should clear prerequisites when null provided', () async {
        // Arrange
        final eventWithPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithPrereqs);
        when(mockRepository.updateEvent(any))
            .thenAnswer((_) async {});

        // Act
        final updatedEvent = await eventService.setEventPrerequisites(
          'event_1',
          prerequisiteEventIds: null,
        );

        // Assert
        final prerequisites = updatedEvent.getJudgingCriterion<List<dynamic>>('prerequisites');
        expect(prerequisites, isNull);
      });

      test('should add custom prerequisites', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.updateEvent(any))
            .thenAnswer((_) async {});

        // Act
        final updatedEvent = await eventService.setEventPrerequisites(
          'event_1',
          customPrerequisites: {'minScore': 80, 'completionRate': 0.9},
        );

        // Assert
        expect(updatedEvent.getJudgingCriterion<int>('minScore'), 80);
        expect(updatedEvent.getJudgingCriterion<double>('completionRate'), 0.9);
      });

      test('should throw exception when prerequisite event not found', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.getEventById('nonexistent_event'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.setEventPrerequisites(
            'event_1',
            prerequisiteEventIds: ['nonexistent_event'],
          ),
          throwsA(isA<EventValidationException>()),
        );
      });

      test('should throw exception when prerequisite is in different group', () async {
        // Arrange
        final differentGroupPrereq = prerequisiteEvent.copyWith(groupId: 'group_2');
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.getEventById('prereq_event_1'))
            .thenAnswer((_) async => differentGroupPrereq);

        // Act & Assert
        expect(
          () => eventService.setEventPrerequisites(
            'event_1',
            prerequisiteEventIds: ['prereq_event_1'],
          ),
          throwsA(isA<EventValidationException>()),
        );
      });

      test('should throw exception when event not found', () async {
        // Arrange
        when(mockRepository.getEventById('nonexistent_event'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.setEventPrerequisites('nonexistent_event'),
          throwsA(isA<EventNotFoundException>()),
        );
      });
    });

    group('Check Team Prerequisites', () {
      test('should return true when no prerequisites exist', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isTrue);
      });

      test('should return true when all prerequisites are met', () async {
        // Arrange
        final eventWithPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithPrereqs);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => true);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isTrue);
      });

      test('should return false when prerequisites are not met', () async {
        // Arrange
        final eventWithPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithPrereqs);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => false);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isFalse);
      });

      test('should return false when some prerequisites are not met', () async {
        // Arrange
        final eventWithPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': ['prereq_event_1', 'prereq_event_2']},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithPrereqs);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => true);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_2', 'team_1'))
            .thenAnswer((_) async => false);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isFalse);
      });

      test('should return false when event not found', () async {
        // Arrange
        when(mockRepository.getEventById('nonexistent_event'))
            .thenAnswer((_) async => null);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('nonexistent_event', 'team_1');

        // Assert
        expect(meetsPrereqs, isFalse);
      });

      test('should handle non-string prerequisites gracefully', () async {
        // Arrange
        final eventWithInvalidPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': ['prereq_event_1', 123, null]},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithInvalidPrereqs);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => true);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isTrue); // Should only check valid string prerequisites
      });
    });

    group('Integration with Access Control', () {
      test('should consider both access control and prerequisites', () async {
        // Arrange
        final restrictedEventWithPrereqs = Event(
          id: 'event_2',
          groupId: 'group_1',
          title: 'Restricted Event with Prerequisites',
          description: 'Both restricted and has prerequisites',
          eventType: EventType.competition,
          status: EventStatus.active,
          eligibleTeamIds: ['team_1', 'team_2'], // team_1 is eligible
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
          createdBy: 'member_1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(mockRepository.getGroupEvents('group_1'))
            .thenAnswer((_) async => [restrictedEventWithPrereqs]);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => true);

        // Act
        final accessibleEvents = await eventService.getAccessibleEventsForTeam('group_1', 'team_1');

        // Assert
        expect(accessibleEvents.length, 1);
        expect(accessibleEvents.first.id, 'event_2');
      });

      test('should exclude events when team meets prerequisites but not access control', () async {
        // Arrange
        final restrictedEventWithPrereqs = Event(
          id: 'event_2',
          groupId: 'group_1',
          title: 'Restricted Event with Prerequisites',
          description: 'Both restricted and has prerequisites',
          eventType: EventType.competition,
          status: EventStatus.active,
          eligibleTeamIds: ['team_2', 'team_3'], // team_1 is NOT eligible
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
          createdBy: 'member_1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(mockRepository.getGroupEvents('group_1'))
            .thenAnswer((_) async => [restrictedEventWithPrereqs]);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => true);

        // Act
        final accessibleEvents = await eventService.getAccessibleEventsForTeam('group_1', 'team_1');

        // Assert
        expect(accessibleEvents.length, 0); // Should be excluded due to access control
      });

      test('should exclude events when team has access but not prerequisites', () async {
        // Arrange
        final restrictedEventWithPrereqs = Event(
          id: 'event_2',
          groupId: 'group_1',
          title: 'Restricted Event with Prerequisites',
          description: 'Both restricted and has prerequisites',
          eventType: EventType.competition,
          status: EventStatus.active,
          eligibleTeamIds: ['team_1', 'team_2'], // team_1 is eligible
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
          createdBy: 'member_1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(mockRepository.getGroupEvents('group_1'))
            .thenAnswer((_) async => [restrictedEventWithPrereqs]);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenAnswer((_) async => false); // Prerequisites not met

        // Act
        final accessibleEvents = await eventService.getAccessibleEventsForTeam('group_1', 'team_1');

        // Assert
        expect(accessibleEvents.length, 0); // Should be excluded due to unmet prerequisites
      });
    });

    group('Edge Cases', () {
      test('should handle empty prerequisites list', () async {
        // Arrange
        final eventWithEmptyPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': []},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithEmptyPrereqs);

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isTrue);
      });

      test('should handle repository errors gracefully', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenThrow(Exception('Database error'));

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isFalse);
      });

      test('should handle completion check errors gracefully', () async {
        // Arrange
        final eventWithPrereqs = testEvent.copyWith(
          judgingCriteria: {'prerequisites': ['prereq_event_1']},
        );
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithPrereqs);
        when(mockRepository.hasTeamCompletedEvent('prereq_event_1', 'team_1'))
            .thenThrow(Exception('Database error'));

        // Act
        final meetsPrereqs = await eventService.doesTeamMeetPrerequisites('event_1', 'team_1');

        // Assert
        expect(meetsPrereqs, isFalse);
      });
    });
  });
}