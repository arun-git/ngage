import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/score_repository.dart';

import 'score_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
])
void main() {
  group('ScoreRepository Tests', () {
    late ScoreRepository scoreRepository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;

    late Score testScore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();

      scoreRepository = ScoreRepository(firestore: mockFirestore);

      testScore = Score(
        id: 'score_123',
        submissionId: 'submission_456',
        judgeId: 'judge_789',
        eventId: 'event_101',
        scores: {'creativity': 85.0, 'technical': 90.0},
        comments: 'Great work!',
        totalScore: 87.5,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 1, 10, 30),
      );

      // Setup basic mocks
      when(mockFirestore.collection('scores')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocRef);
    });

    group('Create Operations', () {
      test('should create score successfully', () async {
        // Arrange
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await scoreRepository.create(testScore);

        // Assert
        expect(result, equals(testScore));
        verify(mockCollection.doc(testScore.id)).called(1);
        verify(mockDocRef.set(testScore.toJson())).called(1);
      });
    });

    group('Read Operations', () {
      test('should get score by ID when exists', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await scoreRepository.getById('score_123');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('score_123'));
        verify(mockCollection.doc('score_123')).called(1);
        verify(mockDocRef.get()).called(1);
      });

      test('should return null when score does not exist', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await scoreRepository.getById('nonexistent');

        // Assert
        expect(result, isNull);
        verify(mockCollection.doc('nonexistent')).called(1);
        verify(mockDocRef.get()).called(1);
      });

      test('should get scores by submission ID', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getBySubmissionId('submission_456');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.submissionId, equals('submission_456'));
        verify(mockCollection.where('submissionId', isEqualTo: 'submission_456')).called(1);
        verify(mockQuery.orderBy('createdAt', descending: true)).called(1);
        verify(mockQuery.get()).called(1);
      });

      test('should get scores by judge ID', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('judgeId', isEqualTo: 'judge_789'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getByJudgeId('judge_789');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.judgeId, equals('judge_789'));
        verify(mockCollection.where('judgeId', isEqualTo: 'judge_789')).called(1);
      });

      test('should get scores by judge ID with event filter', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('judgeId', isEqualTo: 'judge_789'))
            .thenReturn(mockQuery);
        when(mockQuery.where('eventId', isEqualTo: 'event_101'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getByJudgeId('judge_789', eventId: 'event_101');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.judgeId, equals('judge_789'));
        expect(result.first.eventId, equals('event_101'));
        verify(mockQuery.where('eventId', isEqualTo: 'event_101')).called(1);
      });

      test('should get scores by event ID', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('eventId', isEqualTo: 'event_101'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getByEventId('event_101');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.eventId, equals('event_101'));
        verify(mockCollection.where('eventId', isEqualTo: 'event_101')).called(1);
      });

      test('should get score by submission and judge', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.where('judgeId', isEqualTo: 'judge_789'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getBySubmissionAndJudge('submission_456', 'judge_789');

        // Assert
        expect(result, isNotNull);
        expect(result!.submissionId, equals('submission_456'));
        expect(result.judgeId, equals('judge_789'));
        verify(mockQuery.limit(1)).called(1);
      });

      test('should return null when no score found by submission and judge', () async {
        // Arrange
        when(mockQuerySnapshot.docs).thenReturn([]);
        
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.where('judgeId', isEqualTo: 'judge_789'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getBySubmissionAndJudge('submission_456', 'judge_789');

        // Assert
        expect(result, isNull);
      });
    });

    group('Update Operations', () {
      test('should update score successfully', () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await scoreRepository.update(testScore);

        // Assert
        expect(result.updatedAt.isAfter(testScore.updatedAt), isTrue);
        verify(mockCollection.doc(testScore.id)).called(1);
        verify(mockDocRef.update(any)).called(1);
      });
    });

    group('Delete Operations', () {
      test('should delete score successfully', () async {
        // Arrange
        when(mockDocRef.delete()).thenAnswer((_) async => {});

        // Act
        await scoreRepository.delete('score_123');

        // Assert
        verify(mockCollection.doc('score_123')).called(1);
        verify(mockDocRef.delete()).called(1);
      });

      test('should delete scores by submission ID', () async {
        // Arrange
        final mockBatch = MockWriteBatch();
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async => []);
        
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        await scoreRepository.deleteBySubmissionId('submission_456');

        // Assert
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(any)).called(1);
        verify(mockBatch.commit()).called(1);
      });
    });

    group('Batch Operations', () {
      test('should get scores by multiple submission IDs', () async {
        // Arrange
        final submissionIds = ['submission_1', 'submission_2'];
        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
        final score1 = testScore.copyWith(id: 'score_1', submissionId: 'submission_1');
        final score2 = testScore.copyWith(id: 'score_2', submissionId: 'submission_2');
        
        when(mockQueryDocSnapshot1.data()).thenReturn(score1.toJson());
        when(mockQueryDocSnapshot2.data()).thenReturn(score2.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot1, mockQueryDocSnapshot2]);
        
        when(mockCollection.where('submissionId', whereIn: submissionIds))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getBySubmissionIds(submissionIds);

        // Assert
        expect(result, hasLength(2));
        expect(result['submission_1'], hasLength(1));
        expect(result['submission_2'], hasLength(1));
        expect(result['submission_1']!.first.id, equals('score_1'));
        expect(result['submission_2']!.first.id, equals('score_2'));
      });

      test('should handle large submission ID lists in batches', () async {
        // Arrange - Create 15 submission IDs (more than Firestore's 10 limit)
        final submissionIds = List.generate(15, (i) => 'submission_$i');
        
        // Mock first batch (10 items)
        final mockQuerySnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
        when(mockQuerySnapshot1.docs).thenReturn([]);
        
        // Mock second batch (5 items)
        final mockQuerySnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
        when(mockQuerySnapshot2.docs).thenReturn([]);
        
        when(mockCollection.where('submissionId', whereIn: submissionIds.take(10).toList()))
            .thenReturn(mockQuery);
        when(mockCollection.where('submissionId', whereIn: submissionIds.skip(10).take(10).toList()))
            .thenReturn(mockQuery);
        
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot1)
            .thenAnswer((_) async => mockQuerySnapshot2);

        // Act
        final result = await scoreRepository.getBySubmissionIds(submissionIds);

        // Assert
        expect(result, hasLength(15));
        verify(mockQuery.get()).called(2); // Two batches
      });
    });

    group('Statistics', () {
      test('should get average score for submission', () async {
        // Arrange
        final scores = [
          testScore.copyWith(totalScore: 80.0),
          testScore.copyWith(id: 'score_2', totalScore: 90.0),
          testScore.copyWith(id: 'score_3', totalScore: 85.0),
        ];
        final mockQueryDocSnapshots = scores.map((score) {
          final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.data()).thenReturn(score.toJson());
          return mockDoc;
        }).toList();
        
        when(mockQuerySnapshot.docs).thenReturn(mockQueryDocSnapshots);
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getAverageScore('submission_456');

        // Assert
        expect(result, closeTo(85.0, 0.1)); // (80 + 90 + 85) / 3
      });

      test('should return null for average when no scores exist', () async {
        // Arrange
        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getAverageScore('submission_456');

        // Assert
        expect(result, isNull);
      });

      test('should get event score statistics', () async {
        // Arrange
        final scores = [
          testScore.copyWith(totalScore: 80.0, judgeId: 'judge_1', submissionId: 'sub_1'),
          testScore.copyWith(id: 'score_2', totalScore: 90.0, judgeId: 'judge_2', submissionId: 'sub_1'),
          testScore.copyWith(id: 'score_3', totalScore: 85.0, judgeId: 'judge_1', submissionId: 'sub_2'),
        ];
        final mockQueryDocSnapshots = scores.map((score) {
          final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.data()).thenReturn(score.toJson());
          return mockDoc;
        }).toList();
        
        when(mockQuerySnapshot.docs).thenReturn(mockQueryDocSnapshots);
        when(mockCollection.where('eventId', isEqualTo: 'event_101'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getEventScoreStatistics('event_101');

        // Assert
        expect(result.eventId, equals('event_101'));
        expect(result.totalScores, equals(3));
        expect(result.averageScore, closeTo(85.0, 0.1)); // (80 + 90 + 85) / 3
        expect(result.highestScore, equals(90.0));
        expect(result.lowestScore, equals(80.0));
        expect(result.judgeCount, equals(2)); // judge_1 and judge_2
        expect(result.submissionCount, equals(2)); // sub_1 and sub_2
      });
    });

    group('Utility Methods', () {
      test('should check if judge has scored', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.where('judgeId', isEqualTo: 'judge_789'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.hasJudgeScored('submission_456', 'judge_789');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when judge has not scored', () async {
        // Arrange
        when(mockQuerySnapshot.docs).thenReturn([]);
        
        when(mockCollection.where('submissionId', isEqualTo: 'submission_456'))
            .thenReturn(mockQuery);
        when(mockQuery.where('judgeId', isEqualTo: 'judge_789'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.hasJudgeScored('submission_456', 'judge_789');

        // Assert
        expect(result, isFalse);
      });

      test('should get incomplete scores', () async {
        // Arrange
        final incompleteScore = testScore.copyWith(totalScore: null);
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(incompleteScore.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('eventId', isEqualTo: 'event_101'))
            .thenReturn(mockQuery);
        when(mockQuery.where('totalScore', isNull: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await scoreRepository.getIncompleteScores('event_101');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.totalScore, isNull);
      });
    });
  });
}

// Additional mock classes needed for Firestore operations
class MockQueryDocumentSnapshot<T> extends Mock implements QueryDocumentSnapshot<T> {}
class MockWriteBatch extends Mock implements WriteBatch {}