import '../models/analytics.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsService {
  final AnalyticsRepository _repository;

  AnalyticsService(this._repository);

  /// Calculate participation metrics for a group within a time period
  Future<ParticipationMetrics> calculateParticipationMetrics({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      // Get member data
      final memberData = await _repository.getMemberParticipationData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      // Get team data
      final teamData = await _repository.getTeamParticipationData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      // Get event data
      final eventData = await _repository.getEventParticipationData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      // Get submission data
      final submissionData = await _repository.getSubmissionData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      // Calculate metrics
      final totalMembers = memberData['total'] as int;
      final activeMembers = memberData['active'] as int;
      final totalTeams = teamData['total'] as int;
      final activeTeams = teamData['active'] as int;
      final totalEvents = eventData['total'] as int;
      final completedEvents = eventData['completed'] as int;
      final totalSubmissions = submissionData['total'] as int;

      final participationRate = totalMembers > 0 
          ? (activeMembers / totalMembers) * 100 
          : 0.0;
      
      final eventCompletionRate = totalEvents > 0 
          ? (completedEvents / totalEvents) * 100 
          : 0.0;

      return ParticipationMetrics(
        totalMembers: totalMembers,
        activeMembers: activeMembers,
        totalTeams: totalTeams,
        activeTeams: activeTeams,
        totalEvents: totalEvents,
        completedEvents: completedEvents,
        totalSubmissions: totalSubmissions,
        participationRate: participationRate,
        eventCompletionRate: eventCompletionRate,
        membersByCategory: Map<String, int>.from(memberData['byCategory'] ?? {}),
        teamsByType: Map<String, int>.from(teamData['byType'] ?? {}),
      );
    } catch (e) {
      throw Exception('Failed to calculate participation metrics: $e');
    }
  }

  /// Calculate judge activity metrics
  Future<JudgeActivityMetrics> calculateJudgeActivityMetrics({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      // Get judge data
      final judgeData = await _repository.getJudgeActivityData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      // Get scoring data
      final scoringData = await _repository.getScoringData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      // Get comment data
      final commentData = await _repository.getJudgeCommentData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      final totalJudges = judgeData['total'] as int;
      final activeJudges = judgeData['active'] as int;
      final totalScores = scoringData['total'] as int;
      final totalComments = commentData['total'] as int;

      final averageScoresPerJudge = activeJudges > 0 
          ? totalScores / activeJudges 
          : 0.0;
      
      final averageCommentsPerJudge = activeJudges > 0 
          ? totalComments / activeJudges 
          : 0.0;

      return JudgeActivityMetrics(
        totalJudges: totalJudges,
        activeJudges: activeJudges,
        totalScores: totalScores,
        totalComments: totalComments,
        averageScoresPerJudge: averageScoresPerJudge,
        averageCommentsPerJudge: averageCommentsPerJudge,
        scoresByJudge: Map<String, int>.from(scoringData['byJudge'] ?? {}),
        commentsByJudge: Map<String, int>.from(commentData['byJudge'] ?? {}),
        averageScoresByEvent: Map<String, double>.from(scoringData['averageByEvent'] ?? {}),
      );
    } catch (e) {
      throw Exception('Failed to calculate judge activity metrics: $e');
    }
  }

  /// Calculate engagement metrics
  Future<EngagementMetrics> calculateEngagementMetrics({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get social engagement data
      final postData = await _repository.getPostData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      final likeData = await _repository.getLikeData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      final commentData = await _repository.getCommentData(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalPosts = postData['total'] as int;
      final totalLikes = likeData['total'] as int;
      final totalComments = commentData['total'] as int;

      final averageLikesPerPost = totalPosts > 0 
          ? totalLikes / totalPosts 
          : 0.0;
      
      final averageCommentsPerPost = totalPosts > 0 
          ? totalComments / totalPosts 
          : 0.0;

      // Get top contributors
      final topContributors = await _repository.getTopContributors(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        limit: 10,
      );

      // Get engagement by day
      final engagementByDay = await _repository.getEngagementByDay(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      return EngagementMetrics(
        totalPosts: totalPosts,
        totalLikes: totalLikes,
        totalComments: totalComments,
        averageLikesPerPost: averageLikesPerPost,
        averageCommentsPerPost: averageCommentsPerPost,
        postsByMember: Map<String, int>.from(postData['byMember'] ?? {}),
        likesByMember: Map<String, int>.from(likeData['byMember'] ?? {}),
        commentsByMember: Map<String, int>.from(commentData['byMember'] ?? {}),
        topContributors: List<String>.from(topContributors),
        engagementByDay: Map<String, double>.from(engagementByDay),
      );
    } catch (e) {
      throw Exception('Failed to calculate engagement metrics: $e');
    }
  }

  /// Generate comprehensive analytics metrics
  Future<AnalyticsMetrics> generateAnalyticsMetrics({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventId,
  }) async {
    try {
      final participation = await calculateParticipationMetrics(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      final judgeActivity = await calculateJudgeActivityMetrics(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        eventId: eventId,
      );

      final engagement = await calculateEngagementMetrics(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      final metrics = AnalyticsMetrics(
        id: _generateMetricsId(groupId, startDate, endDate, eventId),
        groupId: groupId,
        eventId: eventId,
        periodStart: startDate,
        periodEnd: endDate,
        participation: participation,
        judgeActivity: judgeActivity,
        engagement: engagement,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store metrics for historical tracking
      await _repository.storeAnalyticsMetrics(metrics);

      return metrics;
    } catch (e) {
      throw Exception('Failed to generate analytics metrics: $e');
    }
  }

  /// Generate analytics report with filtering
  Future<AnalyticsReport> generateReport({
    required String title,
    required String description,
    required AnalyticsFilter filter,
    required String generatedBy,
  }) async {
    try {
      final metrics = <AnalyticsMetrics>[];
      
      // Generate metrics based on filter
      if (filter.groupIds != null) {
        for (final groupId in filter.groupIds!) {
          final groupMetrics = await generateAnalyticsMetrics(
            groupId: groupId,
            startDate: filter.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
            endDate: filter.endDate ?? DateTime.now(),
            eventId: filter.eventIds?.isNotEmpty == true ? filter.eventIds!.first : null,
          );
          metrics.add(groupMetrics);
        }
      }

      // Calculate summary statistics
      final summary = _calculateReportSummary(metrics, filter);

      final report = AnalyticsReport(
        id: _generateReportId(),
        title: title,
        description: description,
        filter: filter,
        metrics: metrics,
        summary: summary,
        generatedAt: DateTime.now(),
        generatedBy: generatedBy,
      );

      // Store report
      await _repository.storeAnalyticsReport(report);

      return report;
    } catch (e) {
      throw Exception('Failed to generate analytics report: $e');
    }
  }

  /// Get historical analytics data for trend analysis
  Future<List<AnalyticsMetrics>> getHistoricalMetrics({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    AnalyticsPeriod period = AnalyticsPeriod.monthly,
    String? eventId,
  }) async {
    try {
      return await _repository.getHistoricalMetrics(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        period: period,
        eventId: eventId,
      );
    } catch (e) {
      throw Exception('Failed to get historical metrics: $e');
    }
  }

  /// Get analytics reports with filtering
  Future<List<AnalyticsReport>> getReports({
    List<String>? groupIds,
    DateTime? startDate,
    DateTime? endDate,
    String? generatedBy,
    int limit = 50,
  }) async {
    try {
      return await _repository.getAnalyticsReports(
        groupIds: groupIds,
        startDate: startDate,
        endDate: endDate,
        generatedBy: generatedBy,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get analytics reports: $e');
    }
  }

  /// Calculate trend analysis
  Future<Map<String, dynamic>> calculateTrends({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
    AnalyticsPeriod period = AnalyticsPeriod.monthly,
  }) async {
    try {
      final historicalData = await getHistoricalMetrics(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      if (historicalData.length < 2) {
        return {'trends': {}, 'message': 'Insufficient data for trend analysis'};
      }

      final trends = <String, dynamic>{};
      
      // Calculate participation trends
      final participationTrend = _calculateTrend(
        historicalData.map((m) => m.participation.participationRate).toList(),
      );
      trends['participation'] = participationTrend;

      // Calculate engagement trends
      final engagementTrend = _calculateTrend(
        historicalData.map((m) => m.engagement.totalPosts.toDouble()).toList(),
      );
      trends['engagement'] = engagementTrend;

      // Calculate judge activity trends
      final judgeActivityTrend = _calculateTrend(
        historicalData.map((m) => m.judgeActivity.averageScoresPerJudge).toList(),
      );
      trends['judgeActivity'] = judgeActivityTrend;

      return {'trends': trends, 'dataPoints': historicalData.length};
    } catch (e) {
      throw Exception('Failed to calculate trends: $e');
    }
  }

  // Helper methods
  String _generateMetricsId(String groupId, DateTime start, DateTime end, String? eventId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final eventSuffix = eventId != null ? '_$eventId' : '';
    return '${groupId}_${start.millisecondsSinceEpoch}_${end.millisecondsSinceEpoch}${eventSuffix}_$timestamp';
  }

  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _calculateReportSummary(List<AnalyticsMetrics> metrics, AnalyticsFilter filter) {
    if (metrics.isEmpty) return {};

    final totalParticipation = metrics.fold<double>(
      0, (sum, m) => sum + m.participation.participationRate,
    ) / metrics.length;

    final totalEngagement = metrics.fold<int>(
      0, (sum, m) => sum + m.engagement.totalPosts,
    );

    final totalJudgeActivity = metrics.fold<double>(
      0, (sum, m) => sum + m.judgeActivity.averageScoresPerJudge,
    ) / metrics.length;

    return {
      'averageParticipationRate': totalParticipation,
      'totalEngagementPosts': totalEngagement,
      'averageJudgeActivity': totalJudgeActivity,
      'groupsAnalyzed': metrics.length,
      'periodDays': filter.endDate != null && filter.startDate != null
          ? filter.endDate!.difference(filter.startDate!).inDays
          : 0,
    };
  }

  Map<String, dynamic> _calculateTrend(List<double> values) {
    if (values.length < 2) return {'trend': 'insufficient_data'};

    final first = values.first;
    final last = values.last;
    final change = last - first;
    final percentChange = first != 0 ? (change / first) * 100 : 0;

    String trend;
    if (percentChange > 5) {
      trend = 'increasing';
    } else if (percentChange < -5) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'change': change,
      'percentChange': percentChange,
      'firstValue': first,
      'lastValue': last,
    };
  }
}