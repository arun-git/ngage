import 'package:json_annotation/json_annotation.dart';

part 'analytics.g.dart';

@JsonSerializable()
class AnalyticsMetrics {
  final String id;
  final String groupId;
  final String? eventId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final ParticipationMetrics participation;
  final JudgeActivityMetrics judgeActivity;
  final EngagementMetrics engagement;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnalyticsMetrics({
    required this.id,
    required this.groupId,
    this.eventId,
    required this.periodStart,
    required this.periodEnd,
    required this.participation,
    required this.judgeActivity,
    required this.engagement,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnalyticsMetrics.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsMetricsToJson(this);
}

@JsonSerializable()
class ParticipationMetrics {
  final int totalMembers;
  final int activeMembers;
  final int totalTeams;
  final int activeTeams;
  final int totalEvents;
  final int completedEvents;
  final int totalSubmissions;
  final double participationRate;
  final double eventCompletionRate;
  final Map<String, int> membersByCategory;
  final Map<String, int> teamsByType;

  const ParticipationMetrics({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalTeams,
    required this.activeTeams,
    required this.totalEvents,
    required this.completedEvents,
    required this.totalSubmissions,
    required this.participationRate,
    required this.eventCompletionRate,
    required this.membersByCategory,
    required this.teamsByType,
  });

  factory ParticipationMetrics.fromJson(Map<String, dynamic> json) =>
      _$ParticipationMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipationMetricsToJson(this);
}

@JsonSerializable()
class JudgeActivityMetrics {
  final int totalJudges;
  final int activeJudges;
  final int totalScores;
  final int totalComments;
  final double averageScoresPerJudge;
  final double averageCommentsPerJudge;
  final Map<String, int> scoresByJudge;
  final Map<String, int> commentsByJudge;
  final Map<String, double> averageScoresByEvent;

  const JudgeActivityMetrics({
    required this.totalJudges,
    required this.activeJudges,
    required this.totalScores,
    required this.totalComments,
    required this.averageScoresPerJudge,
    required this.averageCommentsPerJudge,
    required this.scoresByJudge,
    required this.commentsByJudge,
    required this.averageScoresByEvent,
  });

  factory JudgeActivityMetrics.fromJson(Map<String, dynamic> json) =>
      _$JudgeActivityMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$JudgeActivityMetricsToJson(this);
}

@JsonSerializable()
class EngagementMetrics {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final double averageLikesPerPost;
  final double averageCommentsPerPost;
  final Map<String, int> postsByMember;
  final Map<String, int> likesByMember;
  final Map<String, int> commentsByMember;
  final List<String> topContributors;
  final Map<String, double> engagementByDay;

  const EngagementMetrics({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.averageLikesPerPost,
    required this.averageCommentsPerPost,
    required this.postsByMember,
    required this.likesByMember,
    required this.commentsByMember,
    required this.topContributors,
    required this.engagementByDay,
  });

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) =>
      _$EngagementMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementMetricsToJson(this);
}

@JsonSerializable()
class AnalyticsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? groupIds;
  final List<String>? eventIds;
  final List<String>? teamIds;
  final List<String>? memberIds;
  final AnalyticsPeriod period;
  final List<AnalyticsMetricType> metricTypes;

  const AnalyticsFilter({
    this.startDate,
    this.endDate,
    this.groupIds,
    this.eventIds,
    this.teamIds,
    this.memberIds,
    required this.period,
    required this.metricTypes,
  });

  factory AnalyticsFilter.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsFilterFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsFilterToJson(this);
}

@JsonSerializable()
class AnalyticsReport {
  final String id;
  final String title;
  final String description;
  final AnalyticsFilter filter;
  final List<AnalyticsMetrics> metrics;
  final Map<String, dynamic> summary;
  final DateTime generatedAt;
  final String generatedBy;

  const AnalyticsReport({
    required this.id,
    required this.title,
    required this.description,
    required this.filter,
    required this.metrics,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsReportFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsReportToJson(this);
}

enum AnalyticsPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

enum AnalyticsMetricType {
  participation,
  judgeActivity,
  engagement,
  performance,
  trends,
}