import '../models/content_report.dart';
import '../models/moderation_action.dart';
import '../repositories/content_report_repository.dart';
import '../repositories/moderation_action_repository.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';

class ModerationService {
  final ContentReportRepository _reportRepository;
  final ModerationActionRepository _actionRepository;
  final NotificationService _notificationService;
  final PermissionService _permissionService;

  ModerationService({
    ContentReportRepository? reportRepository,
    ModerationActionRepository? actionRepository,
    NotificationService? notificationService,
    PermissionService? permissionService,
  })  : _reportRepository = reportRepository ?? ContentReportRepository(),
        _actionRepository = actionRepository ?? ModerationActionRepository(),
        _notificationService = notificationService ?? NotificationService(),
        _permissionService = permissionService ?? PermissionService();

  /// Report content for moderation
  Future<String> reportContent({
    required String reporterId,
    required String contentId,
    required ContentType contentType,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      // Check if user has already reported this content
      final hasReported = await _reportRepository.hasUserReportedContent(
        reporterId,
        contentId,
        contentType,
      );

      if (hasReported) {
        throw Exception('You have already reported this content');
      }

      final now = DateTime.now();
      final report = ContentReport(
        id: '', // Will be set by Firestore
        reporterId: reporterId,
        contentId: contentId,
        contentType: contentType,
        reason: reason,
        description: description,
        status: ReportStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final reportId = await _reportRepository.createReport(report);

      // Notify admins about new report
      await _notifyAdminsOfNewReport(reportId, contentType, reason);

      return reportId;
    } catch (e) {
      throw Exception('Failed to report content: $e');
    }
  }

  /// Get pending reports for moderation dashboard
  Future<List<ContentReport>> getPendingReports({int? limit}) async {
    try {
      return await _reportRepository.getPendingReports(limit: limit);
    } catch (e) {
      throw Exception('Failed to get pending reports: $e');
    }
  }

  /// Get reports by status
  Future<List<ContentReport>> getReportsByStatus(ReportStatus status) async {
    try {
      return await _reportRepository.getReportsByStatus(status);
    } catch (e) {
      throw Exception('Failed to get reports by status: $e');
    }
  }

  /// Review a content report
  Future<void> reviewReport({
    required String reportId,
    required String reviewerId,
    required ReportStatus newStatus,
    String? reviewNotes,
  }) async {
    try {
      // Check if reviewer has admin permissions
      final hasPermission = await _permissionService.hasPermission(
        reviewerId,
        'moderate_content',
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to review reports');
      }

      await _reportRepository.updateReportStatus(
        reportId,
        newStatus,
        reviewedBy: reviewerId,
        reviewNotes: reviewNotes,
      );

      // Get the report to notify the reporter
      final report = await _reportRepository.getReport(reportId);
      if (report != null) {
        await _notifyReporterOfReview(report, newStatus);
      }
    } catch (e) {
      throw Exception('Failed to review report: $e');
    }
  }

  /// Take moderation action on content or user
  Future<String> takeModerationAction({
    required String moderatorId,
    required String targetId,
    required ModerationTargetType targetType,
    required ModerationActionType actionType,
    String? reason,
    String? notes,
    String? reportId,
    DateTime? expiresAt,
  }) async {
    try {
      // Check if moderator has admin permissions
      final hasPermission = await _permissionService.hasPermission(
        moderatorId,
        'moderate_content',
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to take moderation action');
      }

      final now = DateTime.now();
      final action = ModerationAction(
        id: '', // Will be set by Firestore
        moderatorId: moderatorId,
        targetId: targetId,
        targetType: targetType,
        actionType: actionType,
        reason: reason,
        notes: notes,
        reportId: reportId,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final actionId = await _actionRepository.createAction(action);

      // If this is a user action, notify the user
      if (targetType == ModerationTargetType.user) {
        await _notifyUserOfModerationAction(targetId, actionType, reason);
      }

      // If this action resolves a report, update the report status
      if (reportId != null) {
        await _reportRepository.updateReportStatus(
          reportId,
          ReportStatus.resolved,
          reviewedBy: moderatorId,
          reviewNotes: 'Resolved with ${actionType.name} action',
        );
      }

      return actionId;
    } catch (e) {
      throw Exception('Failed to take moderation action: $e');
    }
  }

  /// Hide content
  Future<String> hideContent({
    required String moderatorId,
    required String contentId,
    required ModerationTargetType contentType,
    String? reason,
    String? reportId,
  }) async {
    return takeModerationAction(
      moderatorId: moderatorId,
      targetId: contentId,
      targetType: contentType,
      actionType: ModerationActionType.hide,
      reason: reason,
      reportId: reportId,
    );
  }

  /// Delete content
  Future<String> deleteContent({
    required String moderatorId,
    required String contentId,
    required ModerationTargetType contentType,
    String? reason,
    String? reportId,
  }) async {
    return takeModerationAction(
      moderatorId: moderatorId,
      targetId: contentId,
      targetType: contentType,
      actionType: ModerationActionType.delete,
      reason: reason,
      reportId: reportId,
    );
  }

  /// Suspend user
  Future<String> suspendUser({
    required String moderatorId,
    required String userId,
    required DateTime expiresAt,
    String? reason,
    String? reportId,
  }) async {
    return takeModerationAction(
      moderatorId: moderatorId,
      targetId: userId,
      targetType: ModerationTargetType.user,
      actionType: ModerationActionType.suspend,
      reason: reason,
      reportId: reportId,
      expiresAt: expiresAt,
    );
  }

  /// Ban user permanently
  Future<String> banUser({
    required String moderatorId,
    required String userId,
    String? reason,
    String? reportId,
  }) async {
    return takeModerationAction(
      moderatorId: moderatorId,
      targetId: userId,
      targetType: ModerationTargetType.user,
      actionType: ModerationActionType.ban,
      reason: reason,
      reportId: reportId,
    );
  }

  /// Warn user
  Future<String> warnUser({
    required String moderatorId,
    required String userId,
    String? reason,
    String? reportId,
  }) async {
    return takeModerationAction(
      moderatorId: moderatorId,
      targetId: userId,
      targetType: ModerationTargetType.user,
      actionType: ModerationActionType.warn,
      reason: reason,
      reportId: reportId,
    );
  }

  /// Approve content (dismiss false reports)
  Future<String> approveContent({
    required String moderatorId,
    required String contentId,
    required ModerationTargetType contentType,
    String? reason,
    String? reportId,
  }) async {
    return takeModerationAction(
      moderatorId: moderatorId,
      targetId: contentId,
      targetType: contentType,
      actionType: ModerationActionType.approve,
      reason: reason,
      reportId: reportId,
    );
  }

  /// Reverse moderation action
  Future<void> reverseModerationAction(String actionId, String moderatorId) async {
    try {
      // Check if moderator has admin permissions
      final hasPermission = await _permissionService.hasPermission(
        moderatorId,
        'moderate_content',
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to reverse moderation action');
      }

      await _actionRepository.deactivateAction(actionId);
    } catch (e) {
      throw Exception('Failed to reverse moderation action: $e');
    }
  }

  /// Check if content is hidden or deleted
  Future<bool> isContentModerated(String contentId, ModerationTargetType contentType) async {
    try {
      return await _actionRepository.isContentHidden(contentId, contentType);
    } catch (e) {
      throw Exception('Failed to check if content is moderated: $e');
    }
  }

  /// Check if user is restricted (suspended or banned)
  Future<bool> isUserRestricted(String userId) async {
    try {
      return await _actionRepository.isUserRestricted(userId);
    } catch (e) {
      throw Exception('Failed to check if user is restricted: $e');
    }
  }

  /// Get user restrictions
  Future<List<ModerationAction>> getUserRestrictions(String userId) async {
    try {
      return await _actionRepository.getUserRestrictions(userId);
    } catch (e) {
      throw Exception('Failed to get user restrictions: $e');
    }
  }

  /// Get moderation statistics for dashboard
  Future<Map<String, dynamic>> getModerationStatistics() async {
    try {
      final reportStats = await _reportRepository.getReportsStatistics();
      final actionStats = await _actionRepository.getModerationStatistics();

      return {
        'reports': reportStats,
        'actions': actionStats,
      };
    } catch (e) {
      throw Exception('Failed to get moderation statistics: $e');
    }
  }

  /// Get actions for a specific target
  Future<List<ModerationAction>> getActionsForTarget(
    String targetId,
    ModerationTargetType targetType,
  ) async {
    try {
      return await _actionRepository.getActionsForTarget(targetId, targetType);
    } catch (e) {
      throw Exception('Failed to get actions for target: $e');
    }
  }

  /// Stream pending reports for real-time updates
  Stream<List<ContentReport>> streamPendingReports() {
    return _reportRepository.streamPendingReports();
  }

  /// Clean up expired moderation actions
  Future<void> cleanupExpiredActions() async {
    try {
      await _actionRepository.cleanupExpiredActions();
    } catch (e) {
      throw Exception('Failed to cleanup expired actions: $e');
    }
  }

  /// Private helper methods

  Future<void> _notifyAdminsOfNewReport(
    String reportId,
    ContentType contentType,
    ReportReason reason,
  ) async {
    try {
      // This would typically get all admin users and send notifications
      // For now, we'll just log the notification
      // In a real implementation, you'd query for admin users and send notifications
      print('New content report: $reportId for ${contentType.name} - ${reason.name}');
    } catch (e) {
      print('Failed to notify admins of new report: $e');
    }
  }

  Future<void> _notifyReporterOfReview(
    ContentReport report,
    ReportStatus newStatus,
  ) async {
    try {
      // Notify the reporter about the review outcome
      print('Report ${report.id} reviewed with status: ${newStatus.name}');
    } catch (e) {
      print('Failed to notify reporter of review: $e');
    }
  }

  Future<void> _notifyUserOfModerationAction(
    String userId,
    ModerationActionType actionType,
    String? reason,
  ) async {
    try {
      // Notify the user about the moderation action taken against them
      print('User $userId received ${actionType.name} action. Reason: $reason');
    } catch (e) {
      print('Failed to notify user of moderation action: $e');
    }
  }
}