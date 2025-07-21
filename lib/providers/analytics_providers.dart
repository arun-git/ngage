import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';
import '../repositories/analytics_repository.dart';
import '../services/analytics_service.dart';

// Repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(FirebaseFirestore.instance);
});

// Service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsService(repository);
});

// Analytics metrics provider
final analyticsMetricsProvider = FutureProvider.family<AnalyticsMetrics, AnalyticsMetricsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.generateAnalyticsMetrics(
    groupId: params.groupId,
    startDate: params.startDate,
    endDate: params.endDate,
    eventId: params.eventId,
  );
});

// Historical metrics provider
final historicalMetricsProvider = FutureProvider.family<List<AnalyticsMetrics>, HistoricalMetricsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getHistoricalMetrics(
    groupId: params.groupId,
    startDate: params.startDate,
    endDate: params.endDate,
    period: params.period,
    eventId: params.eventId,
  );
});

// Analytics reports provider
final analyticsReportsProvider = FutureProvider.family<List<AnalyticsReport>, AnalyticsReportsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getReports(
    groupIds: params.groupIds,
    startDate: params.startDate,
    endDate: params.endDate,
    generatedBy: params.generatedBy,
    limit: params.limit,
  );
});

// Trends provider
final trendsProvider = FutureProvider.family<Map<String, dynamic>, TrendsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.calculateTrends(
    groupId: params.groupId,
    startDate: params.startDate,
    endDate: params.endDate,
    period: params.period,
  );
});

// Participation metrics provider
final participationMetricsProvider = FutureProvider.family<ParticipationMetrics, AnalyticsMetricsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.calculateParticipationMetrics(
    groupId: params.groupId,
    startDate: params.startDate,
    endDate: params.endDate,
    eventId: params.eventId,
  );
});

// Judge activity metrics provider
final judgeActivityMetricsProvider = FutureProvider.family<JudgeActivityMetrics, AnalyticsMetricsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.calculateJudgeActivityMetrics(
    groupId: params.groupId,
    startDate: params.startDate,
    endDate: params.endDate,
    eventId: params.eventId,
  );
});

// Engagement metrics provider
final engagementMetricsProvider = FutureProvider.family<EngagementMetrics, EngagementMetricsParams>((ref, params) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.calculateEngagementMetrics(
    groupId: params.groupId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// Parameter classes
class AnalyticsMetricsParams {
  final String groupId;
  final DateTime startDate;
  final DateTime endDate;
  final String? eventId;

  const AnalyticsMetricsParams({
    required this.groupId,
    required this.startDate,
    required this.endDate,
    this.eventId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsMetricsParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          eventId == other.eventId;

  @override
  int get hashCode =>
      groupId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      eventId.hashCode;
}

class HistoricalMetricsParams {
  final String groupId;
  final DateTime startDate;
  final DateTime endDate;
  final AnalyticsPeriod period;
  final String? eventId;

  const HistoricalMetricsParams({
    required this.groupId,
    required this.startDate,
    required this.endDate,
    required this.period,
    this.eventId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoricalMetricsParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          period == other.period &&
          eventId == other.eventId;

  @override
  int get hashCode =>
      groupId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      period.hashCode ^
      eventId.hashCode;
}

class AnalyticsReportsParams {
  final List<String>? groupIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? generatedBy;
  final int limit;

  const AnalyticsReportsParams({
    this.groupIds,
    this.startDate,
    this.endDate,
    this.generatedBy,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsReportsParams &&
          runtimeType == other.runtimeType &&
          groupIds == other.groupIds &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          generatedBy == other.generatedBy &&
          limit == other.limit;

  @override
  int get hashCode =>
      groupIds.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      generatedBy.hashCode ^
      limit.hashCode;
}

class TrendsParams {
  final String groupId;
  final DateTime startDate;
  final DateTime endDate;
  final AnalyticsPeriod period;

  const TrendsParams({
    required this.groupId,
    required this.startDate,
    required this.endDate,
    required this.period,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendsParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          period == other.period;

  @override
  int get hashCode =>
      groupId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      period.hashCode;
}

class EngagementMetricsParams {
  final String groupId;
  final DateTime startDate;
  final DateTime endDate;

  const EngagementMetricsParams({
    required this.groupId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngagementMetricsParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      groupId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}