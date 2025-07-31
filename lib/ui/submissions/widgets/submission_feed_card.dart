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
    return LayoutBuilder(
      builder: (context, constraints) {
        // More compact margins on desktop
        final isDesktop = constraints.maxWidth > 768;
        final bottomMargin = isDesktop ? 12.0 : 16.0;

        return Card(
          margin: EdgeInsets.only(bottom: bottomMargin),
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
                _buildHeader(context, isDesktop),

                // Text content if available
                if (submission.textContent?.isNotEmpty == true)
                  _buildTextContent(context, isDesktop),

                // Media content in staggered style
                if (_hasMediaContent()) _buildMediaContent(context, isDesktop),

                // Footer with interaction info
                _buildFooter(context, isDesktop),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final padding = isDesktop ? 12.0 : 16.0; // More compact padding on desktop
    final avatarRadius =
        isDesktop ? 18.0 : 20.0; // Slightly smaller avatar on desktop

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          // Team avatar
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              teamName?.substring(0, 1).toUpperCase() ?? 'T',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14 : 16, // Smaller font on desktop
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

  Widget _buildTextContent(BuildContext context, bool isDesktop) {
    final horizontalPadding = isDesktop ? 12.0 : 16.0;
    final bottomPadding = isDesktop ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, 0, horizontalPadding, bottomPadding),
      child: Text(
        submission.textContent!,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: isDesktop ? 3 : 4, // Fewer lines on desktop for compactness
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, bool isDesktop) {
    final horizontalPadding = isDesktop ? 12.0 : 16.0;
    final bottomPadding = isDesktop ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, 0, horizontalPadding, bottomPadding),
      child: StaggeredMediaFeed(
        submissions: [submission],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDesktop) {
    final hasFiles = submission.allFileUrls.isNotEmpty;
    final fileCount = submission.allFileUrls.length;

    if (!hasFiles && submission.textContent?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    final horizontalPadding = isDesktop ? 12.0 : 16.0;
    final bottomPadding = isDesktop ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, 0, horizontalPadding, bottomPadding),
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

          // View details button - more compact on desktop
          TextButton(
            onPressed: onTap,
            style: isDesktop
                ? TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  )
                : null,
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
