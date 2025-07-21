import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/analytics.dart';
import '../../lib/repositories/analytics_repository.dart';

import 'analytics_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
])
void main() {
  group('AnalyticsRepository', () {
    late AnalyticsRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockQueryDoc;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockQueryDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      
      repository = AnalyticsRepository(mockFirestore);
    });

    group('getMemberParticipationData', () {
      test('should return member participation data correctly', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        // Mock group members query
        when(mockFirestore.collection('group_members'))
            .thenReturn(mockCollection);
        when(mockCollection.where('groupId', isEqualTo: groupId))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs)
            .thenReturn([mockQueryDoc, mockQueryDoc]); // 2 members

        // Mock submissions query
        when(mockFirestore.collection('submissions'))
            .thenReturn(mockCollection);
        when(mockCollection.where('createdAt', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)))
            .thenReturn(mockQuery);
        when(mockQuery.where('createdAt', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate)))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        
        final submissionDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(submissionDoc.data()).thenReturn({'submittedBy': 'member1'});
        when(mockQuerySnapshot.docs).thenReturn([submissionDoc]);

        // Mock posts query
        when(mockFirestore.collection('posts'))
            .thenReturn(mockCollection);
        when(mockCollection.where('groupId', isEqualTo: groupId))
            .thenReturn(mockQuery);
        when(mockQuery.where('createdAt', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)))
            .thenReturn(mockQuery);
        when(mockQuery.where('createdAt', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate)))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        
        final postDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(postDoc.data()).thenReturn({'authorId': 'member2'});
        when(mockQuerySnapshot.docs).thenReturn([postDoc]);

        // Mock member details
        when(mockQueryDoc.data()).thenReturn({'memberId': 'member1'});
        final mockMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        when(mockFirestore.collection('members'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('member1'))
            .thenReturn(MockDocumentReference<Map<String, dynamic>>());
        when(MockDocumentReference<Map<String, dynamic>>().get())
            .thenAnswer((_) async => mockMemberDoc);
        when(mockMemberDoc.exists).thenReturn(true);
        when(mockMemberDoc.data()).thenReturn({'category': 'Engineering'});

        // Act
        final result = await repository.getMemberParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result['total'], equals(2));
        expect(result['active'], equals(2)); // member1 from submission, member2 from post
        expect(result['byCategory'], isA<Map<String, int>>());
      });
    });

    group('getTeamParticipationData', () {
      test('should return team participation data correctly', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        // Mock teams query
        when(mockFirestore.collection('teams'))
            .thenReturn(mockCollection);
        when(mockCollection.where('groupId', isEqualTo: groupId))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        
        final teamDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(teamDoc.data()).thenReturn({'teamType': 'Development'});
        when(mockQuerySnapshot.docs).thenReturn([teamDoc]);

        // Mock submissions query for team activity
        when(mockFirestore.collection('submissions'))
            .thenReturn(mockCollection);
        when(mockCollection.where('createdAt', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)))
            .thenReturn(mockQuery);
        when(mockQuery.where('createdAt', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate)))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        
        final submissionDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(submissionDoc.data()).thenReturn({'teamId': 'team1'});
        when(mockQuerySnapshot.docs).thenReturn([submissionDoc]);

        // Act
        final result = await repository.getTeamParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result['total'], equals(1));
        expect(result['active'], equals(1));
        expect(result['byType'], isA<Map<String, int>>());
        expect(result['byType']['Development'], equals(1));
      });
    });

    group('storeAnalyticsMetrics', () {
      test('should store analytics metrics successfully', () async {
        // Arrange
        final metrics = _createTestAnalyticsMetrics();
        
        when(mockFirestore.collection('analytics_metrics'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(metrics.id))
            .thenReturn(MockDocumentReference<Map<String, dynamic>>());
        when(MockDocumentReference<Map<String, dynamic>>().set(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.storeAnalyticsMetrics(metrics);

        // Assert
        verify(mockFirestore.collection('analytics_metrics')).called(1);
      });
    });

    group('getHistoricalMetrics', () {
      test('should return historical metrics correctly', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 3, 31);

        when(mockFirestore.collection('analytics_metrics'))
            .thenReturn(mockCollection);
        when(mockCollection.where('groupId', isEqualTo: groupId))
            .thenReturn(mockQuery);
        when(mockQuery.where('periodStart', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)))
            .thenReturn(mockQuery);
        when(mockQuery.where('periodEnd', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate)))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('periodStart'))
            .thenReturn(mockQuery);
        when(mockQuery.get())
            .thenAnswer((_) async => mockQuerySnapshot);

        final metricsDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(metricsDoc.data()).thenReturn(_createTestAnalyticsMetrics().toJson());
        when(mockQuerySnapshot.docs).thenReturn([metricsDoc]);

        // Act
        final result = await repository.getHistoricalMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isA<List<AnalyticsMetrics>>());
        expect(result.length, equals(1));
      });
    });

    group('error handling', () {
      test('should handle Firestore exceptions gracefully', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(mockFirestore.collection('group_members'))
            .thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => repository.getMemberParticipationData(
            groupId: groupId,
            startDate: startDate,
            endDate: endDate,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

AnalyticsMetrics _createTestAnalyticsMetrics() {
  return AnalyticsMetrics(
    id: 'test-metrics',
    groupId: 'test-group',
    periodStart: DateTime(2024, 1, 1),
    periodEnd: DateTime(2024, 1, 31),
    participation: const ParticipationMetrics(
      totalMembers: 100,
      activeMembers: 80,
      totalTeams: 10,
      activeTeams: 8,
      totalEvents: 5,
      completedEvents: 4,
      totalSubmissions: 25,
      participationRate: 80.0,
      eventCompletionRate: 80.0,
      membersByCategory: {'Engineering': 50},
      teamsByType: {'Development': 5},
    ),
    judgeActivity: const JudgeActivityMetrics(
      totalJudges: 10,
      activeJudges: 8,
      totalScores: 40,
      totalComments: 20,
      averageScoresPerJudge: 5.0,
      averageCommentsPerJudge: 2.5,
      scoresByJudge: {'judge1': 15},
      commentsByJudge: {'judge1': 8},
      averageScoresByEvent: {'event1': 8.5},
    ),
    engagement: const EngagementMetrics(
      totalPosts: 50,
      totalLikes: 200,
      totalComments: 100,
      averageLikesPerPost: 4.0,
      averageCommentsPerPost: 2.0,
      postsByMember: {'member1': 20},
      likesByMember: {'member1': 80},
      commentsByMember: {'member1': 40},
      topContributors: ['member1'],
      engagementByDay: {'2024-01-01': 10.0},
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}