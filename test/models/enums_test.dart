import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('GroupType', () {
    test('should have correct values', () {
      expect(GroupType.corporate.value, equals('corporate'));
      expect(GroupType.educational.value, equals('educational'));
      expect(GroupType.community.value, equals('community'));
      expect(GroupType.social.value, equals('social'));
    });

    test('should create from string', () {
      expect(GroupType.fromString('corporate'), equals(GroupType.corporate));
      expect(GroupType.fromString('educational'), equals(GroupType.educational));
      expect(GroupType.fromString('community'), equals(GroupType.community));
      expect(GroupType.fromString('social'), equals(GroupType.social));
    });

    test('should throw error for invalid string', () {
      expect(
        () => GroupType.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have all expected values', () {
      expect(GroupType.values.length, equals(4));
      expect(GroupType.values, contains(GroupType.corporate));
      expect(GroupType.values, contains(GroupType.educational));
      expect(GroupType.values, contains(GroupType.community));
      expect(GroupType.values, contains(GroupType.social));
    });
  });

  group('EventType', () {
    test('should have correct values', () {
      expect(EventType.competition.value, equals('competition'));
      expect(EventType.challenge.value, equals('challenge'));
      expect(EventType.survey.value, equals('survey'));
    });

    test('should create from string', () {
      expect(EventType.fromString('competition'), equals(EventType.competition));
      expect(EventType.fromString('challenge'), equals(EventType.challenge));
      expect(EventType.fromString('survey'), equals(EventType.survey));
    });

    test('should throw error for invalid string', () {
      expect(
        () => EventType.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have all expected values', () {
      expect(EventType.values.length, equals(3));
      expect(EventType.values, contains(EventType.competition));
      expect(EventType.values, contains(EventType.challenge));
      expect(EventType.values, contains(EventType.survey));
    });
  });

  group('EventStatus', () {
    test('should have correct values', () {
      expect(EventStatus.draft.value, equals('draft'));
      expect(EventStatus.scheduled.value, equals('scheduled'));
      expect(EventStatus.active.value, equals('active'));
      expect(EventStatus.completed.value, equals('completed'));
      expect(EventStatus.cancelled.value, equals('cancelled'));
    });

    test('should create from string', () {
      expect(EventStatus.fromString('draft'), equals(EventStatus.draft));
      expect(EventStatus.fromString('scheduled'), equals(EventStatus.scheduled));
      expect(EventStatus.fromString('active'), equals(EventStatus.active));
      expect(EventStatus.fromString('completed'), equals(EventStatus.completed));
      expect(EventStatus.fromString('cancelled'), equals(EventStatus.cancelled));
    });

    test('should throw error for invalid string', () {
      expect(
        () => EventStatus.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have all expected values', () {
      expect(EventStatus.values.length, equals(5));
      expect(EventStatus.values, contains(EventStatus.draft));
      expect(EventStatus.values, contains(EventStatus.scheduled));
      expect(EventStatus.values, contains(EventStatus.active));
      expect(EventStatus.values, contains(EventStatus.completed));
      expect(EventStatus.values, contains(EventStatus.cancelled));
    });
  });

  group('SubmissionStatus', () {
    test('should have correct values', () {
      expect(SubmissionStatus.draft.value, equals('draft'));
      expect(SubmissionStatus.submitted.value, equals('submitted'));
      expect(SubmissionStatus.underReview.value, equals('under_review'));
      expect(SubmissionStatus.approved.value, equals('approved'));
      expect(SubmissionStatus.rejected.value, equals('rejected'));
    });

    test('should create from string', () {
      expect(SubmissionStatus.fromString('draft'), equals(SubmissionStatus.draft));
      expect(SubmissionStatus.fromString('submitted'), equals(SubmissionStatus.submitted));
      expect(SubmissionStatus.fromString('under_review'), equals(SubmissionStatus.underReview));
      expect(SubmissionStatus.fromString('approved'), equals(SubmissionStatus.approved));
      expect(SubmissionStatus.fromString('rejected'), equals(SubmissionStatus.rejected));
    });

    test('should throw error for invalid string', () {
      expect(
        () => SubmissionStatus.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have all expected values', () {
      expect(SubmissionStatus.values.length, equals(5));
      expect(SubmissionStatus.values, contains(SubmissionStatus.draft));
      expect(SubmissionStatus.values, contains(SubmissionStatus.submitted));
      expect(SubmissionStatus.values, contains(SubmissionStatus.underReview));
      expect(SubmissionStatus.values, contains(SubmissionStatus.approved));
      expect(SubmissionStatus.values, contains(SubmissionStatus.rejected));
    });
  });

  group('GroupRole', () {
    test('should have correct values', () {
      expect(GroupRole.admin.value, equals('admin'));
      expect(GroupRole.judge.value, equals('judge'));
      expect(GroupRole.teamLead.value, equals('team_lead'));
      expect(GroupRole.member.value, equals('member'));
    });

    test('should create from string', () {
      expect(GroupRole.fromString('admin'), equals(GroupRole.admin));
      expect(GroupRole.fromString('judge'), equals(GroupRole.judge));
      expect(GroupRole.fromString('team_lead'), equals(GroupRole.teamLead));
      expect(GroupRole.fromString('member'), equals(GroupRole.member));
    });

    test('should throw error for invalid string', () {
      expect(
        () => GroupRole.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have all expected values', () {
      expect(GroupRole.values.length, equals(4));
      expect(GroupRole.values, contains(GroupRole.admin));
      expect(GroupRole.values, contains(GroupRole.judge));
      expect(GroupRole.values, contains(GroupRole.teamLead));
      expect(GroupRole.values, contains(GroupRole.member));
    });
  });

  group('NotificationType', () {
    test('should have correct values', () {
      expect(NotificationType.eventReminder.value, equals('event_reminder'));
      expect(NotificationType.deadlineAlert.value, equals('deadline_alert'));
      expect(NotificationType.resultAnnouncement.value, equals('result_announcement'));
      expect(NotificationType.leaderboardUpdate.value, equals('leaderboard_update'));
      expect(NotificationType.general.value, equals('general'));
    });

    test('should create from string', () {
      expect(NotificationType.fromString('event_reminder'), equals(NotificationType.eventReminder));
      expect(NotificationType.fromString('deadline_alert'), equals(NotificationType.deadlineAlert));
      expect(NotificationType.fromString('result_announcement'), equals(NotificationType.resultAnnouncement));
      expect(NotificationType.fromString('leaderboard_update'), equals(NotificationType.leaderboardUpdate));
      expect(NotificationType.fromString('general'), equals(NotificationType.general));
    });

    test('should throw error for invalid string', () {
      expect(
        () => NotificationType.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should have all expected values', () {
      expect(NotificationType.values.length, equals(5));
      expect(NotificationType.values, contains(NotificationType.eventReminder));
      expect(NotificationType.values, contains(NotificationType.deadlineAlert));
      expect(NotificationType.values, contains(NotificationType.resultAnnouncement));
      expect(NotificationType.values, contains(NotificationType.leaderboardUpdate));
      expect(NotificationType.values, contains(NotificationType.general));
    });
  });
}