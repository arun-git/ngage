import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/models.dart';

void main() {
  group('Score Model Tests', () {
    late Score testScore;
    late ScoringRubric testRubric;

    setUp(() {
      testScore = Score(
        id: 'score_123',
        submissionId: 'submission_456',
        judgeId: 'judge_789',
        eventId: 'event_101',
        scores: {
          'creativity': 85.0,
          'technical': 90.0,
          'presentation': 75.0,
        },
        comments: 'Great work overall!',
        totalScore: 83.3,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 1, 10, 30),
      );

      testRubric = ScoringRubric(
        id: 'rubric_123',
        name: 'Test Rubric',
        description: 'Test scoring rubric',
        criteria: [
          const ScoringCriterion(
            key: 'creativity',
            name: 'Creativity',
            description: 'Creative aspects',
            maxScore: 100.0,
            weight: 0.3,
          ),
          const ScoringCriterion(
            key: 'technical',
            name: 'Technical',
            description: 'Technical implementation',
            maxScore: 100.0,
            weight: 0.4,
          ),
          const ScoringCriterion(
            key: 'presentation',
            name: 'Presentation',
            description: 'Presentation quality',
            maxScore: 100.0,
            weight: 0.3,
          ),
        ],
        createdBy: 'member_123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    group('Constructor and Properties', () {
      test('should create Score with all properties', () {
        expect(testScore.id, equals('score_123'));
        expect(testScore.submissionId, equals('submission_456'));
        expect(testScore.judgeId, equals('judge_789'));
        expect(testScore.eventId, equals('event_101'));
        expect(testScore.scores, isA<Map<String, dynamic>>());
        expect(testScore.comments, equals('Great work overall!'));
        expect(testScore.totalScore, equals(83.3));
        expect(testScore.createdAt, equals(DateTime(2024, 1, 1, 10, 0)));
        expect(testScore.updatedAt, equals(DateTime(2024, 1, 1, 10, 30)));
      });

      test('should create Score with minimal properties', () {
        final minimalScore = Score(
          id: 'score_min',
          submissionId: 'submission_min',
          judgeId: 'judge_min',
          eventId: 'event_min',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(minimalScore.scores, isEmpty);
        expect(minimalScore.comments, isNull);
        expect(minimalScore.totalScore, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testScore.toJson();

        expect(json['id'], equals('score_123'));
        expect(json['submissionId'], equals('submission_456'));
        expect(json['judgeId'], equals('judge_789'));
        expect(json['eventId'], equals('event_101'));
        expect(json['scores'], isA<Map<String, dynamic>>());
        expect(json['comments'], equals('Great work overall!'));
        expect(json['totalScore'], equals(83.3));
        expect(json['createdAt'], equals('2024-01-01T10:00:00.000'));
        expect(json['updatedAt'], equals('2024-01-01T10:30:00.000'));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'score_json',
          'submissionId': 'submission_json',
          'judgeId': 'judge_json',
          'eventId': 'event_json',
          'scores': {'creativity': 80.0, 'technical': 85.0},
          'comments': 'JSON test comment',
          'totalScore': 82.5,
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-01T10:30:00.000',
        };

        final score = Score.fromJson(json);

        expect(score.id, equals('score_json'));
        expect(score.submissionId, equals('submission_json'));
        expect(score.judgeId, equals('judge_json'));
        expect(score.eventId, equals('event_json'));
        expect(score.scores['creativity'], equals(80.0));
        expect(score.scores['technical'], equals(85.0));
        expect(score.comments, equals('JSON test comment'));
        expect(score.totalScore, equals(82.5));
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'score_null',
          'submissionId': 'submission_null',
          'judgeId': 'judge_null',
          'eventId': 'event_null',
          'scores': null,
          'comments': null,
          'totalScore': null,
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-01T10:30:00.000',
        };

        final score = Score.fromJson(json);

        expect(score.scores, isEmpty);
        expect(score.comments, isNull);
        expect(score.totalScore, isNull);
      });
    });

    group('Score Operations', () {
      test('should get specific score value', () {
        expect(testScore.getScore<double>('creativity'), equals(85.0));
        expect(testScore.getScore<double>('technical'), equals(90.0));
        expect(testScore.getScore<double>('nonexistent'), isNull);
        expect(testScore.getScore<double>('nonexistent', 50.0), equals(50.0));
      });

      test('should get numeric score value', () {
        expect(testScore.getNumericScore('creativity'), equals(85.0));
        expect(testScore.getNumericScore('technical'), equals(90.0));
        expect(testScore.getNumericScore('nonexistent'), isNull);
      });

      test('should update score criterion', () {
        final updatedScore = testScore.updateScore('creativity', 95.0);

        expect(updatedScore.getNumericScore('creativity'), equals(95.0));
        expect(updatedScore.getNumericScore('technical'), equals(90.0)); // Unchanged
        expect(testScore.getNumericScore('creativity'), equals(85.0)); // Original unchanged
      });

      test('should remove score criterion', () {
        final updatedScore = testScore.removeScore('creativity');

        expect(updatedScore.getNumericScore('creativity'), isNull);
        expect(updatedScore.getNumericScore('technical'), equals(90.0)); // Unchanged
        expect(testScore.getNumericScore('creativity'), equals(85.0)); // Original unchanged
      });
    });

    group('Total Score Calculation', () {
      test('should calculate total score with rubric', () {
        final scoreWithoutTotal = testScore.copyWith(totalScore: null);
        final calculatedScore = scoreWithoutTotal.calculateTotalScore(testRubric);

        // Expected: (85 * 0.3) + (90 * 0.4) + (75 * 0.3) = 25.5 + 36 + 22.5 = 84.0
        expect(calculatedScore.totalScore, closeTo(84.0, 0.1));
      });

      test('should handle missing criteria in score calculation', () {
        final partialScore = Score(
          id: 'partial',
          submissionId: 'sub',
          judgeId: 'judge',
          eventId: 'event',
          scores: {'creativity': 80.0}, // Missing technical and presentation
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final calculatedScore = partialScore.calculateTotalScore(testRubric);

        // Only creativity scored: (80 * 0.3) / 0.3 * 100 = 80.0
        expect(calculatedScore.totalScore, closeTo(80.0, 0.1));
      });

      test('should handle empty scores in calculation', () {
        final emptyScore = Score(
          id: 'empty',
          submissionId: 'sub',
          judgeId: 'judge',
          eventId: 'event',
          scores: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final calculatedScore = emptyScore.calculateTotalScore(testRubric);

        expect(calculatedScore.totalScore, equals(0.0));
      });
    });

    group('Completion Checking', () {
      test('should check if score is complete with all required criteria', () {
        expect(testScore.isComplete(testRubric), isTrue);
      });

      test('should check if score is incomplete with missing required criteria', () {
        final incompleteScore = testScore.removeScore('creativity');
        expect(incompleteScore.isComplete(testRubric), isFalse);
      });

      test('should get completion percentage', () {
        expect(testScore.getCompletionPercentage(testRubric), equals(100.0));

        final partialScore = testScore.removeScore('creativity');
        expect(partialScore.getCompletionPercentage(testRubric), closeTo(66.7, 0.1));

        final emptyScore = testScore.copyWith(scores: {});
        expect(emptyScore.getCompletionPercentage(testRubric), equals(0.0));
      });

      test('should handle empty rubric in completion check', () {
        final emptyRubric = testRubric.copyWith(criteria: []);
        expect(testScore.getCompletionPercentage(emptyRubric), equals(100.0));
      });
    });

    group('Validation', () {
      test('should validate valid score', () {
        final result = testScore.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should validate score with invalid total score range', () {
        final invalidScore = testScore.copyWith(totalScore: 150.0);
        final result = invalidScore.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Total score must be between 0 and 100'));
      });

      test('should validate score with negative total score', () {
        final invalidScore = testScore.copyWith(totalScore: -10.0);
        final result = invalidScore.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Total score must be between 0 and 100'));
      });

      test('should validate score with too long comments', () {
        final longComment = 'x' * 2001;
        final invalidScore = testScore.copyWith(comments: longComment);
        final result = invalidScore.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Comments must not exceed 2000 characters'));
      });

      test('should validate individual score ranges', () {
        final invalidScore = testScore.updateScore('creativity', 150.0);
        final result = invalidScore.validate();
        
        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('Score for creativity must be between 0 and 100')), isTrue);
      });

      test('should validate required fields', () {
        final invalidScore = Score(
          id: '',
          submissionId: '',
          judgeId: '',
          eventId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = invalidScore.validate();
        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(0));
      });
    });

    group('Equality and Hashing', () {
      test('should be equal to identical score', () {
        final identicalScore = Score(
          id: 'score_123',
          submissionId: 'submission_456',
          judgeId: 'judge_789',
          eventId: 'event_101',
          scores: {
            'creativity': 85.0,
            'technical': 90.0,
            'presentation': 75.0,
          },
          comments: 'Great work overall!',
          totalScore: 83.3,
          createdAt: DateTime(2024, 1, 1, 10, 0),
          updatedAt: DateTime(2024, 1, 1, 10, 30),
        );

        expect(testScore, equals(identicalScore));
        expect(testScore.hashCode, equals(identicalScore.hashCode));
      });

      test('should not be equal to different score', () {
        final differentScore = testScore.copyWith(totalScore: 90.0);

        expect(testScore, isNot(equals(differentScore)));
      });
    });

    group('CopyWith', () {
      test('should copy with updated fields', () {
        final updatedScore = testScore.copyWith(
          totalScore: 90.0,
          comments: 'Updated comment',
        );

        expect(updatedScore.totalScore, equals(90.0));
        expect(updatedScore.comments, equals('Updated comment'));
        expect(updatedScore.id, equals(testScore.id)); // Unchanged
        expect(updatedScore.submissionId, equals(testScore.submissionId)); // Unchanged
      });

      test('should copy without changes when no parameters provided', () {
        final copiedScore = testScore.copyWith();

        expect(copiedScore, equals(testScore));
        expect(identical(copiedScore, testScore), isFalse); // Different instances
      });
    });
  });
}