import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/analytics.dart';
import 'package:ngage/repositories/analytics_repository.dart';
import 'package:ngage/services/analytics_service.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([AnalyticsRepository])
void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockAnalyticsRepository mockRepository;

    setUp(() {
      mockRepository = MockAnalyticsRepository();
      analyticsService = AnalyticsService(mockRepository);
    });

    group('calculateParticipationMetrics', () {
      test('should calculate participation metrics correctly', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(mockRepository.getMemberParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 100,
          'active': 80,
          'byCategory': {'Engineering': 50, 'Marketing': 30, 'Sales': 20},
        });

        when(mockRepository.getTeamParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 10,
          'active': 8,
          'byType': {'Development': 5, 'Marketing': 3, 'Sales': 2},
        });

        when(mockRepository.getEventParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 5,
          'completed': 4,
        });

        when(mockRepository.getSubmissionData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 25,
        });

        // Act
        final result = await analyticsService.calculateParticipationMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.totalMembers, equals(100));
        expect(result.activeMembers, equals(80));
        expect(result.totalTeams, equals(10));
        expect(result.activeTeams, equals(8));
        expect(result.totalEvents, equals(5));
        expect(result.completedEvents, equals(4));
        expect(result.totalSubmissions, equals(25));
        expect(result.participationRate, equals(80.0));
        expect(result.eventCompletionRate, equals(80.0));
        expect(result.membersByCategory['Engineering'], equals(50));
        expect(result.teamsByType['Development'], equals(5));
      });

      test('should handle zero members correctly', () async {
        // Arrange
        const groupId = 'empty-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(mockRepository.getMemberParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 0,
          'active': 0,
          'byCategory': <String, int>{},
        });

        when(mockRepository.getTeamParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 0,
          'active': 0,
          'byType': <String, int>{},
        });

        when(mockRepository.getEventParticipationData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 0,
          'completed': 0,
        });

        when(mockRepository.getSubmissionData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 0,
        });

        // Act
        final result = await analyticsService.calculateParticipationMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.totalMembers, equals(0));
        expect(result.activeMembers, equals(0));
        expect(result.participationRate, equals(0.0));
        expect(result.eventCompletionRate, equals(0.0));
      });
    });

    group('calculateJudgeActivityMetrics', () {
      test('should calculate judge activity metrics correctly', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(mockRepository.getJudgeActivityData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 10,
          'active': 8,
        });

        when(mockRepository.getScoringData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 40,
          'byJudge': {'judge1': 15, 'judge2': 12, 'judge3': 13},
          'averageByEvent': {'event1': 8.5, 'event2': 7.8},
        });

        when(mockRepository.getJudgeCommentData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          eventId: null,
        )).thenAnswer((_) async => {
          'total': 20,
          'byJudge': {'judge1': 8, 'judge2': 6, 'judge3': 6},
        });

        // Act
        final result = await analyticsService.calculateJudgeActivityMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.totalJudges, equals(10));
        expect(result.activeJudges, equals(8));
        expect(result.totalScores, equals(40));
        expect(result.totalComments, equals(20));
        expect(result.averageScoresPerJudge, equals(5.0));
        expect(result.averageCommentsPerJudge, equals(2.5));
        expect(result.scoresByJudge['judge1'], equals(15));
        expect(result.commentsByJudge['judge1'], equals(8));
      });
    });

    group('calculateEngagementMetrics', () {
      test('should calculate engagement metrics correctly', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(mockRepository.getPostData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 50,
          'byMember': {'member1': 20, 'member2': 15, 'member3': 15},
        });

        when(mockRepository.getLikeData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 200,
          'byMember': {'member1': 80, 'member2': 60, 'member3': 60},
        });

        when(mockRepository.getCommentData(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          'total': 100,
          'byMember': {'member1': 40, 'member2': 30, 'member3': 30},
        });

        when(mockRepository.getTopContributors(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          limit: 10,
        )).thenAnswer((_) async => ['member1', 'member2', 'member3']);

        when(mockRepository.getEngagementByDay(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => {
          '2024-01-01': 10.0,
          '2024-01-02': 15.0,
          '2024-01-03': 12.0,
        });

        // Act
        final result = await analyticsService.calculateEngagementMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.totalPosts, equals(50));
        expect(result.totalLikes, equals(200));
        expect(result.totalComments, equals(100));
        expect(result.averageLikesPerPost, equals(4.0));
        expect(result.averageCommentsPerPost, equals(2.0));
        expect(result.topContributors, contains('member1'));
        expect(result.engagementByDay['2024-01-01'], equals(10.0));
      });
    });

    group('generateAnalyticsMetrics', () {
      test('should generate comprehensive analytics metrics', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        // Mock all required repository calls
        _setupMockRepositoryCalls(mockRepository, groupId, startDate, endDate);

        when(mockRepository.storeAnalyticsMetrics(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await analyticsService.generateAnalyticsMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.groupId, equals(groupId));
        expect(result.periodStart, equals(startDate));
        expect(result.periodEnd, equals(endDate));
        expect(result.participation.totalMembers, equals(100));
        expect(result.judgeActivity.totalJudges, equals(10));
        expect(result.engagement.totalPosts, equals(50));
        
        verify(mockRepository.storeAnalyticsMetrics(any)).called(1);
      });
    });

    group('calculateTrends', () {
      test('should calculate trends with sufficient data', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 3, 31);

        final historicalMetrics = [
          _createMockAnalyticsMetrics(
            participationRate: 70.0,
            totalPosts: 40,
            averageScoresPerJudge: 4.0,
          ),
          _createMockAnalyticsMetrics(
            participationRate: 80.0,
            totalPosts: 50,
            averageScoresPerJudge: 5.0,
          ),
        ];

        when(mockRepository.getHistoricalMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          period: AnalyticsPeriod.monthly,
          eventId: null,
        )).thenAnswer((_) async => historicalMetrics);

        // Act
        final result = await analyticsService.calculateTrends(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result['dataPoints'], equals(2));
        expect(result['trends'], isA<Map<String, dynamic>>());
        
        final trends = result['trends'] as Map<String, dynamic>;
        expect(trends['participation']['trend'], equals('increasing'));
        expect(trends['engagement']['trend'], equals('increasing'));
        expect(trends['judgeActivity']['trend'], equals('increasing'));
      });

      test('should handle insufficient data for trends', () async {
        // Arrange
        const groupId = 'test-group';
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(mockRepository.getHistoricalMetrics(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
          period: AnalyticsPeriod.monthly,
          eventId: null,
        )).thenAnswer((_) async => []);

        // Act
        final result = await analyticsService.calculateTrends(
          groupId: groupId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result['trends'], isEmpty);
        expect(result['message'], contains('Insufficient data'));
      });
    });
  });
}

void _setupMockRepositoryCalls(
  MockAnalyticsRepository mockRepository,
  String groupId,
  DateTime startDate,
  DateTime endDate,
) {
  when(mockRepository.getMemberParticipationData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
  )).thenAnswer((_) async => {
    'total': 100,
    'active': 80,
    'byCategory': {'Engineering': 50, 'Marketing': 30, 'Sales': 20},
  });

  when(mockRepository.getTeamParticipationData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
  )).thenAnswer((_) async => {
    'total': 10,
    'active': 8,
    'byType': {'Development': 5, 'Marketing': 3, 'Sales': 2},
  });

  when(mockRepository.getEventParticipationData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
    eventId: null,
  )).thenAnswer((_) async => {
    'total': 5,
    'completed': 4,
  });

  when(mockRepository.getSubmissionData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
    eventId: null,
  )).thenAnswer((_) async => {
    'total': 25,
  });

  when(mockRepository.getJudgeActivityData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
    eventId: null,
  )).thenAnswer((_) async => {
    'total': 10,
    'active': 8,
  });

  when(mockRepository.getScoringData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
    eventId: null,
  )).thenAnswer((_) async => {
    'total': 40,
    'byJudge': {'judge1': 15, 'judge2': 12, 'judge3': 13},
    'averageByEvent': {'event1': 8.5, 'event2': 7.8},
  });

  when(mockRepository.getJudgeCommentData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
    eventId: null,
  )).thenAnswer((_) async => {
    'total': 20,
    'byJudge': {'judge1': 8, 'judge2': 6, 'judge3': 6},
  });

  when(mockRepository.getPostData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
  )).thenAnswer((_) async => {
    'total': 50,
    'byMember': {'member1': 20, 'member2': 15, 'member3': 15},
  });

  when(mockRepository.getLikeData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
  )).thenAnswer((_) async => {
    'total': 200,
    'byMember': {'member1': 80, 'member2': 60, 'member3': 60},
  });

  when(mockRepository.getCommentData(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
  )).thenAnswer((_) async => {
    'total': 100,
    'byMember': {'member1': 40, 'member2': 30, 'member3': 30},
  });

  when(mockRepository.getTopContributors(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
    limit: 10,
  )).thenAnswer((_) async => ['member1', 'member2', 'member3']);

  when(mockRepository.getEngagementByDay(
    groupId: groupId,
    startDate: startDate,
    endDate: endDate,
  )).thenAnswer((_) async => {
    '2024-01-01': 10.0,
    '2024-01-02': 15.0,
    '2024-01-03': 12.0,
  });
}

AnalyticsMetrics _createMockAnalyticsMetrics({
  required double participationRate,
  required int totalPosts,
  required double averageScoresPerJudge,
}) {
  return AnalyticsMetrics(
    id: 'test-metrics',
    groupId: 'test-group',
    periodStart: DateTime(2024, 1, 1),
    periodEnd: DateTime(2024, 1, 31),
    participation: ParticipationMetrics(
      totalMembers: 100,
      activeMembers: (participationRate * 100 / 100).round(),
      totalTeams: 10,
      activeTeams: 8,
      totalEvents: 5,
      completedEvents: 4,
      totalSubmissions: 25,
      participationRate: participationRate,
      eventCompletionRate: 80.0,
      membersByCategory: const {'Engineering': 50},
      teamsByType: const {'Development': 5},
    ),
    judgeActivity: JudgeActivityMetrics(
      totalJudges: 10,
      activeJudges: 8,
      totalScores: 40,
      totalComments: 20,
      averageScoresPerJudge: averageScoresPerJudge,
      averageCommentsPerJudge: 2.5,
      scoresByJudge: const {'judge1': 15},
      commentsByJudge: const {'judge1': 8},
      averageScoresByEvent: const {'event1': 8.5},
    ),
    engagement: EngagementMetrics(
      totalPosts: totalPosts,
      totalLikes: 200,
      totalComments: 100,
      averageLikesPerPost: 4.0,
      averageCommentsPerPost: 2.0,
      postsByMember: const {'member1': 20},
      likesByMember: const {'member1': 80},
      commentsByMember: const {'member1': 40},
      topContributors: const ['member1'],
      engagementByDay: const {'2024-01-01': 10.0},
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}