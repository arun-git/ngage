// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsMetrics _$AnalyticsMetricsFromJson(Map<String, dynamic> json) =>
    AnalyticsMetrics(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      eventId: json['eventId'] as String?,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      participation: ParticipationMetrics.fromJson(
          json['participation'] as Map<String, dynamic>),
      judgeActivity: JudgeActivityMetrics.fromJson(
          json['judgeActivity'] as Map<String, dynamic>),
      engagement: EngagementMetrics.fromJson(
          json['engagement'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AnalyticsMetricsToJson(AnalyticsMetrics instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'eventId': instance.eventId,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'participation': instance.participation,
      'judgeActivity': instance.judgeActivity,
      'engagement': instance.engagement,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

ParticipationMetrics _$ParticipationMetricsFromJson(
        Map<String, dynamic> json) =>
    ParticipationMetrics(
      totalMembers: (json['totalMembers'] as num).toInt(),
      activeMembers: (json['activeMembers'] as num).toInt(),
      totalTeams: (json['totalTeams'] as num).toInt(),
      activeTeams: (json['activeTeams'] as num).toInt(),
      totalEvents: (json['totalEvents'] as num).toInt(),
      completedEvents: (json['completedEvents'] as num).toInt(),
      totalSubmissions: (json['totalSubmissions'] as num).toInt(),
      participationRate: (json['participationRate'] as num).toDouble(),
      eventCompletionRate: (json['eventCompletionRate'] as num).toDouble(),
      membersByCategory:
          Map<String, int>.from(json['membersByCategory'] as Map),
      teamsByType: Map<String, int>.from(json['teamsByType'] as Map),
    );

Map<String, dynamic> _$ParticipationMetricsToJson(
        ParticipationMetrics instance) =>
    <String, dynamic>{
      'totalMembers': instance.totalMembers,
      'activeMembers': instance.activeMembers,
      'totalTeams': instance.totalTeams,
      'activeTeams': instance.activeTeams,
      'totalEvents': instance.totalEvents,
      'completedEvents': instance.completedEvents,
      'totalSubmissions': instance.totalSubmissions,
      'participationRate': instance.participationRate,
      'eventCompletionRate': instance.eventCompletionRate,
      'membersByCategory': instance.membersByCategory,
      'teamsByType': instance.teamsByType,
    };

JudgeActivityMetrics _$JudgeActivityMetricsFromJson(
        Map<String, dynamic> json) =>
    JudgeActivityMetrics(
      totalJudges: (json['totalJudges'] as num).toInt(),
      activeJudges: (json['activeJudges'] as num).toInt(),
      totalScores: (json['totalScores'] as num).toInt(),
      totalComments: (json['totalComments'] as num).toInt(),
      averageScoresPerJudge: (json['averageScoresPerJudge'] as num).toDouble(),
      averageCommentsPerJudge:
          (json['averageCommentsPerJudge'] as num).toDouble(),
      scoresByJudge: Map<String, int>.from(json['scoresByJudge'] as Map),
      commentsByJudge: Map<String, int>.from(json['commentsByJudge'] as Map),
      averageScoresByEvent:
          (json['averageScoresByEvent'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$JudgeActivityMetricsToJson(
        JudgeActivityMetrics instance) =>
    <String, dynamic>{
      'totalJudges': instance.totalJudges,
      'activeJudges': instance.activeJudges,
      'totalScores': instance.totalScores,
      'totalComments': instance.totalComments,
      'averageScoresPerJudge': instance.averageScoresPerJudge,
      'averageCommentsPerJudge': instance.averageCommentsPerJudge,
      'scoresByJudge': instance.scoresByJudge,
      'commentsByJudge': instance.commentsByJudge,
      'averageScoresByEvent': instance.averageScoresByEvent,
    };

EngagementMetrics _$EngagementMetricsFromJson(Map<String, dynamic> json) =>
    EngagementMetrics(
      totalPosts: (json['totalPosts'] as num).toInt(),
      totalLikes: (json['totalLikes'] as num).toInt(),
      totalComments: (json['totalComments'] as num).toInt(),
      averageLikesPerPost: (json['averageLikesPerPost'] as num).toDouble(),
      averageCommentsPerPost:
          (json['averageCommentsPerPost'] as num).toDouble(),
      postsByMember: Map<String, int>.from(json['postsByMember'] as Map),
      likesByMember: Map<String, int>.from(json['likesByMember'] as Map),
      commentsByMember: Map<String, int>.from(json['commentsByMember'] as Map),
      topContributors: (json['topContributors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      engagementByDay: (json['engagementByDay'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$EngagementMetricsToJson(EngagementMetrics instance) =>
    <String, dynamic>{
      'totalPosts': instance.totalPosts,
      'totalLikes': instance.totalLikes,
      'totalComments': instance.totalComments,
      'averageLikesPerPost': instance.averageLikesPerPost,
      'averageCommentsPerPost': instance.averageCommentsPerPost,
      'postsByMember': instance.postsByMember,
      'likesByMember': instance.likesByMember,
      'commentsByMember': instance.commentsByMember,
      'topContributors': instance.topContributors,
      'engagementByDay': instance.engagementByDay,
    };

AnalyticsFilter _$AnalyticsFilterFromJson(Map<String, dynamic> json) =>
    AnalyticsFilter(
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      groupIds: (json['groupIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      eventIds: (json['eventIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      teamIds:
          (json['teamIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      memberIds: (json['memberIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      period: $enumDecode(_$AnalyticsPeriodEnumMap, json['period']),
      metricTypes: (json['metricTypes'] as List<dynamic>)
          .map((e) => $enumDecode(_$AnalyticsMetricTypeEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$AnalyticsFilterToJson(AnalyticsFilter instance) =>
    <String, dynamic>{
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'groupIds': instance.groupIds,
      'eventIds': instance.eventIds,
      'teamIds': instance.teamIds,
      'memberIds': instance.memberIds,
      'period': _$AnalyticsPeriodEnumMap[instance.period]!,
      'metricTypes': instance.metricTypes
          .map((e) => _$AnalyticsMetricTypeEnumMap[e]!)
          .toList(),
    };

const _$AnalyticsPeriodEnumMap = {
  AnalyticsPeriod.daily: 'daily',
  AnalyticsPeriod.weekly: 'weekly',
  AnalyticsPeriod.monthly: 'monthly',
  AnalyticsPeriod.quarterly: 'quarterly',
  AnalyticsPeriod.yearly: 'yearly',
  AnalyticsPeriod.custom: 'custom',
};

const _$AnalyticsMetricTypeEnumMap = {
  AnalyticsMetricType.participation: 'participation',
  AnalyticsMetricType.judgeActivity: 'judgeActivity',
  AnalyticsMetricType.engagement: 'engagement',
  AnalyticsMetricType.performance: 'performance',
  AnalyticsMetricType.trends: 'trends',
};

AnalyticsReport _$AnalyticsReportFromJson(Map<String, dynamic> json) =>
    AnalyticsReport(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      filter: AnalyticsFilter.fromJson(json['filter'] as Map<String, dynamic>),
      metrics: (json['metrics'] as List<dynamic>)
          .map((e) => AnalyticsMetrics.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as Map<String, dynamic>,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      generatedBy: json['generatedBy'] as String,
    );

Map<String, dynamic> _$AnalyticsReportToJson(AnalyticsReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'filter': instance.filter,
      'metrics': instance.metrics,
      'summary': instance.summary,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'generatedBy': instance.generatedBy,
    };
