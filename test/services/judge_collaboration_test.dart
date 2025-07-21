import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/services/judging_service.dart';
import 'package:ngage/repositories/judge_comment_repository.dart';
import 'package:ngage/repositories/judge_assignment_repository.dart';
import 'package:ngage/repositories/score_repository.dart';
import 'package:ngage/repositories/scoring_rubric_repository.dart';
import 'package:ngage/repositories/submission_repository.dart';
import 'package:ngage/repositories/team_repository.dart';

import 'judge_collaboration_test.mocks.dart';

@GenerateMocks([
  JudgeCommentRepository,
  JudgeAssignmentRepository,
  ScoreRepository,
  ScoringRubricRepository,
  SubmissionRepository,
  TeamRepository,
])
void main() {
  group('Judge Collaboration Features', () {
    late JudgingService judgingService;
    late MockJudgeCommentRepository mockCommentRepository;
    late MockJudgeAssignmentRepository mockAssignmentRepository;
    late MockScoreRepository mockScoreRepository;
    late MockScoringRubricRepository mockRubricRepository;
    late MockSubmissionRepository mockSubmissionRepository;
    late MockTeamRepository mockTeamRepository;

    setUp(() {
      mockCommentRepository = MockJudgeCommentRepository();
      mockAssignmentRepository = MockJudgeAssignmentRepository();
      mockScoreRepository = MockScoreRepository();
      mockRubricRepository = MockScoringRubricRepository();
      mockSubmissionRepository = MockSubmissionRepository();
      mockTeamRepository = MockTeamRepository();

      judgingService = JudgingService(
        commentRepository: mockCommentRepository,
        assignmentRepository: mockAssignmentRepository,
        scoreRepository: mockScoreRepository,
        rubricRepository: mockRubricRepository,
        submissionRepository: mockSubmissionRepository,
        teamRepository: mockTeamRepository,
      );
    });

    group('Judge Comments', () {
      test('should create judge comment successfully', () async {
        // Arrange
        const submissionId = 'submission_1';
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const content = 'This is a test comment';
        const type = JudgeCommentType.general;

        final assignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: 'admin_1',
          role: JudgeRole.judge,
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final expectedComment = JudgeComment(
          id: 'comment_1',
          submissionId: submissionId,
          eventId: eventId,
          judgeId: judgeId,
          content: content,
          type: type,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => assignment);
        when(mockCommentRepository.create(any))
            .thenAnswer((_) async => expectedComment);

        // Act
        final result = await judgingService.createJudgeComment(
          submissionId: submissionId,
          eventId: eventId,
          judgeId: judgeId,
          content: content,
          type: type,
        );

        // Assert
        expect(result.submissionId, equals(submissionId));
        expect(result.eventId, equals(eventId));
        expect(result.judgeId, equals(judgeId));
        expect(result.content, equals(content));
        expect(result.type, equals(type));
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(1);
        verify(mockCommentRepository.create(any)).called(1);
      });

      test('should throw exception when judge is not assigned to event', () async {
        // Arrange
        const submissionId = 'submission_1';
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const content = 'This is a test comment';

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => judgingService.createJudgeComment(
            submissionId: submissionId,
            eventId: eventId,
            judgeId: judgeId,
            content: content,
          ),
          throwsA(isA<Exception>()),
        );
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(1);
        verifyNever(mockCommentRepository.create(any));
      });

      test('should get submission comments successfully', () async {
        // Arrange
        const submissionId = 'submission_1';
        final expectedComments = [
          JudgeComment(
            id: 'comment_1',
            submissionId: submissionId,
            eventId: 'event_1',
            judgeId: 'judge_1',
            content: 'First comment',
            type: JudgeCommentType.general,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          JudgeComment(
            id: 'comment_2',
            submissionId: submissionId,
            eventId: 'event_1',
            judgeId: 'judge_2',
            content: 'Second comment',
            type: JudgeCommentType.question,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockCommentRepository.getBySubmissionId(submissionId))
            .thenAnswer((_) async => expectedComments);

        // Act
        final result = await judgingService.getSubmissionComments(submissionId);

        // Assert
        expect(result, equals(expectedComments));
        expect(result.length, equals(2));
        verify(mockCommentRepository.getBySubmissionId(submissionId)).called(1);
      });

      test('should update judge comment successfully', () async {
        // Arrange
        const commentId = 'comment_1';
        const judgeId = 'judge_1';
        const newContent = 'Updated comment content';
        const newType = JudgeCommentType.suggestion;

        final existingComment = JudgeComment(
          id: commentId,
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: judgeId,
          content: 'Original content',
          type: JudgeCommentType.general,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updatedComment = existingComment.copyWith(
          content: newContent,
          type: newType,
          updatedAt: DateTime.now(),
        );

        when(mockCommentRepository.getById(commentId))
            .thenAnswer((_) async => existingComment);
        when(mockCommentRepository.update(any))
            .thenAnswer((_) async => updatedComment);

        // Act
        final result = await judgingService.updateJudgeComment(
          commentId: commentId,
          judgeId: judgeId,
          content: newContent,
          type: newType,
        );

        // Assert
        expect(result.content, equals(newContent));
        expect(result.type, equals(newType));
        verify(mockCommentRepository.getById(commentId)).called(1);
        verify(mockCommentRepository.update(any)).called(1);
      });

      test('should throw exception when updating comment by different judge', () async {
        // Arrange
        const commentId = 'comment_1';
        const judgeId = 'judge_1';
        const differentJudgeId = 'judge_2';
        const newContent = 'Updated comment content';

        final existingComment = JudgeComment(
          id: commentId,
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: judgeId,
          content: 'Original content',
          type: JudgeCommentType.general,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCommentRepository.getById(commentId))
            .thenAnswer((_) async => existingComment);

        // Act & Assert
        expect(
          () => judgingService.updateJudgeComment(
            commentId: commentId,
            judgeId: differentJudgeId,
            content: newContent,
          ),
          throwsA(isA<Exception>()),
        );
        verify(mockCommentRepository.getById(commentId)).called(1);
        verifyNever(mockCommentRepository.update(any));
      });

      test('should delete judge comment successfully', () async {
        // Arrange
        const commentId = 'comment_1';
        const judgeId = 'judge_1';

        final existingComment = JudgeComment(
          id: commentId,
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: judgeId,
          content: 'Comment to delete',
          type: JudgeCommentType.general,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCommentRepository.getById(commentId))
            .thenAnswer((_) async => existingComment);
        when(mockCommentRepository.delete(commentId))
            .thenAnswer((_) async => {});

        // Act
        await judgingService.deleteJudgeComment(commentId, judgeId);

        // Assert
        verify(mockCommentRepository.getById(commentId)).called(1);
        verify(mockCommentRepository.delete(commentId)).called(1);
      });
    });

    group('Judge Assignments', () {
      test('should assign judge to event successfully', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const assignedBy = 'admin_1';
        const role = JudgeRole.judge;
        const permissions = ['score_submissions', 'comment_on_submissions'];

        final expectedAssignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: assignedBy,
          role: role,
          permissions: permissions,
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getAssignment(eventId, judgeId))
            .thenAnswer((_) async => null);
        when(mockAssignmentRepository.create(any))
            .thenAnswer((_) async => expectedAssignment);

        // Act
        final result = await judgingService.assignJudge(
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: assignedBy,
          role: role,
          permissions: permissions,
        );

        // Assert
        expect(result.eventId, equals(eventId));
        expect(result.judgeId, equals(judgeId));
        expect(result.assignedBy, equals(assignedBy));
        expect(result.role, equals(role));
        expect(result.permissions, equals(permissions));
        expect(result.isActive, isTrue);
        verify(mockAssignmentRepository.getAssignment(eventId, judgeId)).called(1);
        verify(mockAssignmentRepository.create(any)).called(1);
      });

      test('should throw exception when judge is already assigned', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const assignedBy = 'admin_1';

        final existingAssignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: assignedBy,
          role: JudgeRole.judge,
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getAssignment(eventId, judgeId))
            .thenAnswer((_) async => existingAssignment);

        // Act & Assert
        expect(
          () => judgingService.assignJudge(
            eventId: eventId,
            judgeId: judgeId,
            assignedBy: assignedBy,
          ),
          throwsA(isA<Exception>()),
        );
        verify(mockAssignmentRepository.getAssignment(eventId, judgeId)).called(1);
        verifyNever(mockAssignmentRepository.create(any));
      });

      test('should remove judge from event successfully', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';

        final activeAssignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: 'admin_1',
          role: JudgeRole.judge,
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final revokedAssignment = activeAssignment.revoke();

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => activeAssignment);
        when(mockAssignmentRepository.update(any))
            .thenAnswer((_) async => revokedAssignment);

        // Act
        final result = await judgingService.removeJudge(
          eventId: eventId,
          judgeId: judgeId,
        );

        // Assert
        expect(result.isActive, isFalse);
        expect(result.revokedAt, isNotNull);
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(1);
        verify(mockAssignmentRepository.update(any)).called(1);
      });

      test('should get event judges successfully', () async {
        // Arrange
        const eventId = 'event_1';
        final expectedAssignments = [
          JudgeAssignment(
            id: 'assignment_1',
            eventId: eventId,
            judgeId: 'judge_1',
            assignedBy: 'admin_1',
            role: JudgeRole.judge,
            isActive: true,
            assignedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          JudgeAssignment(
            id: 'assignment_2',
            eventId: eventId,
            judgeId: 'judge_2',
            assignedBy: 'admin_1',
            role: JudgeRole.leadJudge,
            isActive: true,
            assignedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockAssignmentRepository.getActiveByEventId(eventId))
            .thenAnswer((_) async => expectedAssignments);

        // Act
        final result = await judgingService.getEventJudges(eventId);

        // Assert
        expect(result, equals(expectedAssignments));
        expect(result.length, equals(2));
        verify(mockAssignmentRepository.getActiveByEventId(eventId)).called(1);
      });

      test('should update judge assignment successfully', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const newRole = JudgeRole.leadJudge;
        const newPermissions = ['score_submissions', 'view_all_scores', 'moderate_discussions'];

        final existingAssignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: 'admin_1',
          role: JudgeRole.judge,
          permissions: const ['score_submissions'],
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updatedAssignment = existingAssignment.copyWith(
          role: newRole,
          permissions: newPermissions,
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => existingAssignment);
        when(mockAssignmentRepository.update(any))
            .thenAnswer((_) async => updatedAssignment);

        // Act
        final result = await judgingService.updateJudgeAssignment(
          eventId: eventId,
          judgeId: judgeId,
          role: newRole,
          permissions: newPermissions,
        );

        // Assert
        expect(result.role, equals(newRole));
        expect(result.permissions, equals(newPermissions));
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(1);
        verify(mockAssignmentRepository.update(any)).called(1);
      });

      test('should check judge permission correctly', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const permission = 'score_submissions';

        final assignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: 'admin_1',
          role: JudgeRole.judge,
          permissions: const ['score_submissions', 'comment_on_submissions'],
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => assignment);

        // Act
        final result = await judgingService.hasJudgePermission(
          eventId: eventId,
          judgeId: judgeId,
          permission: permission,
        );

        // Assert
        expect(result, isTrue);
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(1);
      });

      test('should return false for judge permission when not assigned', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const permission = 'score_submissions';

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => null);

        // Act
        final result = await judgingService.hasJudgePermission(
          eventId: eventId,
          judgeId: judgeId,
          permission: permission,
        );

        // Assert
        expect(result, isFalse);
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(1);
      });

      test('should get lead judges successfully', () async {
        // Arrange
        const eventId = 'event_1';
        final expectedLeadJudges = [
          JudgeAssignment(
            id: 'assignment_1',
            eventId: eventId,
            judgeId: 'judge_1',
            assignedBy: 'admin_1',
            role: JudgeRole.leadJudge,
            isActive: true,
            assignedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockAssignmentRepository.getLeadJudges(eventId))
            .thenAnswer((_) async => expectedLeadJudges);

        // Act
        final result = await judgingService.getLeadJudges(eventId);

        // Assert
        expect(result, equals(expectedLeadJudges));
        expect(result.length, equals(1));
        expect(result.first.role, equals(JudgeRole.leadJudge));
        verify(mockAssignmentRepository.getLeadJudges(eventId)).called(1);
      });
    });

    group('Permission Validation', () {
      test('should validate judge action successfully', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const action = 'score_submissions';

        final assignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: 'admin_1',
          role: JudgeRole.judge,
          permissions: const ['score_submissions'],
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => assignment);

        // Act & Assert
        expect(
          () => judgingService.validateJudgeAction(
            eventId: eventId,
            judgeId: judgeId,
            action: action,
          ),
          returnsNormally,
        );
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(2);
      });

      test('should throw exception when judge lacks permission', () async {
        // Arrange
        const eventId = 'event_1';
        const judgeId = 'judge_1';
        const action = 'moderate_discussions';

        final assignment = JudgeAssignment(
          id: 'assignment_1',
          eventId: eventId,
          judgeId: judgeId,
          assignedBy: 'admin_1',
          role: JudgeRole.judge,
          permissions: const ['score_submissions'],
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAssignmentRepository.getActiveAssignment(eventId, judgeId))
            .thenAnswer((_) async => assignment);

        // Act & Assert
        expect(
          () => judgingService.validateJudgeAction(
            eventId: eventId,
            judgeId: judgeId,
            action: action,
          ),
          throwsA(isA<Exception>()),
        );
        verify(mockAssignmentRepository.getActiveAssignment(eventId, judgeId)).called(2);
      });
    });
  });
}