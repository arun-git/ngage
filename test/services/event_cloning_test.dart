import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/models.dart';
import '../../lib/services/event_service.dart';
import '../../lib/repositories/event_repository.dart';

import 'event_cloning_test.mocks.dart';

@GenerateMocks([EventRepository])
void main() {
  group('Event Cloning Tests', () {
    late EventService eventService;
    late MockEventRepository mockRepository;
    late Event originalEvent;

    setUp(() {
      mockRepository = MockEventRepository();
      eventService = EventService(eventRepository: mockRepository);
      
      originalEvent = Event(
        id: 'original_event_1',
        groupId: 'group_1',
        title: 'Original Event',
        description: 'Original event description',
        eventType: EventType.competition,
        status: EventStatus.completed,
        startTime: DateTime(2024, 1, 15, 10, 0),
        endTime: DateTime(2024, 1, 15, 18, 0),
        submissionDeadline: DateTime(2024, 1, 15, 16, 0),
        eligibleTeamIds: ['team_1', 'team_2'],
        judgingCriteria: {'creativity': 10, 'technical': 10},
        createdBy: 'member_1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    group('Basic Cloning', () {
      test('should clone event with default settings', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', any))
            .thenAnswer((_) async => []);

        // Act
        final clonedEvent = await eventService.cloneEvent('original_event_1');

        // Assert
        expect(clonedEvent.title, 'Original Event (Copy)');
        expect(clonedEvent.description, originalEvent.description);
        expect(clonedEvent.eventType, originalEvent.eventType);
        expect(clonedEvent.status, EventStatus.draft);
        expect(clonedEvent.groupId, originalEvent.groupId);
        expect(clonedEvent.judgingCriteria, originalEvent.judgingCriteria);
        expect(clonedEvent.createdBy, originalEvent.createdBy);
        
        // Should not preserve schedule by default
        expect(clonedEvent.startTime, isNull);
        expect(clonedEvent.endTime, isNull);
        expect(clonedEvent.submissionDeadline, isNull);
        
        // Should preserve access control by default
        expect(clonedEvent.eligibleTeamIds, originalEvent.eligibleTeamIds);
        
        verify(mockRepository.createEvent(any)).called(1);
      });

      test('should clone event with custom title and description', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', any))
            .thenAnswer((_) async => []);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          newTitle: 'Custom Clone Title',
          newDescription: 'Custom clone description',
        );

        // Assert
        expect(clonedEvent.title, 'Custom Clone Title');
        expect(clonedEvent.description, 'Custom clone description');
      });

      test('should clone event with different creator', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', any))
            .thenAnswer((_) async => []);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          createdBy: 'member_2',
        );

        // Assert
        expect(clonedEvent.createdBy, 'member_2');
      });
    });

    group('Schedule Preservation', () {
      test('should preserve schedule when preserveSchedule is true', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', any))
            .thenAnswer((_) async => []);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          preserveSchedule: true,
        );

        // Assert
        expect(clonedEvent.startTime, originalEvent.startTime);
        expect(clonedEvent.endTime, originalEvent.endTime);
        expect(clonedEvent.submissionDeadline, originalEvent.submissionDeadline);
      });

      test('should not preserve schedule when preserveSchedule is false', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', any))
            .thenAnswer((_) async => []);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          preserveSchedule: false,
        );

        // Assert
        expect(clonedEvent.startTime, isNull);
        expect(clonedEvent.endTime, isNull);
        expect(clonedEvent.submissionDeadline, isNull);
      });
    });

    group('Access Control Preservation', () {
      test('should preserve access control when preserveAccessControl is true', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', ['team_1', 'team_2']))
            .thenAnswer((_) async => ['team_1', 'team_2']);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          preserveAccessControl: true,
        );

        // Assert
        expect(clonedEvent.eligibleTeamIds, originalEvent.eligibleTeamIds);
        expect(clonedEvent.isRestrictedEvent, isTrue);
      });

      test('should reset access control when preserveAccessControl is false', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          preserveAccessControl: false,
        );

        // Assert
        expect(clonedEvent.eligibleTeamIds, isNull);
        expect(clonedEvent.isOpenEvent, isTrue);
      });

      test('should use new eligible team IDs when provided', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_1', ['team_3', 'team_4']))
            .thenAnswer((_) async => ['team_3', 'team_4']);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          newEligibleTeamIds: ['team_3', 'team_4'],
        );

        // Assert
        expect(clonedEvent.eligibleTeamIds, ['team_3', 'team_4']);
      });
    });

    group('Cross-Group Cloning', () {
      test('should clone event to different group', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          targetGroupId: 'group_2',
        );

        // Assert
        expect(clonedEvent.groupId, 'group_2');
        expect(clonedEvent.eligibleTeamIds, isNull); // Should reset access control for cross-group
      });

      test('should validate teams in target group for cross-group cloning', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});
        when(mockRepository.validateTeamsInGroup('group_2', ['team_5']))
            .thenAnswer((_) async => ['team_5']);

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          targetGroupId: 'group_2',
          newEligibleTeamIds: ['team_5'],
        );

        // Assert
        expect(clonedEvent.groupId, 'group_2');
        expect(clonedEvent.eligibleTeamIds, ['team_5']);
        verify(mockRepository.validateTeamsInGroup('group_2', ['team_5'])).called(1);
      });
    });

    group('Error Handling', () {
      test('should throw exception when original event not found', () async {
        // Arrange
        when(mockRepository.getEventById('nonexistent_event'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => eventService.cloneEvent('nonexistent_event'),
          throwsA(isA<EventNotFoundException>()),
        );
      });

      test('should throw exception when team validation fails', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.validateTeamsInGroup('group_1', ['invalid_team']))
            .thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => eventService.cloneEvent(
            'original_event_1',
            newEligibleTeamIds: ['invalid_team'],
          ),
          throwsA(isA<EventValidationException>()),
        );
      });

      test('should handle repository errors gracefully', () async {
        // Arrange
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => originalEvent);
        when(mockRepository.createEvent(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => eventService.cloneEvent('original_event_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Open Event Cloning', () {
      test('should clone open event correctly', () async {
        // Arrange
        final openEvent = originalEvent.copyWith(eligibleTeamIds: null);
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => openEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});

        // Act
        final clonedEvent = await eventService.cloneEvent('original_event_1');

        // Assert
        expect(clonedEvent.isOpenEvent, isTrue);
        expect(clonedEvent.eligibleTeamIds, isNull);
      });

      test('should preserve open event status when preserveAccessControl is true', () async {
        // Arrange
        final openEvent = originalEvent.copyWith(eligibleTeamIds: null);
        when(mockRepository.getEventById('original_event_1'))
            .thenAnswer((_) async => openEvent);
        when(mockRepository.createEvent(any))
            .thenAnswer((_) async {});

        // Act
        final clonedEvent = await eventService.cloneEvent(
          'original_event_1',
          preserveAccessControl: true,
        );

        // Assert
        expect(clonedEvent.isOpenEvent, isTrue);
        expect(clonedEvent.eligibleTeamIds, isNull);
      });
    });
  });
}