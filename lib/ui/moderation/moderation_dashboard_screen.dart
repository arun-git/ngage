import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/content_report.dart';
import '../../providers/moderation_providers.dart';
import 'widgets/moderation_stats_card.dart';
import 'widgets/pending_reports_list.dart';
import 'widgets/moderation_actions_list.dart';

class ModerationDashboardScreen extends ConsumerStatefulWidget {
  const ModerationDashboardScreen({super.key});

  @override
  ConsumerState<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends ConsumerState<ModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moderationStats = ref.watch(moderationStatisticsProvider);
    final pendingReportsCount = ref.watch(pendingReportsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              text: 'Dashboard',
              icon: Icon(Icons.dashboard),
            ),
            Tab(
              text: 'Reports',
              icon: Badge(
                label: pendingReportsCount.when(
                  data: (count) => Text(count.toString()),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                child: const Icon(Icons.report),
              ),
            ),
            const Tab(
              text: 'Actions',
              icon: Icon(Icons.gavel),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(moderationStats),
          _buildReportsTab(),
          _buildActionsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(AsyncValue<Map<String, dynamic>> moderationStats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          moderationStats.when(
            data: (stats) => ModerationStatsCard(stats: stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading statistics: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const PendingReportsList(limit: 5),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Under Review'),
              Tab(text: 'Resolved'),
              Tab(text: 'Dismissed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildReportsList(ReportStatus.pending),
                _buildReportsList(ReportStatus.underReview),
                _buildReportsList(ReportStatus.resolved),
                _buildReportsList(ReportStatus.dismissed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(ReportStatus status) {
    final reportsAsync = ref.watch(reportsByStatusProvider(status));

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.name} reports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'Reported ${_formatDate(report.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: status == ReportStatus.pending
                    ? PopupMenuButton<String>(
                        onSelected: (action) => _handleReportAction(report, action),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'review',
                            child: Text('Start Review'),
                          ),
                          const PopupMenuItem(
                            value: 'resolve',
                            child: Text('Mark Resolved'),
                          ),
                          const PopupMenuItem(
                            value: 'dismiss',
                            child: Text('Dismiss'),
                          ),
                        ],
                      )
                    : null,
                onTap: () => _showReportDetails(report),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading reports: $error'),
      ),
    );
  }

  Widget _buildActionsTab() {
    return const ModerationActionsList();
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

  void _handleReportAction(ContentReport report, String action) {
    switch (action) {
      case 'review':
        _startReview(report);
        break;
      case 'resolve':
        _resolveReport(report);
        break;
      case 'dismiss':
        _dismissReport(report);
        break;
    }
  }

  void _startReview(ContentReport report) async {
    try {
      final service = ref.read(moderationServiceProvider);
      await service.reviewReport(
        reportId: report.id,
        reviewerId: 'current_user_id', // TODO: Get from auth
        newStatus: ReportStatus.underReview,
      );
      
      ref.invalidate(reportsByStatusProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report moved to under review')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _resolveReport(ContentReport report) async {
    try {
      final service = ref.read(moderationServiceProvider);
      await service.reviewReport(
        reportId: report.id,
        reviewerId: 'current_user_id', // TODO: Get from auth
        newStatus: ReportStatus.resolved,
        reviewNotes: 'Resolved by admin',
      );
      
      ref.invalidate(reportsByStatusProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _dismissReport(ContentReport report) async {
    try {
      final service = ref.read(moderationServiceProvider);
      await service.reviewReport(
        reportId: report.id,
        reviewerId: 'current_user_id', // TODO: Get from auth
        newStatus: ReportStatus.dismissed,
        reviewNotes: 'Dismissed by admin',
      );
      
      ref.invalidate(reportsByStatusProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showReportDetails(ContentReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${report.contentType.name}'),
            Text('Reason: ${_getReasonText(report.reason)}'),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              const Text('Description:'),
              Text(report.description!),
            ],
            const SizedBox(height: 8),
            Text('Reported: ${report.createdAt}'),
            if (report.reviewedAt != null) ...[
              Text('Reviewed: ${report.reviewedAt}'),
              if (report.reviewNotes != null)
                Text('Notes: ${report.reviewNotes}'),
            ],
          ],
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
}