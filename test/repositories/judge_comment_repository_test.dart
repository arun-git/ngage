import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/judge_comment_repository.dart';

import 'judge_comment_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  AggregateQuery,
  AggregateQuerySnapshot,
])
void main() {
  group('JudgeCommentRepository', () {
    late JudgeCommentRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();

      repository = JudgeCommentRepository(firestore: mockFirestore);

      when(mockFirestore.collection('judge_comments')).thenReturn(mockCollection);
    });

    group('create', () {
      test('should create judge comment successfully', () async {
        // Arrange
        final comment = JudgeComment(
          id: 'comment_1',
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: 'judge_1',
          content: 'Test comment',
          type: JudgeCommentType.general,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCollection.doc(comment.id)).thenReturn(mockDocRef);
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.create(comment);

        // Assert
        expect(result, equals(comment));
        verify(mockCollection.doc(comment.id)).called(1);
        verify(mockDocRef.set(comment.toJson())).called(1);
      });
    });

    group('getById', () {
      test('should return comment when document exists', () async {
        // Arrange
        const commentId = 'comment_1';
        final commentData = {
          'submissionId': 'submission_1',
          'eventId': 'event_1',
          'judgeId': 'judge_1',
          'content': 'Test comment',
          'type': 'general',
          'parentCommentId': null,
          'isPrivate': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockCollection.doc(commentId)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.id).thenReturn(commentId);
        when(mockDocSnapshot.data()).thenReturn(commentData);

        // Act
        final result = await repository.getById(commentId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(commentId));
        expect(result.submissionId, equals('submission_1'));
        verify(mockCollection.doc(commentId)).called(1);
        verify(mockDocRef.get()).called(1);
      });

      test('should return null when document does not exist', () async {
        // Arrange
        const commentId = 'comment_1';

        when(mockCollection.doc(commentId)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.getById(commentId);

        // Assert
        expect(result, isNull);
        verify(mockCollection.doc(commentId)).called(1);
        verify(mockDocRef.get()).called(1);
      });
    });

    group('getBySubmissionId', () {
      test('should return comments for submission', () async {
        // Arrange
        const submissionId = 'submission_1';
        final commentsData = [
          {
            'submissionId': submissionId,
            'eventId': 'event_1',
            'judgeId': 'judge_1',
            'content': 'First comment',
            'type': 'general',
            'parentCommentId': null,
            'isPrivate': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'submissionId': submissionId,
            'eventId': 'event_1',
            'judgeId': 'judge_2',
            'content': 'Second comment',
            'type': 'question',
            'parentCommentId': null,
            'isPrivate': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        final mockDocs = commentsData.asMap().entries.map((entry) {
          final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.id).thenReturn('comment_${entry.key + 1}');
          when(mockDoc.data()).thenReturn(entry.value);
          return mockDoc;
        }).toList();

        when(mockCollection.where('submissionId', isEqualTo: submissionId))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: false))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.getBySubmissionId(submissionId);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].submissionId, equals(submissionId));
        expect(result[1].submissionId, equals(submissionId));
        verify(mockCollection.where('submissionId', isEqualTo: submissionId)).called(1);
      });
    });

    group('getTopLevelComments', () {
      test('should return only top-level comments', () async {
        // Arrange
        const submissionId = 'submission_1';
        final commentsData = [
          {
            'submissionId': submissionId,
            'eventId': 'event_1',
            'judgeId': 'judge_1',
            'content': 'Top level comment',
            'type': 'general',
            'parentCommentId': null,
            'isPrivate': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        final mockDocs = commentsData.asMap().entries.map((entry) {
          final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.id).thenReturn('comment_${entry.key + 1}');
          when(mockDoc.data()).thenReturn(entry.value);
          return mockDoc;
        }).toList();

        when(mockCollection.where('submissionId', isEqualTo: submissionId))
            .thenReturn(mockQuery);
        when(mockQuery.where('parentCommentId', isNull: true))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: false))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.getTopLevelComments(submissionId);

        // Assert
        expect(result.length, equals(1));
        expect(result[0].parentCommentId, isNull);
        verify(mockCollection.where('submissionId', isEqualTo: submissionId)).called(1);
        verify(mockQuery.where('parentCommentId', isNull: true)).called(1);
      });
    });

    group('getReplies', () {
      test('should return replies to parent comment', () async {
        // Arrange
        const parentCommentId = 'parent_1';
        final repliesData = [
          {
            'submissionId': 'submission_1',
            'eventId': 'event_1',
            'judgeId': 'judge_2',
            'content': 'Reply to parent',
            'type': 'general',
            'parentCommentId': parentCommentId,
            'isPrivate': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        final mockDocs = repliesData.asMap().entries.map((entry) {
          final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.id).thenReturn('reply_${entry.key + 1}');
          when(mockDoc.data()).thenReturn(entry.value);
          return mockDoc;
        }).toList();

        when(mockCollection.where('parentCommentId', isEqualTo: parentCommentId))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: false))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.getReplies(parentCommentId);

        // Assert
        expect(result.length, equals(1));
        expect(result[0].parentCommentId, equals(parentCommentId));
        verify(mockCollection.where('parentCommentId', isEqualTo: parentCommentId)).called(1);
      });
    });

    group('update', () {
      test('should update comment successfully', () async {
        // Arrange
        final comment = JudgeComment(
          id: 'comment_1',
          submissionId: 'submission_1',
          eventId: 'event_1',
          judgeId: 'judge_1',
          content: 'Updated comment',
          type: JudgeCommentType.suggestion,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCollection.doc(comment.id)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.update(comment);

        // Assert
        expect(result, equals(comment));
        verify(mockCollection.doc(comment.id)).called(1);
        verify(mockDocRef.update(comment.toJson())).called(1);
      });
    });

    group('delete', () {
      test('should delete comment successfully', () async {
        // Arrange
        const commentId = 'comment_1';

        when(mockCollection.doc(commentId)).thenReturn(mockDocRef);
        when(mockDocRef.delete()).thenAnswer((_) async => {});

        // Act
        await repository.delete(commentId);

        // Assert
        verify(mockCollection.doc(commentId)).called(1);
        verify(mockDocRef.delete()).called(1);
      });
    });

    group('hasJudgeCommented', () {
      test('should return true when judge has commented', () async {
        // Arrange
        const submissionId = 'submission_1';
        const judgeId = 'judge_1';

        final mockDocs = [MockDocumentSnapshot<Map<String, dynamic>>()];

        when(mockCollection.where('submissionId', isEqualTo: submissionId))
            .thenReturn(mockQuery);
        when(mockQuery.where('judgeId', isEqualTo: judgeId))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await repository.hasJudgeCommented(submissionId, judgeId);

        // Assert
        expect(result, isTrue);
        verify(mockCollection.where('submissionId', isEqualTo: submissionId)).called(1);
        verify(mockQuery.where('judgeId', isEqualTo: judgeId)).called(1);
      });

      test('should return false when judge has not commented', () async {
        // Arrange
        const submissionId = 'submission_1';
        const judgeId = 'judge_1';

        when(mockCollection.where('submissionId', isEqualTo: submissionId))
            .thenReturn(mockQuery);
        when(mockQuery.where('judgeId', isEqualTo: judgeId))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await repository.hasJudgeCommented(submissionId, judgeId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getCommentCount', () {
      test('should return comment count for submission', () async {
        // Arrange
        const submissionId = 'submission_1';
        const expectedCount = 5;

        final mockAggregateQuery = MockAggregateQuery();
        final mockAggregateSnapshot = MockAggregateQuerySnapshot();

        when(mockCollection.where('submissionId', isEqualTo: submissionId))
            .thenReturn(mockQuery);
        when(mockQuery.count()).thenReturn(mockAggregateQuery);
        when(mockAggregateQuery.get()).thenAnswer((_) async => mockAggregateSnapshot);
        when(mockAggregateSnapshot.count).thenReturn(expectedCount);

        // Act
        final result = await repository.getCommentCount(submissionId);

        // Assert
        expect(result, equals(expectedCount));
        verify(mockCollection.where('submissionId', isEqualTo: submissionId)).called(1);
        verify(mockQuery.count()).called(1);
      });

      test('should return 0 when count is null', () async {
        // Arrange
        const submissionId = 'submission_1';

        final mockAggregateQuery = MockAggregateQuery();
        final mockAggregateSnapshot = MockAggregateQuerySnapshot();

        when(mockCollection.where('submissionId', isEqualTo: submissionId))
            .thenReturn(mockQuery);
        when(mockQuery.count()).thenReturn(mockAggregateQuery);
        when(mockAggregateQuery.get()).thenAnswer((_) async => mockAggregateSnapshot);
        when(mockAggregateSnapshot.count).thenReturn(null);

        // Act
        final result = await repository.getCommentCount(submissionId);

        // Assert
        expect(result, equals(0));
      });
    });
  });
}