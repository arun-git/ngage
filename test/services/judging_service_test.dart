import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/models.dart';
import '../../lib/services/judging_service.dart';
import '../../lib/repositories/score_repository.dart';
import '../../lib/repositories/scoring_rubric_repository.dart';
import '../../lib/repositories/submission_repository.dart';
import '../../lib/repositories/team_repository.dart';

import 'judging_service_test.mocks.dart';

@GenerateMocks([
  ScoreRepository,
  ScoringRubricRepository,
  SubmissionRepository,
  TeamRepository,
])
void main() {
  group('JudgingService Tests', () {
    late JudgingService judgingService;
    late MockScoreRepository mockScoreRepository;
    late MockScoringRubricRepository mockRubricRepository;
    late MockSubmissionRepository mockSubmissionRepository;
    late MockTeamRepository mockTeamRepository;

    late Submission testSubmission;
    late ScoringRubric testRubric;
    late Score testScore;
    late Team testTeam;

    setUp(() {
      mockScoreRepository = MockScoreRepository();
      mockRubricRepository = MockScoringRubricRepository();
      mockSubmissionRepository = MockSubmissionRepository();
      mockTeamRepository = MockTeamRepository();

      judgingService = JudgingService(
        scoreRepository: mockScoreRepository,
        rubricRepository: mockRubricRepository,
        submissionRepository: mockSubmissionRepository,
        teamRepository: mockTeamRepository,
      );

      testSubmission = Submission(
        id: 'submission_123',
        eventId: 'event_456',
        teamId: 'team_789',
        submittedBy: 'member_101',
        content: {'description': 'Test submission'},
        status: SubmissionStatus.submitted,
        submittedAt: DateTime(2024, 1, 1, 12, 0),
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 1, 12, 0),
      );

      testRubric = ScoringRubric(
        id: 'rubric_123',
        name: 'Test Rubric',
        description: 'Test scoring rubric',
        criteria: [
          ScoringCriterion(
            key: 'creativity',
            name: 'Creativity',
            description: 'Creative aspects',
            maxScore: 100.0,
            weight: 0.4,
          ),
          ScoringCriterion(
            key: 'technical',
            name: 'Technical',
            description: 'Technical implementation',
            maxScore: 100.0,
            weight: 0.6,
          ),
        ],
        createdBy: 'member_123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      testScore = Score(
        id: 'score_123',
        submissionId: 'submission_123',
        judgeId: 'judge_456',
        eventId: 'event_456',
        scores: {'creativity': 85.0, 'technical': 90.0},
        comments: 'Great work!',
        totalScore: 88.0,
        createdAt: DateTime(2024, 1, 1, 14, 0),
        updatedAt: DateTime(2024, 1, 1, 14, 0),
      );

      testTeam = Team(
        id: 'team_789',
        groupId: 'group_101',
        name: 'Test Team',
        description: 'Test team description',
        teamLeadId: 'member_101',
        memberIds: ['member_101', 'member_102'],
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    group('Score Submission', () {
      test('should create new score when none exists', () async {
        // Arrange
        when(mockSubmissionRepository.getById('submission_123'))
            .thenAnswer((_) async => testSubmission);
        when(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456'))
            .thenAnswer((_) async => null);
        when(mockScoreRepository.create(any))
            .thenAnswer((_) async => testScore);

        final scores = {'creativity': 85.0, 'technical': 90.0};

        // Act
        final result = await judgingService.scoreSubmission(
          submissionId: 'submission_123',
          judgeId: 'judge_456',
          eventId: 'event_456',
          scores: scores,
          comments: 'Great work!',
          rubric: testRubric,
        );

        // Assert
        expect(result, isA<Score>());
        verify(mockSubmissionRepository.getById('submission_123')).called(1);
        verify(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456')).called(1);
        verify(mockScoreRepository.create(any)).called(1);
      });

      test('should update existing score when one exists', () async {
        // Arrange
        when(mockSubmissionRepository.getById('submission_123'))
            .thenAnswer((_) async => testSubmission);
        when(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456'))
            .thenAnswer((_) async => testScore);
        when(mockScoreRepository.update(any))
            .thenAnswer((_) async => testScore);

        final newScores = {'creativity': 95.0, 'technical': 85.0};

        // Act
        final result = await judgingService.scoreSubmission(
          submissionId: 'submission_123',
          judgeId: 'judge_456',
          eventId: 'event_456',
          scores: newScores,
          comments: 'Updated comment',
        );

        // Assert
        expect(result, isA<Score>());
        verify(mockSubmissionRepository.getById('submission_123')).called(1);
        verify(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456')).called(1);
        verify(mockScoreRepository.update(any)).called(1);
      });

      test('should throw exception when submission not found', () async {
        // Arrange
        when(mockSubmissionRepository.getById('submission_123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => judgingService.scoreSubmission(
            submissionId: 'submission_123',
            judgeId: 'judge_456',
            eventId: 'event_456',
            scores: {'creativity': 85.0},
          ),
          throwsException,
        );
      });

      test('should calculate total score with rubric', () async {
        // Arrange
        when(mockSubmissionRepository.getById('submission_123'))
            .thenAnswer((_) async => testSubmission);
        when(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456'))
            .thenAnswer((_) async => null);
        when(mockScoreRepository.create(any))
            .thenAnswer((invocation) async {
              final score = invocation.positionalArguments[0] as Score;
              // Verify total score was calculated
              expect(score.totalScore, isNotNull);
              expect(score.totalScore, greaterThan(0));
              return score;
            });

        final scores = {'creativity': 80.0, 'technical': 90.0};

        // Act
        await judgingService.scoreSubmission(
          submissionId: 'submission_123',
          judgeId: 'judge_456',
          eventId: 'event_456',
          scores: scores,
          rubric: testRubric,
        );

        // Assert
        verify(mockScoreRepository.create(any)).called(1);
      });
    });

    group('Score Retrieval', () {
      test('should get submission scores', () async {
        // Arrange
        final scores = [testScore];
        when(mockScoreRepository.getBySubmissionId('submission_123'))
            .thenAnswer((_) async => scores);

        // Act
        final result = await judgingService.getSubmissionScores('submission_123');

        // Assert
        expect(result, equals(scores));
        verify(mockScoreRepository.getBySubmissionId('submission_123')).called(1);
      });

      test('should get judge score', () async {
        // Arrange
        when(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456'))
            .thenAnswer((_) async => testScore);

        // Act
        final result = await judgingService.getJudgeScore('submission_123', 'judge_456');

        // Assert
        expect(result, equals(testScore));
        verify(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456')).called(1);
      });
    });

    group('Judge Comments', () {
      test('should add comment to existing score', () async {
        // Arrange
        when(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456'))
            .thenAnswer((_) async => testScore);
        when(mockScoreRepository.update(any))
            .thenAnswer((_) async => testScore);

        // Act
        await judgingService.addJudgeComment(
          submissionId: 'submission_123',
          judgeId: 'judge_456',
          eventId: 'event_456',
          comment: 'New comment',
        );

        // Assert
        verify(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456')).called(1);
        verify(mockScoreRepository.update(any)).called(1);
      });

      test('should create new score with comment when none exists', () async {
        // Arrange
        when(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456'))
            .thenAnswer((_) async => null);
        when(mockScoreRepository.create(any))
            .thenAnswer((_) async => testScore);

        // Act
        await judgingService.addJudgeComment(
          submissionId: 'submission_123',
          judgeId: 'judge_456',
          eventId: 'event_456',
          comment: 'New comment',
        );

        // Assert
        verify(mockScoreRepository.getBySubmissionAndJudge('submission_123', 'judge_456')).called(1);
        verify(mockScoreRepository.create(any)).called(1);
      });
    });

    group('Score Aggregation', () {
      test('should calculate submission aggregation with multiple scores', () async {
        // Arrange
        final scores = [
          testScore,
          testScore.copyWith(
            id: 'score_124',
            judgeId: 'judge_457',
            totalScore: 92.0,
          ),
          testScore.copyWith(
            id: 'score_125',
            judgeId: 'judge_458',
            totalScore: 86.0,
          ),
        ];
        when(mockScoreRepository.getBySubmissionId('submission_123'))
            .thenAnswer((_) async => scores);

        // Act
        final result = await judgingService.calculateSubmissionAggregation('submission_123');

        // Assert
        expect(result.submissionId, equals('submission_123'));
        expect(result.judgeCount, equals(3));
        expect(result.averageScore, closeTo(88.67, 0.1)); // (88 + 92 + 86) / 3
        expect(result.totalScore, closeTo(266.0, 0.1)); // 88 + 92 + 86
        expect(result.scoreRange.min, equals(86.0));
        expect(result.scoreRange.max, equals(92.0));
        expect(result.individualScores, hasLength(3));
      });

      test('should handle empty scores in aggregation', () async {
        // Arrange
        when(mockScoreRepository.getBySubmissionId('submission_123'))
            .thenAnswer((_) async => []);

        // Act
        final result = await judgingService.calculateSubmissionAggregation('submission_123');

        // Assert
        expect(result.submissionId, equals('submission_123'));
        expect(result.judgeCount, equals(0));
        expect(result.averageScore, equals(0.0));
        expect(result.totalScore, equals(0.0));
        expect(result.scoreRange.min, equals(0.0));
        expect(result.scoreRange.max, equals(0.0));
      });

      test('should calculate criteria averages', () async {
        // Arrange
        final scores = [
          testScore, // creativity: 85, technical: 90
          testScore.copyWith(
            id: 'score_124',
            judgeId: 'judge_457',
            scores: {'creativity': 75.0, 'technical': 80.0},
          ),
        ];
        when(mockScoreRepository.getBySubmissionId('submission_123'))
            .thenAnswer((_) async => scores);

        // Act
        final result = await judgingService.calculateSubmissionAggregation('submission_123');

        // Assert
        expect(result.criteriaAverages['creativity'], closeTo(80.0, 0.1)); // (85 + 75) / 2
        expect(result.criteriaAverages['technical'], closeTo(85.0, 0.1)); // (90 + 80) / 2
      });
    });

    group('Leaderboard Calculation', () {
      test('should calculate leaderboard with multiple teams', () async {
        // Arrange
        final submissions = [
          testSubmission,
          testSubmission.copyWith(
            id: 'submission_124',
            teamId: 'team_790',
          ),
        ];
        final scoresBySubmission = {
          'submission_123': [testScore], // Team 789: 88.0
          'submission_124': [
            testScore.copyWith(
              id: 'score_124',
              submissionId: 'submission_124',
              totalScore: 95.0,
            )
          ], // Team 790: 95.0
        };

        when(mockSubmissionRepository.getByEventId('event_456'))
            .thenAnswer((_) async => submissions);
        when(mockScoreRepository.getBySubmissionIds(['submission_123', 'submission_124']))
            .thenAnswer((_) async => scoresBySubmission);
        when(mockTeamRepository.getById('team_789'))
            .thenAnswer((_) async => testTeam);
        when(mockTeamRepository.getById('team_790'))
            .thenAnswer((_) async => testTeam.copyWith(id: 'team_790', name: 'Team B'));

        // Act
        final result = await judgingService.calculateLeaderboard('event_456');

        // Assert
        expect(result.eventId, equals('event_456'));
        expect(result.entries, hasLength(2));
        
        // Check ranking (Team 790 should be first with 95.0)
        final firstPlace = result.entries.firstWhere((e) => e.position == 1);
        final secondPlace = result.entries.firstWhere((e) => e.position == 2);
        
        expect(firstPlace.teamId, equals('team_790'));
        expect(firstPlace.averageScore, equals(95.0));
        expect(secondPlace.teamId, equals('team_789'));
        expect(secondPlace.averageScore, equals(88.0));
      });

      test('should handle empty submissions in leaderboard', () async {
        // Arrange
        when(mockSubmissionRepository.getByEventId('event_456'))
            .thenAnswer((_) async => []);

        // Act
        final result = await judgingService.calculateLeaderboard('event_456');

        // Assert
        expect(result.eventId, equals('event_456'));
        expect(result.entries, isEmpty);
      });

      test('should only include submitted/approved submissions', () async {
        // Arrange
        final submissions = [
          testSubmission, // submitted
          testSubmission.copyWith(
            id: 'submission_draft',
            status: SubmissionStatus.draft,
          ), // draft - should be excluded
          testSubmission.copyWith(
            id: 'submission_approved',
            status: SubmissionStatus.approved,
          ), // approved - should be included
        ];

        when(mockSubmissionRepository.getByEventId('event_456'))
            .thenAnswer((_) async => submissions);
        when(mockScoreRepository.getBySubmissionIds(['submission_123', 'submission_approved']))
            .thenAnswer((_) async => {
              'submission_123': [testScore],
              'submission_approved': [testScore.copyWith(id: 'score_approved', submissionId: 'submission_approved')],
            });
        when(mockTeamRepository.getById('team_789'))
            .thenAnswer((_) async => testTeam);

        // Act
        final result = await judgingService.calculateLeaderboard('event_456');

        // Assert
        expect(result.entries, hasLength(1)); // Only one team with valid submissions
        expect(result.getMetadata<int>('totalSubmissions'), equals(2)); // Only submitted/approved counted
      });
    });

    group('Scoring Rubric Management', () {
      test('should create scoring rubric', () async {
        // Arrange
        when(mockRubricRepository.create(any))
            .thenAnswer((_) async => testRubric);

        // Act
        final result = await judgingService.createScoringRubric(
          name: 'Test Rubric',
          description: 'Test description',
          criteria: testRubric.criteria,
          eventId: 'event_456',
          createdBy: 'member_123',
        );

        // Assert
        expect(result, isA<ScoringRubric>());
        verify(mockRubricRepository.create(any)).called(1);
      });

      test('should get scoring rubric by ID', () async {
        // Arrange
        when(mockRubricRepository.getById('rubric_123'))
            .thenAnswer((_) async => testRubric);

        // Act
        final result = await judgingService.getScoringRubric('rubric_123');

        // Assert
        expect(result, equals(testRubric));
        verify(mockRubricRepository.getById('rubric_123')).called(1);
      });

      test('should get available rubrics with filters', () async {
        // Arrange
        final rubrics = [testRubric];
        when(mockRubricRepository.getRubricsPaginated(
          eventId: 'event_456',
          groupId: null,
          isTemplate: null,
          limit: 50,
        )).thenAnswer((_) async => rubrics);

        // Act
        final result = await judgingService.getAvailableRubrics(eventId: 'event_456');

        // Assert
        expect(result, equals(rubrics));
        verify(mockRubricRepository.getRubricsPaginated(
          eventId: 'event_456',
          groupId: null,
          isTemplate: null,
          limit: 50,
        )).called(1);
      });

      test('should clone rubric', () async {
        // Arrange
        final clonedRubric = testRubric.copyWith(
          id: 'rubric_cloned',
          name: 'Cloned Rubric',
        );
        when(mockRubricRepository.clone(
          'rubric_123',
          newName: 'Cloned Rubric',
          newEventId: 'event_789',
          newGroupId: null,
          isTemplate: null,
          createdBy: 'member_456',
        )).thenAnswer((_) async => clonedRubric);

        // Act
        final result = await judgingService.cloneRubric(
          rubricId: 'rubric_123',
          createdBy: 'member_456',
          newName: 'Cloned Rubric',
          eventId: 'event_789',
        );

        // Assert
        expect(result, equals(clonedRubric));
        verify(mockRubricRepository.clone(
          'rubric_123',
          newName: 'Cloned Rubric',
          newEventId: 'event_789',
          newGroupId: null,
          isTemplate: null,
          createdBy: 'member_456',
        )).called(1);
      });
    });

    group('Utility Methods', () {
      test('should check if judge has scored', () async {
        // Arrange
        when(mockScoreRepository.hasJudgeScored('submission_123', 'judge_456'))
            .thenAnswer((_) async => true);

        // Act
        final result = await judgingService.hasJudgeScored('submission_123', 'judge_456');

        // Assert
        expect(result, isTrue);
        verify(mockScoreRepository.hasJudgeScored('submission_123', 'judge_456')).called(1);
      });

      test('should get event scoring statistics', () async {
        // Arrange
        final stats = ScoreStatistics(
          eventId: 'event_456',
          totalScores: 10,
          averageScore: 85.5,
          highestScore: 95.0,
          lowestScore: 75.0,
          judgeCount: 3,
          submissionCount: 5,
        );
        when(mockScoreRepository.getEventScoreStatistics('event_456'))
            .thenAnswer((_) async => stats);

        // Act
        final result = await judgingService.getEventScoringStats('event_456');

        // Assert
        expect(result, equals(stats));
        verify(mockScoreRepository.getEventScoreStatistics('event_456')).called(1);
      });

      test('should validate score against rubric', () {
        // Valid scores
        final validScores = {'creativity': 85.0, 'technical': 90.0};
        expect(judgingService.validateScoreAgainstRubric(validScores, testRubric), isTrue);

        // Missing required criterion
        final missingScores = {'creativity': 85.0}; // Missing technical
        expect(judgingService.validateScoreAgainstRubric(missingScores, testRubric), isFalse);

        // Invalid score value
        final invalidScores = {'creativity': 150.0, 'technical': 90.0}; // creativity > maxScore
        expect(judgingService.validateScoreAgainstRubric(invalidScores, testRubric), isFalse);
      });
    });
  });
}