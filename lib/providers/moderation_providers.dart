import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_report.dart';
import '../models/moderation_action.dart';
import '../repositories/content_report_repository.dart';
import '../repositories/moderation_action_repository.dart';
import '../services/moderation_service.dart';

// Repository providers
final contentReportRepositoryProvider = Provider<ContentReportRepository>((ref) {
  return ContentReportRepository();
});

final moderationActionRepositoryProvider = Provider<ModerationActionRepository>((ref) {
  return ModerationActionRepository();
});

// Service provider
final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService(
    reportRepository: ref.watch(contentReportRepositoryProvider),
    actionRepository: ref.watch(moderationActionRepositoryProvider),
  );
});

// Pending reports stream provider
final pendingReportsStreamProvider = StreamProvider<List<ContentReport>>((ref) {
  final service = ref.watch(moderationServiceProvider);
  return service.streamPendingReports();
});

// Pending reports count provider
final pendingReportsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(moderationServiceProvider);
  final reports = await service.getPendingReports();
  return reports.length;
});

// Reports by status provider
final reportsByStatusProvider = FutureProvider.family<List<ContentReport>, ReportStatus>((ref, status) async {
  final service = ref.watch(moderationServiceProvider);
  return service.getReportsByStatus(status);
});

// Moderation statistics provider
final moderationStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(moderationServiceProvider);
  return service.getModerationStatistics();
});

// Content moderation status provider
final contentModerationStatusProvider = FutureProvider.family<bool, ContentModerationParams>((ref, params) async {
  final service = ref.watch(moderationServiceProvider);
  return service.isContentModerated(params.contentId, params.contentType);
});

// User restriction status provider
final userRestrictionStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.watch(moderationServiceProvider);
  return service.isUserRestricted(userId);
});

// User restrictions provider
final userRestrictionsProvider = FutureProvider.family<List<ModerationAction>, String>((ref, userId) async {
  final service = ref.watch(moderationServiceProvider);
  return service.getUserRestrictions(userId);
});

// Actions for target provider
final actionsForTargetProvider = FutureProvider.family<List<ModerationAction>, ModerationTargetParams>((ref, params) async {
  final service = ref.watch(moderationServiceProvider);
  return service.getActionsForTarget(params.targetId, params.targetType);
});

// Reports for content provider
final reportsForContentProvider = FutureProvider.family<List<ContentReport>, ContentReportParams>((ref, params) async {
  final repository = ref.watch(contentReportRepositoryProvider);
  return repository.getReportsForContent(params.contentId, params.contentType);
});

// Helper classes for provider parameters
class ContentModerationParams {
  final String contentId;
  final ModerationTargetType contentType;

  ContentModerationParams({
    required this.contentId,
    required this.contentType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentModerationParams &&
        other.contentId == contentId &&
        other.contentType == contentType;
  }

  @override
  int get hashCode => Object.hash(contentId, contentType);
}

class ModerationTargetParams {
  final String targetId;
  final ModerationTargetType targetType;

  ModerationTargetParams({
    required this.targetId,
    required this.targetType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModerationTargetParams &&
        other.targetId == targetId &&
        other.targetType == targetType;
  }

  @override
  int get hashCode => Object.hash(targetId, targetType);
}

class ContentReportParams {
  final String contentId;
  final ContentType contentType;

  ContentReportParams({
    required this.contentId,
    required this.contentType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentReportParams &&
        other.contentId == contentId &&
        other.contentType == contentType;
  }

  @override
  int get hashCode => Object.hash(contentId, contentType);
}