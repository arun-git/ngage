import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/services/event_service.dart';
import 'package:ngage/repositories/event_repository.dart';

import 'event_access_control_test.mocks.dart';

@GenerateMocks([EventRepository])
void main() {
  group('Event Access Control Tests', () {
    late EventService eventService;
    late MockEventRepository mockRepository;
    late Event testEvent;

    setUp(() {
      mockRepository = MockEventRepository();
      eventService = EventService(eventRepository: mockRepository);
      
      testEvent = Event(
        id: 'event_1',
        groupId: 'group_1',
        title: 'Test Event',
        description: 'Test event description',
        eventType: EventType.competition,
        status: EventStatus.active,
        eligibleTeamIds: ['team_1', 'team_2'],
        createdBy: 'member_1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    group('Update Event Access', () {
      test('should update event to open access', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.updateEventAccess('event_1', eligibleTeamIds: null))
            .thenAnswer((_) async {});

        // Act
        final updatedEvent = await eventService.updateEventAccess(
          'event_1',
          eligibleTeamIds: null,
        );

        // Assert
        expect(updatedEvent.isOpenEvent, isTrue);
        expect(updatedEvent.eligibleTeamIds, isNull);
        verify(mockRepository.updateEventAccess('event_1', eligibleTeamIds: null)).called(1);
      });

      test('should update event to restricted access', () async {
        // Arrange
        final openEvent = testEvent.copyWith(eligibleTeamIds: null);
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => openEvent);
        when(mockRepository.validateTeamsInGroup('group_1', ['team_3', 'team_4']))
            .thenAnswer((_) async => ['team_3', 'team_4']);
        when(mockRepository.updateEventAccess('event_1', eligibleTeamIds: ['team_3', 'team_4']))
            .thenAnswer((_) async {});

        // Act
        final updatedEvent = await eventService.updateEventAccess(
          'event_1',
          eligibleTeamIds: ['team_3', 'team_4'],
        );

        // Assert
        expect(updatedEvent.isRestrictedEvent, isTrue);
        expect(updatedEvent.eligibleTeamIds, ['team_3', 'team_4']);
        verify(mockRepository.updateEventAccess('event_1', eligibleTeamIds: ['team_3', 'team_4'])).called(1);
      });

      test('should validate team IDs before updating access', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);
        when(mockRepository.validateTeamsInGroup('group_1', ['team_1', 'invalid_team']))
            .thenAnswer((_) async => ['team_1']); // Only team_1 is valid

        // Act & Assert
        expect(
          () => eventService.updateEventAccess(
            'event_1',
            eligibleTeamIds: ['team_1', 'invalid_team'],
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
          () => eventService.updateEventAccess('nonexistent_event'),
          throwsA(isA<EventNotFoundException>()),
        );
      });
    });

    group('Team Access Checking', () {
      test('should return true for team eligible for open event', () async {
        // Arrange
        final openEvent = testEvent.copyWith(eligibleTeamIds: null);
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => openEvent);

        // Act
        final canAccess = await eventService.canTeamAccessEvent('event_1', 'any_team');

        // Assert
        expect(canAccess, isTrue);
      });

      test('should return true for team in eligible list', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);

        // Act
        final canAccess = await eventService.canTeamAccessEvent('event_1', 'team_1');

        // Assert
        expect(canAccess, isTrue);
      });

      test('should return false for team not in eligible list', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);

        // Act
        final canAccess = await eventService.canTeamAccessEvent('event_1', 'team_3');

        // Assert
        expect(canAccess, isFalse);
      });

      test('should return false when event not found', () async {
        // Arrange
        when(mockRepository.getEventById('nonexistent_event'))
            .thenAnswer((_) async => null);

        // Act
        final canAccess = await eventService.canTeamAccessEvent('nonexistent_event', 'team_1');

        // Assert
        expect(canAccess, isFalse);
      });
    });

    group('Get Eligible Teams', () {
      test('should return all group teams for open event', () async {
        // Arrange
        final openEvent = testEvent.copyWith(eligibleTeamIds: null);
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => openEvent);
        when(mockRepository.getAllGroupTeamIds('group_1'))
            .thenAnswer((_) async => ['team_1', 'team_2', 'team_3', 'team_4']);

        // Act
        final eligibleTeams = await eventService.getEligibleTeams('event_1');

        // Assert
        expect(eligibleTeams, ['team_1', 'team_2', 'team_3', 'team_4']);
      });

      test('should return specific teams for restricted event', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);

        // Act
        final eligibleTeams = await eventService.getEligibleTeams('event_1');

        // Assert
        expect(eligibleTeams, ['team_1', 'team_2']);
      });

      test('should throw exception when event not found', () async {
        // Arrange
        when(mockRepository.getEventById('nonexistent_event'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.getEligibleTeams('nonexistent_event'),
          throwsA(isA<EventNotFoundException>()),
        );
      });
    });

    group('Get Team Eligible Events', () {
      test('should return events team can access', () async {
        // Arrange
        final events = [
          testEvent, // team_1 is eligible
          testEvent.copyWith(
            id: 'event_2',
            eligibleTeamIds: ['team_3', 'team_4'], // team_1 not eligible
          ),
          testEvent.copyWith(
            id: 'event_3',
            eligibleTeamIds: null, // open event
          ),
        ];
        
        when(mockRepository.getTeamEligibleEvents('group_1', 'team_1'))
            .thenAnswer((_) async => [events[0], events[2]]); // Only eligible events

        // Act
        final eligibleEvents = await eventService.getTeamEligibleEvents('group_1', 'team_1');

        // Assert
        expect(eligibleEvents.length, 2);
        expect(eligibleEvents.map((e) => e.id), ['event_1', 'event_3']);
      });
    });

    group('Get Accessible Events for Team', () {
      test('should return events considering prerequisites', () async {
        // Arrange
        final eventWithPrereq = testEvent.copyWith(
          id: 'event_2',
          judgingCriteria: {'prerequisites': ['event_1']},
        );
        
        when(mockRepository.getGroupEvents('group_1'))
            .thenAnswer((_) async => [testEvent, eventWithPrereq]);
        when(mockRepository.hasTeamCompletedEvent('event_1', 'team_1'))
            .thenAnswer((_) async => true);

        // Act
        final accessibleEvents = await eventService.getAccessibleEventsForTeam('group_1', 'team_1');

        // Assert
        expect(accessibleEvents.length, 2);
        expect(accessibleEvents.map((e) => e.id), ['event_1', 'event_2']);
      });

      test('should exclude events with unmet prerequisites', () async {
        // Arrange
        final eventWithPrereq = testEvent.copyWith(
          id: 'event_2',
          judgingCriteria: {'prerequisites': ['event_1']},
        );
        
        when(mockRepository.getGroupEvents('group_1'))
            .thenAnswer((_) async => [testEvent, eventWithPrereq]);
        when(mockRepository.hasTeamCompletedEvent('event_1', 'team_1'))
            .thenAnswer((_) async => false); // Prerequisite not met

        // Act
        final accessibleEvents = await eventService.getAccessibleEventsForTeam('group_1', 'team_1');

        // Assert
        expect(accessibleEvents.length, 1);
        expect(accessibleEvents.first.id, 'event_1');
      });

      test('should exclude events team is not eligible for', () async {
        // Arrange
        final restrictedEvent = testEvent.copyWith(
          id: 'event_2',
          eligibleTeamIds: ['team_3', 'team_4'], // team_1 not eligible
        );
        
        when(mockRepository.getGroupEvents('group_1'))
            .thenAnswer((_) async => [testEvent, restrictedEvent]);

        // Act
        final accessibleEvents = await eventService.getAccessibleEventsForTeam('group_1', 'team_1');

        // Assert
        expect(accessibleEvents.length, 1);
        expect(accessibleEvents.first.id, 'event_1');
      });
    });

    group('Edge Cases', () {
      test('should handle empty eligible team list as open event', () async {
        // Arrange
        final eventWithEmptyList = testEvent.copyWith(eligibleTeamIds: []);
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => eventWithEmptyList);

        // Act
        final canAccess = await eventService.canTeamAccessEvent('event_1', 'any_team');

        // Assert
        expect(canAccess, isFalse); // Empty list means no teams eligible
      });

      test('should handle null team ID gracefully', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenAnswer((_) async => testEvent);

        // Act
        final canAccess = await eventService.canTeamAccessEvent('event_1', '');

        // Assert
        expect(canAccess, isFalse);
      });

      test('should handle repository errors in access checking', () async {
        // Arrange
        when(mockRepository.getEventById('event_1'))
            .thenThrow(Exception('Database error'));

        // Act
        final canAccess = await eventService.canTeamAccessEvent('event_1', 'team_1');

        // Assert
        expect(canAccess, isFalse); // Should return false on error
      });
    });
  });
}