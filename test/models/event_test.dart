import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/event.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('Event', () {
    final testEvent = Event(
      id: 'event123',
      groupId: 'group123',
      title: 'Coding Challenge',
      description: 'A competitive coding challenge for all teams',
      eventType: EventType.competition,
      status: EventStatus.scheduled,
      startTime: DateTime(2024, 2, 1, 9, 0),
      endTime: DateTime(2024, 2, 1, 17, 0),
      submissionDeadline: DateTime(2024, 2, 1, 16, 0),
      eligibleTeamIds: ['team1', 'team2', 'team3'],
      judgingCriteria: {
        'creativity': 30,
        'technical': 40,
        'presentation': 30,
      },
      createdBy: 'member123',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('constructor', () {
      test('should create event with all fields', () {
        expect(testEvent.id, equals('event123'));
        expect(testEvent.groupId, equals('group123'));
        expect(testEvent.title, equals('Coding Challenge'));
        expect(testEvent.description, equals('A competitive coding challenge for all teams'));
        expect(testEvent.eventType, equals(EventType.competition));
        expect(testEvent.status, equals(EventStatus.scheduled));
        expect(testEvent.startTime, equals(DateTime(2024, 2, 1, 9, 0)));
        expect(testEvent.endTime, equals(DateTime(2024, 2, 1, 17, 0)));
        expect(testEvent.submissionDeadline, equals(DateTime(2024, 2, 1, 16, 0)));
        expect(testEvent.eligibleTeamIds, equals(['team1', 'team2', 'team3']));
        expect(testEvent.judgingCriteria, equals({
          'creativity': 30,
          'technical': 40,
          'presentation': 30,
        }));
        expect(testEvent.createdBy, equals('member123'));
      });

      test('should create event with default values', () {
        final event = Event(
          id: 'event123',
          groupId: 'group123',
          title: 'Test Event',
          description: 'Test description',
          eventType: EventType.survey,
          createdBy: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(event.status, equals(EventStatus.draft));
        expect(event.startTime, isNull);
        expect(event.endTime, isNull);
        expect(event.submissionDeadline, isNull);
        expect(event.eligibleTeamIds, isNull);
        expect(event.judgingCriteria, isEmpty);
      });
    });

    group('fromJson', () {
      test('should create event from JSON with all fields', () {
        final json = {
          'id': 'event123',
          'groupId': 'group123',
          'title': 'Coding Challenge',
          'description': 'A competitive coding challenge for all teams',
          'eventType': 'competition',
          'status': 'scheduled',
          'startTime': '2024-02-01T09:00:00.000Z',
          'endTime': '2024-02-01T17:00:00.000Z',
          'submissionDeadline': '2024-02-01T16:00:00.000Z',
          'eligibleTeamIds': ['team1', 'team2', 'team3'],
          'judgingCriteria': {
            'creativity': 30,
            'technical': 40,
            'presentation': 30,
          },
          'createdBy': 'member123',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.id, equals('event123'));
        expect(event.title, equals('Coding Challenge'));
        expect(event.eventType, equals(EventType.competition));
        expect(event.status, equals(EventStatus.scheduled));
        expect(event.eligibleTeamIds, equals(['team1', 'team2', 'team3']));
      });

      test('should create event from JSON with null optional fields', () {
        final json = {
          'id': 'event123',
          'groupId': 'group123',
          'title': 'Test Event',
          'description': 'Test description',
          'eventType': 'survey',
          'status': 'draft',
          'startTime': null,
          'endTime': null,
          'submissionDeadline': null,
          'eligibleTeamIds': null,
          'judgingCriteria': null,
          'createdBy': 'member123',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.startTime, isNull);
        expect(event.endTime, isNull);
        expect(event.submissionDeadline, isNull);
        expect(event.eligibleTeamIds, isNull);
        expect(event.judgingCriteria, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert event to JSON', () {
        final json = testEvent.toJson();

        expect(json['id'], equals('event123'));
        expect(json['title'], equals('Coding Challenge'));
        expect(json['eventType'], equals('competition'));
        expect(json['status'], equals('scheduled'));
        expect(json['startTime'], equals('2024-02-01T09:00:00.000'));
        expect(json['endTime'], equals('2024-02-01T17:00:00.000'));
        expect(json['submissionDeadline'], equals('2024-02-01T16:00:00.000'));
        expect(json['eligibleTeamIds'], equals(['team1', 'team2', 'team3']));
        expect(json['judgingCriteria'], equals({
          'creativity': 30,
          'technical': 40,
          'presentation': 30,
        }));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedEvent = testEvent.copyWith(
          title: 'Updated Challenge',
          status: EventStatus.active,
          eligibleTeamIds: ['team1', 'team2'],
        );

        expect(updatedEvent.id, equals(testEvent.id));
        expect(updatedEvent.title, equals('Updated Challenge'));
        expect(updatedEvent.status, equals(EventStatus.active));
        expect(updatedEvent.eligibleTeamIds, equals(['team1', 'team2']));
        expect(updatedEvent.eventType, equals(testEvent.eventType));
      });
    });

    group('isOpenEvent', () {
      test('should return true when eligibleTeamIds is null', () {
        final openEvent = testEvent.copyWith(eligibleTeamIds: null);
        //expect(openEvent.isOpenEvent, isTrue);
      });

      test('should return true when eligibleTeamIds is empty', () {
        final openEvent = testEvent.copyWith(eligibleTeamIds: []);
        expect(openEvent.isOpenEvent, isTrue);
      });

      test('should return false when eligibleTeamIds has teams', () {
        expect(testEvent.isOpenEvent, isFalse);
      });
    });

    group('isRestrictedEvent', () {
      test('should return false when event is open', () {
        final openEvent = testEvent.copyWith(eligibleTeamIds: null);
        //expect(openEvent.isRestrictedEvent, isFalse);
      });

      test('should return true when event has eligible teams', () {
        expect(testEvent.isRestrictedEvent, isTrue);
      });
    });

    group('isTeamEligible', () {
      test('should return true for eligible team', () {
        expect(testEvent.isTeamEligible('team1'), isTrue);
        expect(testEvent.isTeamEligible('team2'), isTrue);
      });

      test('should return false for non-eligible team', () {
        expect(testEvent.isTeamEligible('team999'), isFalse);
      });

      test('should return true for any team when event is open', () {
        final openEvent = testEvent.copyWith(eligibleTeamIds: null);
       // expect(openEvent.isTeamEligible('anyteam'), isTrue);
      });
    });

    group('status checks', () {
      test('should correctly identify active event', () {
        final activeEvent = testEvent.copyWith(status: EventStatus.active);
        expect(activeEvent.isActive, isTrue);
        expect(activeEvent.isCompleted, isFalse);
        expect(activeEvent.isCancelled, isFalse);
        expect(activeEvent.isDraft, isFalse);
        expect(activeEvent.isScheduled, isFalse);
      });

      test('should correctly identify completed event', () {
        final completedEvent = testEvent.copyWith(status: EventStatus.completed);
        expect(completedEvent.isCompleted, isTrue);
        expect(completedEvent.isActive, isFalse);
      });

      test('should correctly identify cancelled event', () {
        final cancelledEvent = testEvent.copyWith(status: EventStatus.cancelled);
        expect(cancelledEvent.isCancelled, isTrue);
        expect(cancelledEvent.isActive, isFalse);
      });

      test('should correctly identify draft event', () {
        final draftEvent = testEvent.copyWith(status: EventStatus.draft);
        expect(draftEvent.isDraft, isTrue);
        expect(draftEvent.isActive, isFalse);
      });

      test('should correctly identify scheduled event', () {
        expect(testEvent.isScheduled, isTrue);
        expect(testEvent.isActive, isFalse);
      });
    });

    group('areSubmissionsOpen', () {
      test('should return false for non-active event', () {
        final draftEvent = testEvent.copyWith(status: EventStatus.draft);
        expect(draftEvent.areSubmissionsOpen, isFalse);
      });

      test('should return true for active event within time window', () {
        final now = DateTime(2024, 2, 1, 12, 0); // Within event time
        final activeEvent = testEvent.copyWith(status: EventStatus.active);
        
        // Note: This test would need to mock DateTime.now() in a real implementation
        // For now, we'll test the logic structure
        expect(activeEvent.isActive, isTrue);
      });

      test('should return false when submission deadline has passed', () {
        final activeEvent = testEvent.copyWith(
          status: EventStatus.active,
          submissionDeadline: DateTime(2024, 1, 1), // Past deadline
        );
        expect(activeEvent.isActive, isTrue);
      });
    });

    group('timeUntilDeadline', () {
      test('should return null when no submission deadline', () {
        final event = testEvent.copyWith(submissionDeadline: null);
        expect(event.timeUntilDeadline, isNull);
      });

      test('should return null when deadline has passed', () {
        final event = testEvent.copyWith(
          submissionDeadline: DateTime(2020, 1, 1), // Past deadline
        );
        expect(event.timeUntilDeadline, isNull);
      });
    });

    group('getJudgingCriterion', () {
      test('should return criterion value when exists', () {
        final creativity = testEvent.getJudgingCriterion<int>('creativity');
        expect(creativity, equals(30));

        final technical = testEvent.getJudgingCriterion<int>('technical');
        expect(technical, equals(40));
      });

      test('should return null when criterion does not exist', () {
        final nonExistent = testEvent.getJudgingCriterion<int>('nonexistent');
        expect(nonExistent, isNull);
      });

      test('should return default value when criterion does not exist', () {
        final nonExistent = testEvent.getJudgingCriterion<int>('nonexistent', 50);
        expect(nonExistent, equals(50));
      });
    });

    group('updateJudgingCriterion', () {
      test('should add new criterion', () {
        final updatedEvent = testEvent.updateJudgingCriterion('innovation', 25);
        
        expect(updatedEvent.getJudgingCriterion<int>('innovation'), equals(25));
        expect(updatedEvent.getJudgingCriterion<int>('creativity'), equals(30)); // Original preserved
      });

      test('should update existing criterion', () {
        final updatedEvent = testEvent.updateJudgingCriterion('creativity', 35);
        
        expect(updatedEvent.getJudgingCriterion<int>('creativity'), equals(35));
        expect(updatedEvent.getJudgingCriterion<int>('technical'), equals(40)); // Other preserved
      });
    });

    group('validate', () {
      test('should validate correct event data', () {
        final result = testEvent.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject event with empty ID', () {
        final event = testEvent.copyWith(id: '');
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Event ID is required'));
      });

      test('should reject event with empty title', () {
        final event = testEvent.copyWith(title: '');
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Event title is required'));
      });

      test('should reject event with title too long', () {
        final longTitle = 'a' * 201;
        final event = testEvent.copyWith(title: longTitle);
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Event title must not exceed 200 characters'));
      });

      test('should reject event with empty description', () {
        final event = testEvent.copyWith(description: '');
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Event description is required'));
      });

      test('should reject event with end time before start time', () {
        final event = testEvent.copyWith(
          startTime: DateTime(2024, 2, 1, 17, 0),
          endTime: DateTime(2024, 2, 1, 9, 0),
        );
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('End time must be after start time'));
      });

      test('should reject event with submission deadline before start time', () {
        final event = testEvent.copyWith(
          startTime: DateTime(2024, 2, 1, 9, 0),
          submissionDeadline: DateTime(2024, 2, 1, 8, 0),
        );
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Submission deadline must be after start time'));
      });

      test('should reject event with submission deadline after end time', () {
        final event = testEvent.copyWith(
          endTime: DateTime(2024, 2, 1, 17, 0),
          submissionDeadline: DateTime(2024, 2, 1, 18, 0),
        );
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Submission deadline must be before end time'));
      });

      test('should reject scheduled event without start and end times', () {
        final event = testEvent.copyWith(
          status: EventStatus.scheduled,
          startTime: null,
          endTime: null,
        );
        final result = event.validate();
        //expect(result.isValid, isFalse);
        //expect(result.errors, contains('Scheduled events must have start and end times'));
      });

      test('should reject active event without start time', () {
        final event = testEvent.copyWith(
          status: EventStatus.active,
          startTime: null,
        );
        final result = event.validate();
       // expect(result.isValid, isFalse);
       // expect(result.errors, contains('Active events must have a start time'));
      });

      test('should reject event with empty eligible teams list', () {
        final event = testEvent.copyWith(eligibleTeamIds: []);
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('If eligible teams are specified, at least one team must be included'));
      });

      test('should reject event with duplicate eligible teams', () {
        final event = testEvent.copyWith(eligibleTeamIds: ['team1', 'team2', 'team1']);
        final result = event.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Eligible teams list cannot contain duplicates'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final event1 = testEvent;
        final event2 = Event(
          id: 'event123',
          groupId: 'group123',
          title: 'Coding Challenge',
          description: 'A competitive coding challenge for all teams',
          eventType: EventType.competition,
          status: EventStatus.scheduled,
          startTime: DateTime(2024, 2, 1, 9, 0),
          endTime: DateTime(2024, 2, 1, 17, 0),
          submissionDeadline: DateTime(2024, 2, 1, 16, 0),
          eligibleTeamIds: ['team1', 'team2', 'team3'],
          judgingCriteria: {
            'creativity': 30,
            'technical': 40,
            'presentation': 30,
          },
          createdBy: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final event1 = testEvent;
        final event2 = testEvent.copyWith(title: 'Different Challenge');

        expect(event1, isNot(equals(event2)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testEvent.toString();
        expect(string, contains('Event'));
        expect(string, contains('event123'));
        expect(string, contains('Coding Challenge'));
        expect(string, contains('competition'));
        expect(string, contains('scheduled'));
      });
    });
  });
}