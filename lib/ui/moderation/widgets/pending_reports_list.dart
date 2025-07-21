import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/content_report.dart';
import '../../../providers/moderation_providers.dart';

class PendingReportsList extends ConsumerWidget {
  final int? limit;

  const PendingReportsList({
    super.key,
    this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingReportsAsync = ref.watch(pendingReportsStreamProvider);

    return pendingReportsAsync.when(
      data: (reports) {
        final displayReports = limit != null && reports.length > limit!
            ? reports.take(limit!).toList()
            : reports;

        if (displayReports.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending reports',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'All reports have been reviewed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: [
              if (limit != null && reports.length > limit!)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${limit!} of ${reports.length} reports',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to full reports view
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayReports.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = displayReports[index];
                  return _buildReportTile(context, ref, report);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading reports: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, WidgetRef ref, ContentReport report) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getReasonColor(report.reason),
        child: Icon(
          _getReasonIcon(report.reason),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(_getReasonText(report.reason)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${report.contentType.name.toUpperCase()} • ${report.contentId}'),
          if (report.description != null)
            Text(
              report.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            _formatDate(report.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => _showReportDetails(context, report),
            tooltip: 'View Details',
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleReportAction(context, ref, report, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.rate_review, size: 16),
                    SizedBox(width: 8),
                    Text('Start Review'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'hide',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, size: 16),
                    SizedBox(width: 8),
                    Text('Hide Content'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16),
                    SizedBox(width: 8),
                    Text('Delete Content'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dismiss',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 16),
                    SizedBox(width: 8),
                    Text('Dismiss Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getReasonColor(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return Colors.orange;
      case ReportReason.harassment:
        return Colors.red;
      case ReportReason.inappropriateContent:
        return Colors.purple;
      case ReportReason.copyright:
        return Colors.blue;
      case ReportReason.misinformation:
        return Colors.amber;
      case ReportReason.other:
        return Colors.grey;
    }
  }

  IconData _getReasonIcon(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return Icons.block;
      case ReportReason.harassment:
        return Icons.warning;
      case ReportReason.inappropriateContent:
        return Icons.visibility_off;
      case ReportReason.copyright:
        return Icons.copyright;
      case ReportReason.misinformation:
        return Icons.fact_check;
      case ReportReason.other:
        return Icons.help;
    }
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.misinformation:
        return 'Misinformation';
      case ReportReason.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showReportDetails(BuildContext context, ContentReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Content Type', report.contentType.name.toUpperCase()),
              _buildDetailRow('Content ID', report.contentId),
              _buildDetailRow('Reason', _getReasonText(report.reason)),
              if (report.description != null)
                _buildDetailRow('Description', report.description!),
              _buildDetailRow('Reported', report.createdAt.toString()),
              _buildDetailRow('Status', report.status.name.toUpperCase()),
              if (report.reviewedAt != null) ...[
                _buildDetailRow('Reviewed', report.reviewedAt.toString()),
                if (report.reviewNotes != null)
                  _buildDetailRow('Review Notes', report.reviewNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _handleReportAction(BuildContext context, WidgetRef ref, ContentReport report, String action) async {
    final service = ref.read(moderationServiceProvider);
    
    try {
      switch (action) {
        case 'review':
          await service.reviewReport(
            reportId: report.id,
            reviewerId: 'current_user_id', // TODO: Get from auth
            newStatus: ReportStatus.underReview,
          );
          _showSnackBar(context, 'Report moved to under review');
          break;
        case 'hide':
          await service.hideContent(
            moderatorId: 'current_user_id', // TODO: Get from auth
            contentId: report.contentId,
            contentType: _mapContentTypeToModerationTarget(report.contentType),
            reason: 'Hidden due to report: ${_getReasonText(report.reason)}',
            reportId: report.id,
          );
          _showSnackBar(context, 'Content hidden');
          break;
        case 'delete':
          await service.deleteContent(
            moderatorId: 'current_user_id', // TODO: Get from auth
            contentId: report.contentId,
            contentType: _mapContentTypeToModerationTarget(report.contentType),
            reason: 'Deleted due to report: ${_getReasonText(report.reason)}',
            reportId: report.id,
          );
          _showSnackBar(context, 'Content deleted');
          break;
        case 'dismiss':
          await service.reviewReport(
            reportId: report.id,
            reviewerId: 'current_user_id', // TODO: Get from auth
            newStatus: ReportStatus.dismissed,
            reviewNotes: 'Dismissed by admin',
          );
          _showSnackBar(context, 'Report dismissed');
          break;
      }
    } catch (e) {
      _showSnackBar(context, 'Error: $e', isError: true);
    }
  }

  ModerationTargetType _mapContentTypeToModerationTarget(ContentType contentType) {
    switch (contentType) {
      case ContentType.post:
        return ModerationTargetType.post;
      case ContentType.comment:
        return ModerationTargetType.comment;
      case ContentType.submission:
        return ModerationTargetType.submission;
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}