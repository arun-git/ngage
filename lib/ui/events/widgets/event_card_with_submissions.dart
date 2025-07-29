import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event.dart';
import '../../../models/submission.dart';
import '../../../models/enums.dart';
import '../../../providers/event_submission_integration_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../services/event_submission_integration_service.dart';
import '../../submissions/widgets/deadline_countdown_widget.dart';
import '../../submissions/widgets/deadline_status_widget.dart';
import '../../submissions/submission_screen.dart';
import '../../submissions/submissions_list_screen.dart';

/// Enhanced event card that displays submission information and status
class EventCardWithSubmissions extends ConsumerWidget {
  final Event event;
  final String? teamId; // If provided, shows team-specific submission status
  final bool isAdminView; // Shows admin-specific information
  final VoidCallback? onTap;

  const EventCardWithSubmissions({
    super.key,
    required this.event,
    this.teamId,
    this.isAdminView = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isAdminView) {
      return _buildAdminCard(context, ref);
    } else if (teamId != null) {
      return _buildTeamCard(context, ref);
    } else {
      return _buildGeneralCard(context, ref);
    }
  }

  Widget _buildAdminCard(BuildContext context, WidgetRef ref) {
    final eventStatsAsync =
        ref.watch(eventWithSubmissionStatsProvider(event.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildEventStatusChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Deadline information
              if (event.submissionDeadline != null) ...[
                DeadlineStatusWidget(
                  event: event,
                  showTime: true,
                ),
                const SizedBox(height: 8),
              ],

              // Submission statistics
              eventStatsAsync.when(
                data: (stats) => _buildSubmissionStats(context, stats),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text(
                  'Error loading stats: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewSubmissions(context),
                    icon: const Icon(Icons.list, size: 16),
                    label: const Text('View Submissions'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _manageEvent(context),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Manage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, WidgetRef ref) {
    final teamSubmissionAsync = ref.watch(teamSubmissionForEventProvider((
      eventId: event.id,
      teamId: teamId!,
    )));
    final canSubmitAsync = ref.watch(canTeamSubmitToEventProvider((
      eventId: event.id,
      teamId: teamId!,
    )));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildEventStatusChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Team submission status
              teamSubmissionAsync.when(
                data: (submission) =>
                    _buildTeamSubmissionStatus(context, submission),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text(
                  'Error loading submission: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

              const SizedBox(height: 8),

              // Deadline countdown
              if (event.submissionDeadline != null) ...[
                DeadlineCountdownWidget(
                  event: event,
                  compact: true,
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                children: [
                  canSubmitAsync.when(
                    data: (canSubmit) => teamSubmissionAsync.when(
                      data: (submission) => _buildTeamActionButton(
                        context,
                        submission,
                        canSubmit,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _viewEventDetails(context),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralCard(BuildContext context, WidgetRef ref) {
    final eventStatsAsync =
        ref.watch(eventWithSubmissionStatsProvider(event.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildEventStatusChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Basic submission info
              eventStatsAsync.when(
                data: (stats) => _buildBasicSubmissionInfo(context, stats),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text(
                  'Error loading info: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

              // Deadline information
              if (event.submissionDeadline != null) ...[
                const SizedBox(height: 8),
                DeadlineStatusWidget(
                  event: event,
                  showTime: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventStatusChip(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (event.status) {
      case EventStatus.draft:
        statusColor = Colors.grey;
        statusText = 'Draft';
        break;
      case EventStatus.scheduled:
        statusColor = Colors.blue;
        statusText = 'Scheduled';
        break;
      case EventStatus.active:
        statusColor = Colors.green;
        statusText = 'Active';
        break;
      case EventStatus.completed:
        statusColor = Colors.purple;
        statusText = 'Completed';
        break;
      case EventStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSubmissionStats(
      BuildContext context, EventWithSubmissionStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submissions',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatChip(context, 'Total', stats.totalSubmissions.toString(),
                Colors.blue),
            const SizedBox(width: 8),
            _buildStatChip(context, 'Submitted',
                stats.submittedSubmissions.toString(), Colors.green),
            const SizedBox(width: 8),
            _buildStatChip(context, 'Draft', stats.draftSubmissions.toString(),
                Colors.orange),
          ],
        ),
        if (stats.underReviewSubmissions > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(context, 'Under Review',
                  stats.underReviewSubmissions.toString(), Colors.purple),
              const SizedBox(width: 8),
              _buildStatChip(context, 'Approved',
                  stats.approvedSubmissions.toString(), Colors.green),
              const SizedBox(width: 8),
              _buildStatChip(context, 'Rejected',
                  stats.rejectedSubmissions.toString(), Colors.red),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBasicSubmissionInfo(
      BuildContext context, EventWithSubmissionStats stats) {
    return Row(
      children: [
        Icon(
          Icons.assignment,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          '${stats.submittedSubmissions} submission${stats.submittedSubmissions == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (stats.hasPendingReviews) ...[
          const SizedBox(width: 16),
          const Icon(
            Icons.pending,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '${stats.underReviewSubmissions} pending review',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamSubmissionStatus(
      BuildContext context, Submission? submission) {
    if (submission == null) {
      return Row(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            'No submission yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (submission.status) {
      case SubmissionStatus.draft:
        statusColor = Colors.orange;
        statusIcon = Icons.edit;
        statusText = 'Draft in progress';
        break;
      case SubmissionStatus.submitted:
        statusColor = Colors.blue;
        statusIcon = Icons.send;
        statusText = 'Submitted';
        break;
      case SubmissionStatus.underReview:
        statusColor = Colors.purple;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Under review';
        break;
      case SubmissionStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case SubmissionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return Row(
      children: [
        Icon(
          statusIcon,
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
              ),
        ),
        if (submission.submittedAt != null) ...[
          const SizedBox(width: 8),
          Text(
            '• ${_formatDate(submission.submittedAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildTeamActionButton(
      BuildContext context, Submission? submission, bool canSubmit) {
    if (submission == null && canSubmit) {
      return ElevatedButton.icon(
        onPressed: () => _createSubmission(context),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Start Submission'),
      );
    } else if (submission != null && submission.canBeEdited) {
      return ElevatedButton.icon(
        onPressed: () => _editSubmission(context, submission),
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Continue'),
      );
    } else if (submission != null) {
      return TextButton.icon(
        onPressed: () => _viewSubmission(context, submission),
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('View'),
      );
    } else {
      return TextButton.icon(
        onPressed: null,
        icon: const Icon(Icons.block, size: 16),
        label: const Text('Cannot Submit'),
      );
    }
  }

  Widget _buildStatChip(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
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

  void _viewSubmissions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionsListScreen(
          eventId: event.id,
          isJudgeView: true,
        ),
      ),
    );
  }

  void _manageEvent(BuildContext context) {
    // Navigate to event management screen
    // This would be implemented based on your navigation structure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Event management for "${event.title}" - Feature coming soon'),
      ),
    );
  }

  void _createSubmission(BuildContext context) {
    if (teamId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final currentMember = ref.watch(currentMemberProvider);
            if (currentMember == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Authentication required'),
                ),
              );
            }

            return SubmissionScreen(
              eventId: event.id,
              teamId: teamId!,
              memberId: currentMember.id,
            );
          },
        ),
      ),
    );
  }

  void _editSubmission(BuildContext context, Submission submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: event.id,
          teamId: submission.teamId,
          memberId: submission.submittedBy,
          submissionId: submission.id,
        ),
      ),
    );
  }

  void _viewSubmission(BuildContext context, Submission submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: event.id,
          teamId: submission.teamId,
          memberId: submission.submittedBy,
          submissionId: submission.id,
        ),
      ),
    );
  }

  void _viewEventDetails(BuildContext context) {
    // Navigate to event details screen
    // This would be implemented based on your navigation structure
    // For now, show a snackbar - you would navigate to EventDetailInnerPage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Event details for "${event.title}" - Feature coming soon'),
      ),
    );
  }
}
