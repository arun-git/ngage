import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/analytics.dart';

void main() {
  group('Analytics Models', () {
    group('ParticipationMetrics', () {
      test('should create ParticipationMetrics correctly', () {
        // Arrange & Act
        const metrics = ParticipationMetrics(
          totalMembers: 100,
          activeMembers: 80,
          totalTeams: 10,
          activeTeams: 8,
          totalEvents: 5,
          completedEvents: 4,
          totalSubmissions: 25,
          participationRate: 80.0,
          eventCompletionRate: 80.0,
          membersByCategory: {'Engineering': 50, 'Marketing': 30},
          teamsByType: {'Development': 5, 'Marketing': 3},
        );

        // Assert
        expect(metrics.totalMembers, equals(100));
        expect(metrics.activeMembers, equals(80));
        expect(metrics.participationRate, equals(80.0));
        expect(metrics.membersByCategory['Engineering'], equals(50));
        expect(metrics.teamsByType['Development'], equals(5));
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        const originalMetrics = ParticipationMetrics(
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
        );

        // Act
        final json = originalMetrics.toJson();
        final deserializedMetrics = ParticipationMetrics.fromJson(json);

        // Assert
        expect(deserializedMetrics.totalMembers, equals(originalMetrics.totalMembers));
        expect(deserializedMetrics.activeMembers, equals(originalMetrics.activeMembers));
        expect(deserializedMetrics.participationRate, equals(originalMetrics.participationRate));
        expect(deserializedMetrics.membersByCategory, equals(originalMetrics.membersByCategory));
      });
    });

    group('JudgeActivityMetrics', () {
      test('should create JudgeActivityMetrics correctly', () {
        // Arrange & Act
        const metrics = JudgeActivityMetrics(
          totalJudges: 10,
          activeJudges: 8,
          totalScores: 40,
          totalComments: 20,
          averageScoresPerJudge: 5.0,
          averageCommentsPerJudge: 2.5,
          scoresByJudge: {'judge1': 15, 'judge2': 12},
          commentsByJudge: {'judge1': 8, 'judge2': 6},
          averageScoresByEvent: {'event1': 8.5, 'event2': 7.8},
        );

        // Assert
        expect(metrics.totalJudges, equals(10));
        expect(metrics.activeJudges, equals(8));
        expect(metrics.averageScoresPerJudge, equals(5.0));
        expect(metrics.scoresByJudge['judge1'], equals(15));
        expect(metrics.averageScoresByEvent['event1'], equals(8.5));
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        const originalMetrics = JudgeActivityMetrics(
          totalJudges: 10,
          activeJudges: 8,
          totalScores: 40,
          totalComments: 20,
          averageScoresPerJudge: 5.0,
          averageCommentsPerJudge: 2.5,
          scoresByJudge: {'judge1': 15},
          commentsByJudge: {'judge1': 8},
          averageScoresByEvent: {'event1': 8.5},
        );

        // Act
        final json = originalMetrics.toJson();
        final deserializedMetrics = JudgeActivityMetrics.fromJson(json);

        // Assert
        expect(deserializedMetrics.totalJudges, equals(originalMetrics.totalJudges));
        expect(deserializedMetrics.averageScoresPerJudge, equals(originalMetrics.averageScoresPerJudge));
        expect(deserializedMetrics.scoresByJudge, equals(originalMetrics.scoresByJudge));
      });
    });

    group('EngagementMetrics', () {
      test('should create EngagementMetrics correctly', () {
        // Arrange & Act
        const metrics = EngagementMetrics(
          totalPosts: 50,
          totalLikes: 200,
          totalComments: 100,
          averageLikesPerPost: 4.0,
          averageCommentsPerPost: 2.0,
          postsByMember: {'member1': 20, 'member2': 15},
          likesByMember: {'member1': 80, 'member2': 60},
          commentsByMember: {'member1': 40, 'member2': 30},
          topContributors: ['member1', 'member2'],
          engagementByDay: {'2024-01-01': 10.0, '2024-01-02': 15.0},
        );

        // Assert
        expect(metrics.totalPosts, equals(50));
        expect(metrics.totalLikes, equals(200));
        expect(metrics.averageLikesPerPost, equals(4.0));
        expect(metrics.topContributors, contains('member1'));
        expect(metrics.engagementByDay['2024-01-01'], equals(10.0));
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        const originalMetrics = EngagementMetrics(
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
        );

        // Act
        final json = originalMetrics.toJson();
        final deserializedMetrics = EngagementMetrics.fromJson(json);

        // Assert
        expect(deserializedMetrics.totalPosts, equals(originalMetrics.totalPosts));
        expect(deserializedMetrics.averageLikesPerPost, equals(originalMetrics.averageLikesPerPost));
        expect(deserializedMetrics.topContributors, equals(originalMetrics.topContributors));
      });
    });

    group('AnalyticsMetrics', () {
      test('should create AnalyticsMetrics correctly', () {
        // Arrange
        final createdAt = DateTime.now();
        final updatedAt = DateTime.now();
        
        final metrics = AnalyticsMetrics(
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
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        // Assert
        expect(metrics.id, equals('test-metrics'));
        expect(metrics.groupId, equals('test-group'));
        expect(metrics.participation.totalMembers, equals(100));
        expect(metrics.judgeActivity.totalJudges, equals(10));
        expect(metrics.engagement.totalPosts, equals(50));
        expect(metrics.createdAt, equals(createdAt));
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        final originalMetrics = AnalyticsMetrics(
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

        // Act
        final json = originalMetrics.toJson();
        final deserializedMetrics = AnalyticsMetrics.fromJson(json);

        // Assert
        expect(deserializedMetrics.id, equals(originalMetrics.id));
        expect(deserializedMetrics.groupId, equals(originalMetrics.groupId));
        expect(deserializedMetrics.participation.totalMembers, 
               equals(originalMetrics.participation.totalMembers));
        expect(deserializedMetrics.judgeActivity.totalJudges, 
               equals(originalMetrics.judgeActivity.totalJudges));
        expect(deserializedMetrics.engagement.totalPosts, 
               equals(originalMetrics.engagement.totalPosts));
      });
    });

    group('AnalyticsFilter', () {
      test('should create AnalyticsFilter correctly', () {
        // Arrange & Act
        final filter = AnalyticsFilter(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          groupIds: ['group1', 'group2'],
          eventIds: ['event1'],
          period: AnalyticsPeriod.monthly,
          metricTypes: [AnalyticsMetricType.participation, AnalyticsMetricType.engagement],
        );

        // Assert
        expect(filter.startDate, equals(DateTime(2024, 1, 1)));
        expect(filter.groupIds, contains('group1'));
        expect(filter.period, equals(AnalyticsPeriod.monthly));
        expect(filter.metricTypes, contains(AnalyticsMetricType.participation));
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        final originalFilter = AnalyticsFilter(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          groupIds: ['group1'],
          period: AnalyticsPeriod.monthly,
          metricTypes: [AnalyticsMetricType.participation],
        );

        // Act
        final json = originalFilter.toJson();
        final deserializedFilter = AnalyticsFilter.fromJson(json);

        // Assert
        expect(deserializedFilter.startDate, equals(originalFilter.startDate));
        expect(deserializedFilter.groupIds, equals(originalFilter.groupIds));
        expect(deserializedFilter.period, equals(originalFilter.period));
        expect(deserializedFilter.metricTypes, equals(originalFilter.metricTypes));
      });
    });

    group('AnalyticsReport', () {
      test('should create AnalyticsReport correctly', () {
        // Arrange
        final generatedAt = DateTime.now();
        final filter = AnalyticsFilter(
          period: AnalyticsPeriod.monthly,
          metricTypes: [AnalyticsMetricType.participation],
        );
        
        final report = AnalyticsReport(
          id: 'report-1',
          title: 'Monthly Report',
          description: 'Monthly analytics report',
          filter: filter,
          metrics: [],
          summary: {'totalGroups': 5},
          generatedAt: generatedAt,
          generatedBy: 'admin-user',
        );

        // Assert
        expect(report.id, equals('report-1'));
        expect(report.title, equals('Monthly Report'));
        expect(report.filter.period, equals(AnalyticsPeriod.monthly));
        expect(report.summary['totalGroups'], equals(5));
        expect(report.generatedBy, equals('admin-user'));
      });

      test('should serialize to and from JSON correctly', () {
        // Arrange
        final originalReport = AnalyticsReport(
          id: 'report-1',
          title: 'Test Report',
          description: 'Test description',
          filter: AnalyticsFilter(
            period: AnalyticsPeriod.monthly,
            metricTypes: [AnalyticsMetricType.participation],
          ),
          metrics: [],
          summary: {'test': 'value'},
          generatedAt: DateTime.now(),
          generatedBy: 'test-user',
        );

        // Act
        final json = originalReport.toJson();
        final deserializedReport = AnalyticsReport.fromJson(json);

        // Assert
        expect(deserializedReport.id, equals(originalReport.id));
        expect(deserializedReport.title, equals(originalReport.title));
        expect(deserializedReport.filter.period, equals(originalReport.filter.period));
        expect(deserializedReport.summary, equals(originalReport.summary));
        expect(deserializedReport.generatedBy, equals(originalReport.generatedBy));
      });
    });

    group('Enums', () {
      test('should have correct AnalyticsPeriod values', () {
        expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.daily));
        expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.weekly));
        expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.monthly));
        expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.quarterly));
        expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.yearly));
        expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.custom));
      });

      test('should have correct AnalyticsMetricType values', () {
        expect(AnalyticsMetricType.values, contains(AnalyticsMetricType.participation));
        expect(AnalyticsMetricType.values, contains(AnalyticsMetricType.judgeActivity));
        expect(AnalyticsMetricType.values, contains(AnalyticsMetricType.engagement));
        expect(AnalyticsMetricType.values, contains(AnalyticsMetricType.performance));
        expect(AnalyticsMetricType.values, contains(AnalyticsMetricType.trends));
      });
    });
  });
}