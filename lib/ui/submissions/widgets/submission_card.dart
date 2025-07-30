import 'package:flutter/material.dart';
import '../../../models/submission.dart';
import 'submission_status_indicator.dart';
import 'submission_files_preview.dart';

/// Reusable card widget for displaying submission information
class SubmissionCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;
  final bool showTeamInfo;
  final bool compact;

  const SubmissionCard({
    super.key,
    required this.submission,
    this.onTap,
    this.showTeamInfo = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      showTeamInfo ? 'Team Submission' : 'Submission',
                      style: compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SubmissionStatusIndicator(
                    status: submission.status,
                    showLabel: !compact,
                  ),
                ],
              ),

              if (!compact) ...[
                const SizedBox(height: 8),

                // Submission info
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      submission.submittedAt != null
                          ? 'Submitted ${_formatDate(submission.submittedAt!)}'
                          : 'Created ${_formatDate(submission.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],

              // Content preview
              if (submission.textContent?.isNotEmpty == true) ...[
                SizedBox(height: compact ? 4 : 8),
                Text(
                  submission.textContent!,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              // File previews or counts
              if (submission.allFileUrls.isNotEmpty) ...[
                SizedBox(height: compact ? 4 : 8),
                if (compact)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (submission.photoUrls.isNotEmpty)
                        _buildFileCount(
                          context,
                          Icons.photo,
                          submission.photoUrls.length,
                          'Photos',
                          compact,
                        ),
                      if (submission.videoUrls.isNotEmpty)
                        _buildFileCount(
                          context,
                          Icons.video_file,
                          submission.videoUrls.length,
                          'Videos',
                          compact,
                        ),
                      if (submission.documentUrls.isNotEmpty)
                        _buildFileCount(
                          context,
                          Icons.description,
                          submission.documentUrls.length,
                          'Documents',
                          compact,
                        ),
                    ],
                  )
                else
                  SubmissionFilesPreview(
                    submission: submission,
                    maxPreviewFiles: 3,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCount(
    BuildContext context,
    IconData icon,
    int count,
    String label,
    bool compact,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? 14 : 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          compact ? '$count' : '$count $label',
          style: compact
              ? Theme.of(context).textTheme.bodySmall
              : Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
