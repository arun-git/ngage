import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/models.dart';
import '../../lib/repositories/scoring_rubric_repository.dart';

import 'scoring_rubric_repository_test.mocks.dart';

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
  group('ScoringRubricRepository Tests', () {
    late ScoringRubricRepository rubricRepository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockAggregateQuery mockAggregateQuery;
    late MockAggregateQuerySnapshot mockAggregateSnapshot;

    late ScoringRubric testRubric;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockAggregateQuery = MockAggregateQuery();
      mockAggregateSnapshot = MockAggregateQuerySnapshot();

      rubricRepository = ScoringRubricRepository(firestore: mockFirestore);

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
        eventId: 'event_456',
        groupId: 'group_789',
        isTemplate: false,
        createdBy: 'member_101',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 1, 10, 30),
      );

      // Setup basic mocks
      when(mockFirestore.collection('scoring_rubrics')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocRef);
    });

    group('Create Operations', () {
      test('should create rubric successfully', () async {
        // Arrange
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await rubricRepository.create(testRubric);

        // Assert
        expect(result, equals(testRubric));
        verify(mockCollection.doc(testRubric.id)).called(1);
        verify(mockDocRef.set(testRubric.toJson())).called(1);
      });
    });

    group('Read Operations', () {
      test('should get rubric by ID when exists', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await rubricRepository.getById('rubric_123');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('rubric_123'));
        verify(mockCollection.doc('rubric_123')).called(1);
        verify(mockDocRef.get()).called(1);
      });

      test('should return null when rubric does not exist', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await rubricRepository.getById('nonexistent');

        // Assert
        expect(result, isNull);
        verify(mockCollection.doc('nonexistent')).called(1);
        verify(mockDocRef.get()).called(1);
      });

      test('should get rubrics by event ID', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('eventId', isEqualTo: 'event_456'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.getByEventId('event_456');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.eventId, equals('event_456'));
        verify(mockCollection.where('eventId', isEqualTo: 'event_456')).called(1);
        verify(mockQuery.orderBy('createdAt', descending: true)).called(1);
        verify(mockQuery.get()).called(1);
      });

      test('should get rubrics by group ID', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('groupId', isEqualTo: 'group_789'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.getByGroupId('group_789');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.groupId, equals('group_789'));
        verify(mockCollection.where('groupId', isEqualTo: 'group_789')).called(1);
      });

      test('should get template rubrics', () async {
        // Arrange
        final templateRubric = testRubric.copyWith(isTemplate: true);
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(templateRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('isTemplate', isEqualTo: true))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.getTemplates();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.isTemplate, isTrue);
        verify(mockCollection.where('isTemplate', isEqualTo: true)).called(1);
      });

      test('should get rubrics by creator', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('createdBy', isEqualTo: 'member_101'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.getByCreator('member_101');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.createdBy, equals('member_101'));
        verify(mockCollection.where('createdBy', isEqualTo: 'member_101')).called(1);
      });

      test('should search rubrics by name', () async {
        // Arrange
        final rubrics = [
          testRubric,
          testRubric.copyWith(id: 'rubric_124', name: 'Another Rubric'),
          testRubric.copyWith(id: 'rubric_125', name: 'Different Name'),
        ];
        final mockQueryDocSnapshots = rubrics.map((rubric) {
          final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.data()).thenReturn(rubric.toJson());
          return mockDoc;
        }).toList();
        
        when(mockQuerySnapshot.docs).thenReturn(mockQueryDocSnapshots);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.searchByName('test');

        // Assert
        expect(result, hasLength(1)); // Only "Test Rubric" should match
        expect(result.first.name, contains('Test'));
      });

      test('should search rubrics by name with group filter', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('groupId', isEqualTo: 'group_789'))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.searchByName('test', groupId: 'group_789');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, contains('Test'));
        verify(mockCollection.where('groupId', isEqualTo: 'group_789')).called(1);
      });
    });

    group('Update Operations', () {
      test('should update rubric successfully', () async {
        // Arrange
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await rubricRepository.update(testRubric);

        // Assert
        expect(result.updatedAt.isAfter(testRubric.updatedAt), isTrue);
        verify(mockCollection.doc(testRubric.id)).called(1);
        verify(mockDocRef.update(any)).called(1);
      });
    });

    group('Delete Operations', () {
      test('should delete rubric successfully', () async {
        // Arrange
        when(mockDocRef.delete()).thenAnswer((_) async => {});

        // Act
        await rubricRepository.delete('rubric_123');

        // Assert
        verify(mockCollection.doc('rubric_123')).called(1);
        verify(mockDocRef.delete()).called(1);
      });

      test('should delete rubrics by event ID', () async {
        // Arrange
        final mockBatch = MockWriteBatch();
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async => []);
        
        when(mockCollection.where('eventId', isEqualTo: 'event_456'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        await rubricRepository.deleteByEventId('event_456');

        // Assert
        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.delete(any)).called(1);
        verify(mockBatch.commit()).called(1);
      });

      test('should delete rubrics by group ID in batches', () async {
        // Arrange - Create 600 rubrics to test batch deletion
        final rubrics = List.generate(600, (i) => testRubric.copyWith(id: 'rubric_$i'));
        final mockQueryDocSnapshots = rubrics.map((rubric) {
          final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockDoc.data()).thenReturn(rubric.toJson());
          return mockDoc;
        }).toList();
        
        final mockBatch = MockWriteBatch();
        when(mockQuerySnapshot.docs).thenReturn(mockQueryDocSnapshots);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async => []);
        
        when(mockCollection.where('groupId', isEqualTo: 'group_789'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        await rubricRepository.deleteByGroupId('group_789');

        // Assert
        verify(mockFirestore.batch()).called(2); // 600 items = 2 batches of 500
        verify(mockBatch.commit()).called(2);
      });
    });

    group('Clone Operations', () {
      test('should clone rubric successfully', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await rubricRepository.clone(
          'rubric_123',
          newName: 'Cloned Rubric',
          createdBy: 'member_456',
        );

        // Assert
        expect(result.name, equals('Cloned Rubric'));
        expect(result.createdBy, equals('member_456'));
        expect(result.id, isNot(equals(testRubric.id))); // Should have new ID
        expect(result.criteria, equals(testRubric.criteria)); // Criteria should be copied
        verify(mockCollection.doc('rubric_123')).called(1);
        verify(mockDocRef.get()).called(1);
        verify(mockDocRef.set(any)).called(1);
      });

      test('should throw exception when cloning non-existent rubric', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(null);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act & Assert
        expect(
          () => rubricRepository.clone('nonexistent', createdBy: 'member_456'),
          throwsException,
        );
      });

      test('should create from template', () async {
        // Arrange
        final templateRubric = testRubric.copyWith(isTemplate: true);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(templateRubric.toJson());
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await rubricRepository.createFromTemplate(
          'template_123',
          name: 'From Template',
          eventId: 'event_789',
          createdBy: 'member_456',
        );

        // Assert
        expect(result.name, equals('From Template'));
        expect(result.eventId, equals('event_789'));
        expect(result.isTemplate, isFalse); // Should not be a template
        expect(result.createdBy, equals('member_456'));
      });
    });

    group('Pagination', () {
      test('should get rubrics with pagination', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.getRubricsPaginated();

        // Assert
        expect(result, hasLength(1));
        verify(mockCollection.orderBy('createdAt', descending: true)).called(1);
        verify(mockQuery.limit(20)).called(1);
      });

      test('should get rubrics with filters and pagination', () async {
        // Arrange
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.data()).thenReturn(testRubric.toJson());
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        
        when(mockCollection.where('eventId', isEqualTo: 'event_456'))
            .thenReturn(mockQuery);
        when(mockQuery.where('isTemplate', isEqualTo: true))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await rubricRepository.getRubricsPaginated(
          eventId: 'event_456',
          isTemplate: true,
          limit: 10,
        );

        // Assert
        expect(result, hasLength(1));
        verify(mockCollection.where('eventId', isEqualTo: 'event_456')).called(1);
        verify(mockQuery.where('isTemplate', isEqualTo: true)).called(1);
        verify(mockQuery.limit(10)).called(1);
      });
    });

    group('Utility Methods', () {
      test('should check if rubric exists', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await rubricRepository.exists('rubric_123');

        // Assert
        expect(result, isTrue);
        verify(mockCollection.doc('rubric_123')).called(1);
        verify(mockDocRef.get()).called(1);
      });

      test('should return false when rubric does not exist', () async {
        // Arrange
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await rubricRepository.exists('nonexistent');

        // Assert
        expect(result, isFalse);
      });

      test('should get group rubric count', () async {
        // Arrange
        when(mockAggregateSnapshot.count).thenReturn(5);
        when(mockAggregateQuery.get()).thenAnswer((_) async => mockAggregateSnapshot);
        when(mockQuery.count()).thenReturn(mockAggregateQuery);
        when(mockCollection.where('groupId', isEqualTo: 'group_789'))
            .thenReturn(mockQuery);

        // Act
        final result = await rubricRepository.getGroupRubricCount('group_789');

        // Assert
        expect(result, equals(5));
        verify(mockCollection.where('groupId', isEqualTo: 'group_789')).called(1);
        verify(mockQuery.count()).called(1);
      });

      test('should get template count', () async {
        // Arrange
        when(mockAggregateSnapshot.count).thenReturn(3);
        when(mockAggregateQuery.get()).thenAnswer((_) async => mockAggregateSnapshot);
        when(mockQuery.count()).thenReturn(mockAggregateQuery);
        when(mockCollection.where('isTemplate', isEqualTo: true))
            .thenReturn(mockQuery);

        // Act
        final result = await rubricRepository.getTemplateCount();

        // Assert
        expect(result, equals(3));
        verify(mockCollection.where('isTemplate', isEqualTo: true)).called(1);
        verify(mockQuery.count()).called(1);
      });

      test('should validate rubric uniqueness', () async {
        // Arrange
        when(mockQuerySnapshot.docs).thenReturn([]); // No existing rubrics
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockCollection.where('name', isEqualTo: 'Test Rubric'))
            .thenReturn(mockQuery);
        when(mockQuery.where('eventId', isEqualTo: 'event_456'))
            .thenReturn(mockQuery);

        // Act
        final result = await rubricRepository.validateRubric(testRubric);

        // Assert
        expect(result, isTrue);
        verify(mockCollection.where('name', isEqualTo: 'Test Rubric')).called(1);
        verify(mockQuery.where('eventId', isEqualTo: 'event_456')).called(1);
      });

      test('should detect duplicate rubric names', () async {
        // Arrange
        final existingDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(existingDoc.id).thenReturn('different_id');
        when(mockQuerySnapshot.docs).thenReturn([existingDoc]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockCollection.where('name', isEqualTo: 'Test Rubric'))
            .thenReturn(mockQuery);
        when(mockQuery.where('eventId', isEqualTo: 'event_456'))
            .thenReturn(mockQuery);

        // Act
        final result = await rubricRepository.validateRubric(testRubric);

        // Assert
        expect(result, isFalse); // Should be invalid due to duplicate name
      });

      test('should allow updating same rubric', () async {
        // Arrange
        final existingDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(existingDoc.id).thenReturn('rubric_123'); // Same ID as test rubric
        when(mockQuerySnapshot.docs).thenReturn([existingDoc]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockCollection.where('name', isEqualTo: 'Test Rubric'))
            .thenReturn(mockQuery);
        when(mockQuery.where('eventId', isEqualTo: 'event_456'))
            .thenReturn(mockQuery);

        // Act
        final result = await rubricRepository.validateRubric(testRubric);

        // Assert
        expect(result, isTrue); // Should be valid when updating same rubric
      });
    });
  });
}

// Additional mock classes needed for Firestore operations
class MockQueryDocumentSnapshot<T> extends Mock implements QueryDocumentSnapshot<T> {}
class MockWriteBatch extends Mock implements WriteBatch {}