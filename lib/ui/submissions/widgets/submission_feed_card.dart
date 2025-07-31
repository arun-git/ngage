import 'package:flutter/material.dart';
import '../../../models/submission.dart';
import 'staggered_media_feed.dart';
import 'submission_status_indicator.dart';

/// A staggered feed card for displaying submissions with media
class SubmissionFeedCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;
  final bool showTeamInfo;
  final String? teamName;

  const SubmissionFeedCard({
    super.key,
    required this.submission,
    this.onTap,
    this.showTeamInfo = true,
    this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with team info and status
            _buildHeader(context),

            // Text content if available
            if (submission.textContent?.isNotEmpty == true)
              _buildTextContent(context),

            // Media content in staggered style
            if (_hasMediaContent()) _buildMediaContent(context),

            // Footer with interaction info
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Team avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              teamName?.substring(0, 1).toUpperCase() ?? 'T',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Team name and submission time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName ?? 'Team ${submission.teamId}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSubmissionTime(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),

          // Status indicator
          SubmissionStatusIndicator(
            status: submission.status,
            showLabel: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        submission.textContent!,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: StaggeredMediaFeed(
        submissions: [submission],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final hasFiles = submission.allFileUrls.isNotEmpty;
    final fileCount = submission.allFileUrls.length;

    if (!hasFiles && submission.textContent?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (hasFiles) ...[
            Icon(
              Icons.attachment,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              '$fileCount file${fileCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
          const Spacer(),

          // View details button
          TextButton(
            onPressed: onTap,
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  bool _hasMediaContent() {
    return submission.photoUrls.isNotEmpty ||
        submission.videoUrls.isNotEmpty ||
        submission.documentUrls.isNotEmpty;
  }

  String _formatSubmissionTime() {
    final submissionTime = submission.submittedAt ?? submission.createdAt;
    final now = DateTime.now();
    final difference = now.difference(submissionTime);

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
}
