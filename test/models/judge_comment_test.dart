import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/judge_comment.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('JudgeComment Model', () {
    late JudgeComment testComment;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testComment = JudgeComment(
        id: 'comment_1',
        submissionId: 'submission_1',
        eventId: 'event_1',
        judgeId: 'judge_1',
        content: 'This is a test comment',
        type: JudgeCommentType.general,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Constructor', () {
      test('should create JudgeComment with required fields', () {
        expect(testComment.id, equals('comment_1'));
        expect(testComment.submissionId, equals('submission_1'));
        expect(testComment.eventId, equals('event_1'));
        expect(testComment.judgeId, equals('judge_1'));
        expect(testComment.content, equals('This is a test comment'));
        expect(testComment.type, equals(JudgeCommentType.general));
        expect(testComment.parentCommentId, isNull);
        expect(testComment.isPrivate, isTrue);
        expect(testComment.createdAt, equals(testDate));
        expect(testComment.updatedAt, equals(testDate));
      });

      test('should create JudgeComment with all fields', () {
        final comment = JudgeComment(
          id: 'comment_2',
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: 'judge_1',
          content: 'Reply comment',
          type: JudgeCommentType.question,
          parentCommentId: 'parent_comment_1',
          isPrivate: false,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(comment.parentCommentId, equals('parent_comment_1'));
        expect(comment.isPrivate, isFalse);
        expect(comment.type, equals(JudgeCommentType.question));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testComment.toJson();

        expect(json['id'], equals('comment_1'));
        expect(json['submissionId'], equals('submission_1'));
        expect(json['eventId'], equals('event_1'));
        expect(json['judgeId'], equals('judge_1'));
        expect(json['content'], equals('This is a test comment'));
        expect(json['type'], equals('general'));
        expect(json['parentCommentId'], isNull);
        expect(json['isPrivate'], isTrue);
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'comment_1',
          'submissionId': 'submission_1',
          'eventId': 'event_1',
          'judgeId': 'judge_1',
          'content': 'This is a test comment',
          'type': 'general',
          'parentCommentId': null,
          'isPrivate': true,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final comment = JudgeComment.fromJson(json);

        expect(comment.id, equals('comment_1'));
        expect(comment.submissionId, equals('submission_1'));
        expect(comment.eventId, equals('event_1'));
        expect(comment.judgeId, equals('judge_1'));
        expect(comment.content, equals('This is a test comment'));
        expect(comment.type, equals(JudgeCommentType.general));
        expect(comment.parentCommentId, isNull);
        expect(comment.isPrivate, isTrue);
        expect(comment.createdAt, equals(testDate));
        expect(comment.updatedAt, equals(testDate));
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'id': 'comment_1',
          'submissionId': 'submission_1',
          'eventId': 'event_1',
          'judgeId': 'judge_1',
          'content': 'This is a test comment',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final comment = JudgeComment.fromJson(json);

        expect(comment.type, equals(JudgeCommentType.general));
        expect(comment.parentCommentId, isNull);
        expect(comment.isPrivate, isTrue);
      });
    });

    group('CopyWith', () {
      test('should copy with updated content', () {
        final updatedComment = testComment.copyWith(
          content: 'Updated content',
          type: JudgeCommentType.suggestion,
        );

        expect(updatedComment.id, equals(testComment.id));
        expect(updatedComment.content, equals('Updated content'));
        expect(updatedComment.type, equals(JudgeCommentType.suggestion));
        expect(updatedComment.submissionId, equals(testComment.submissionId));
      });

      test('should copy with parent comment ID', () {
        final replyComment = testComment.copyWith(
          parentCommentId: 'parent_1',
        );

        expect(replyComment.parentCommentId, equals('parent_1'));
        expect(replyComment.isReply, isTrue);
        expect(replyComment.isTopLevel, isFalse);
      });
    });

    group('Helper Methods', () {
      test('should identify reply comments correctly', () {
        final topLevelComment = testComment;
        final replyComment = testComment.copyWith(parentCommentId: 'parent_1');

        expect(topLevelComment.isReply, isFalse);
        expect(topLevelComment.isTopLevel, isTrue);
        expect(replyComment.isReply, isTrue);
        expect(replyComment.isTopLevel, isFalse);
      });

      test('should generate content preview correctly', () {
        final shortComment = testComment;
        final longComment = testComment.copyWith(
          content: 'This is a very long comment that exceeds the preview limit of 100 characters and should be truncated with ellipsis',
        );

        expect(shortComment.contentPreview, equals('This is a test comment'));
        expect(longComment.contentPreview.length, equals(100));
        expect(longComment.contentPreview.endsWith('...'), isTrue);
      });
    });

    group('Validation', () {
      test('should validate valid comment', () {
        final result = testComment.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation with empty content', () {
        final invalidComment = testComment.copyWith(content: '');
        final result = invalidComment.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Comment content cannot be empty'));
      });

      test('should fail validation with content too long', () {
        final longContent = 'a' * 5001;
        final invalidComment = testComment.copyWith(content: longContent);
        final result = invalidComment.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Comment content must not exceed 5000 characters'));
      });

      test('should fail validation with invalid timestamps', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final invalidComment = testComment.copyWith(
          createdAt: futureDate,
          updatedAt: testDate,
        );
        final result = invalidComment.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Updated timestamp must be after or equal to creation timestamp'));
      });

      test('should fail validation with empty parent comment ID', () {
        final invalidComment = testComment.copyWith(parentCommentId: '');
        final result = invalidComment.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Parent comment ID cannot be empty if provided'));
      });
    });

    group('Equality', () {
      test('should be equal for identical comments', () {
        final comment1 = testComment;
        final comment2 = JudgeComment(
          id: 'comment_1',
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: 'judge_1',
          content: 'This is a test comment',
          type: JudgeCommentType.general,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(comment1, equals(comment2));
        expect(comment1.hashCode, equals(comment2.hashCode));
      });

      test('should not be equal for different comments', () {
        final comment1 = testComment;
        final comment2 = testComment.copyWith(content: 'Different content');

        expect(comment1, isNot(equals(comment2)));
        expect(comment1.hashCode, isNot(equals(comment2.hashCode)));
      });
    });

    group('ToString', () {
      test('should return meaningful string representation', () {
        final string = testComment.toString();
        
        expect(string, contains('JudgeComment'));
        expect(string, contains('comment_1'));
        expect(string, contains('submission_1'));
        expect(string, contains('judge_1'));
        expect(string, contains('general'));
      });
    });
  });

  group('JudgeAssignment Model', () {
    late JudgeAssignment testAssignment;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testAssignment = JudgeAssignment(
        id: 'assignment_1',
        eventId: 'event_1',
        judgeId: 'judge_1',
        assignedBy: 'admin_1',
        role: JudgeRole.judge,
        permissions: const ['score_submissions', 'comment_on_submissions'],
        isActive: true,
        assignedAt: testDate,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Constructor', () {
      test('should create JudgeAssignment with required fields', () {
        expect(testAssignment.id, equals('assignment_1'));
        expect(testAssignment.eventId, equals('event_1'));
        expect(testAssignment.judgeId, equals('judge_1'));
        expect(testAssignment.assignedBy, equals('admin_1'));
        expect(testAssignment.role, equals(JudgeRole.judge));
        expect(testAssignment.permissions, equals(['score_submissions', 'comment_on_submissions']));
        expect(testAssignment.isActive, isTrue);
        expect(testAssignment.assignedAt, equals(testDate));
        expect(testAssignment.revokedAt, isNull);
        expect(testAssignment.createdAt, equals(testDate));
        expect(testAssignment.updatedAt, equals(testDate));
      });
    });

    group('Permission Management', () {
      test('should check if has permission correctly', () {
        expect(testAssignment.hasPermission('score_submissions'), isTrue);
        expect(testAssignment.hasPermission('comment_on_submissions'), isTrue);
        expect(testAssignment.hasPermission('moderate_discussions'), isFalse);
      });

      test('should add permission correctly', () {
        final updatedAssignment = testAssignment.addPermission('moderate_discussions');
        
        expect(updatedAssignment.permissions, contains('moderate_discussions'));
        expect(updatedAssignment.permissions.length, equals(3));
        expect(updatedAssignment.updatedAt.isAfter(testDate), isTrue);
      });

      test('should not add duplicate permission', () {
        final updatedAssignment = testAssignment.addPermission('score_submissions');
        
        expect(updatedAssignment.permissions.length, equals(2));
        expect(updatedAssignment, equals(testAssignment));
      });

      test('should remove permission correctly', () {
        final updatedAssignment = testAssignment.removePermission('score_submissions');
        
        expect(updatedAssignment.permissions, isNot(contains('score_submissions')));
        expect(updatedAssignment.permissions.length, equals(1));
        expect(updatedAssignment.updatedAt.isAtSameMomentAs(testDate) || updatedAssignment.updatedAt.isAfter(testDate), isTrue);
      });

      test('should not change when removing non-existent permission', () {
        final updatedAssignment = testAssignment.removePermission('non_existent');
        
        expect(updatedAssignment.permissions.length, equals(2));
        expect(updatedAssignment, equals(testAssignment));
      });
    });

    group('Assignment Status', () {
      test('should revoke assignment correctly', () {
        final revokedAssignment = testAssignment.revoke();
        
        expect(revokedAssignment.isActive, isFalse);
        expect(revokedAssignment.revokedAt, isNotNull);
        expect(revokedAssignment.isCurrentlyActive, isFalse);
        expect(revokedAssignment.updatedAt.isAfter(testDate), isTrue);
      });

      test('should reactivate assignment correctly', () {
        final revokedAssignment = testAssignment.revoke();
        final reactivatedAssignment = revokedAssignment.reactivate();
        
        expect(reactivatedAssignment.isActive, isTrue);
        expect(reactivatedAssignment.revokedAt, isNull);
        expect(reactivatedAssignment.isCurrentlyActive, isTrue);
        expect(reactivatedAssignment.updatedAt.isAtSameMomentAs(revokedAssignment.updatedAt) || reactivatedAssignment.updatedAt.isAfter(revokedAssignment.updatedAt), isTrue);
      });

      test('should check currently active status correctly', () {
        final activeAssignment = testAssignment;
        final revokedAssignment = testAssignment.revoke();
        
        expect(activeAssignment.isCurrentlyActive, isTrue);
        expect(revokedAssignment.isCurrentlyActive, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testAssignment.toJson();

        expect(json['id'], equals('assignment_1'));
        expect(json['eventId'], equals('event_1'));
        expect(json['judgeId'], equals('judge_1'));
        expect(json['assignedBy'], equals('admin_1'));
        expect(json['role'], equals('judge'));
        expect(json['permissions'], equals(['score_submissions', 'comment_on_submissions']));
        expect(json['isActive'], isTrue);
        expect(json['assignedAt'], equals(testDate.toIso8601String()));
        expect(json['revokedAt'], isNull);
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'assignment_1',
          'eventId': 'event_1',
          'judgeId': 'judge_1',
          'assignedBy': 'admin_1',
          'role': 'judge',
          'permissions': ['score_submissions', 'comment_on_submissions'],
          'isActive': true,
          'assignedAt': testDate.toIso8601String(),
          'revokedAt': null,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final assignment = JudgeAssignment.fromJson(json);

        expect(assignment.id, equals('assignment_1'));
        expect(assignment.eventId, equals('event_1'));
        expect(assignment.judgeId, equals('judge_1'));
        expect(assignment.assignedBy, equals('admin_1'));
        expect(assignment.role, equals(JudgeRole.judge));
        expect(assignment.permissions, equals(['score_submissions', 'comment_on_submissions']));
        expect(assignment.isActive, isTrue);
        expect(assignment.assignedAt, equals(testDate));
        expect(assignment.revokedAt, isNull);
        expect(assignment.createdAt, equals(testDate));
        expect(assignment.updatedAt, equals(testDate));
      });
    });

    group('Validation', () {
      test('should validate valid assignment', () {
        final result = testAssignment.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation with invalid revoked date', () {
        final pastDate = testDate.subtract(const Duration(days: 1));
        final invalidAssignment = testAssignment.copyWith(
          revokedAt: pastDate,
        );
        final result = invalidAssignment.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Revoked date must be after assigned date'));
      });

      test('should fail validation when active but revoked', () {
        final invalidAssignment = testAssignment.copyWith(
          isActive: true,
          revokedAt: DateTime.now(),
        );
        final result = invalidAssignment.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Assignment cannot be active if revoked'));
      });
    });
  });
}