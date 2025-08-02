import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/judging_providers.dart';
import '../../providers/submission_providers.dart';
import 'widgets/scoring_form_widget.dart';
import '../submissions/widgets/staggered_media_feed.dart';

/// Screen for judges to evaluate submissions
class JudgeSubmissionScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final String eventId;
  final String judgeId;

  const JudgeSubmissionScreen({
    super.key,
    required this.submissionId,
    required this.eventId,
    required this.judgeId,
  });

  @override
  ConsumerState<JudgeSubmissionScreen> createState() =>
      _JudgeSubmissionScreenState();
}

class _JudgeSubmissionScreenState extends ConsumerState<JudgeSubmissionScreen> {
  @override
  Widget build(BuildContext context) {
    final submissionAsync =
        ref.watch(submissionStreamProvider(widget.submissionId));
    final eventRubricsAsync =
        ref.watch(eventRubricsWithFallbackStreamProvider(widget.eventId));
    final existingScoreAsync =
        ref.watch(judgeScoreProvider((widget.submissionId, widget.judgeId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Judge Submission'),
        elevation: 0,
      ),
      body: submissionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading submission: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(submissionStreamProvider(widget.submissionId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (submission) => eventRubricsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading rubrics: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(
                        eventRubricsWithFallbackStreamProvider(widget.eventId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (rubrics) => submission != null
              ? _buildJudgingInterface(
                  context,
                  submission,
                  rubrics,
                  existingScoreAsync.value,
                )
              : const Center(child: Text('Submission not found')),
        ),
      ),
    );
  }

  Widget _buildJudgingInterface(
    BuildContext context,
    Submission submission,
    List<ScoringRubric> rubrics,
    Score? existingScore,
  ) {
    if (rubrics.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No scoring rubrics available'),
            SizedBox(height: 8),
            Text(
              'No event-specific rubrics or global template found.\nContact the event organizer to set up scoring criteria.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submission details with responsive layout
          _buildSubmissionCard(submission),

          const SizedBox(height: 24),

          // Show info banner if using global template
          if (rubrics.length == 1 &&
              rubrics.first.id == "rubric_1754073446739_51")
            _buildResponsiveContent(
              context,
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using global scoring template (no event-specific rubrics found)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scoring forms for each rubric with responsive layout
          ...rubrics.map((rubric) => Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildResponsiveContent(
                  context,
                  ScoringFormWidget(
                    submissionId: widget.submissionId,
                    eventId: widget.eventId,
                    judgeId: widget.judgeId,
                    rubric: rubric,
                    existingScore: existingScore,
                    onScoreSubmitted: () {
                      // Refresh the score data
                      ref.invalidate(judgeScoreProvider(
                          (widget.submissionId, widget.judgeId)));
                    },
                  ),
                ),
              )),

          // Judge comments section (if not already in rubric) with responsive layout
          if (rubrics.every((r) => r.criteria.isEmpty))
            _buildResponsiveContent(
              context,
              _buildCommentsOnlySection(existingScore),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Submission submission) {
    return _buildResponsiveContent(
      context,
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text content if available
              if (submission.textContent?.isNotEmpty == true) ...[
                Text(
                  submission.textContent!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],

              // Media content in staggered style
              if (_hasMediaContent(submission)) ...[
                StaggeredMediaFeed(
                  submissions: [submission],
                ),
                const SizedBox(height: 16),
              ],

              // File attachments summary
              if (submission.allFileUrls.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attachment,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${submission.allFileUrls.length} file${submission.allFileUrls.length == 1 ? '' : 's'} attached',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submission metadata
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted: ${_formatDateTime(submission.submittedAt ?? submission.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsOnlySection(Score? existingScore) {
    final commentsController = TextEditingController(
      text: existingScore?.comments ?? '',
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Judge Comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments',
                hintText: 'Add your comments about this submission...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(judgingServiceProvider).addJudgeComment(
                        submissionId: widget.submissionId,
                        judgeId: widget.judgeId,
                        eventId: widget.eventId,
                        comment: commentsController.text.trim(),
                      );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comment saved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving comment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Comment'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds responsive content with proper padding for desktop
  Widget _buildResponsiveContent(BuildContext context, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we're on desktop (width > 768px)
        final isDesktop = constraints.maxWidth > 768;

        if (isDesktop) {
          // On desktop, center the content with max width and padding
          final maxWidth = constraints.maxWidth * 0.7; // 70% of available width
          final constrainedWidth =
              maxWidth.clamp(400.0, 900.0); // Min 400px, Max 900px

          return Center(
            child: SizedBox(
              width: constrainedWidth,
              child: child,
            ),
          );
        } else {
          // On mobile, use full width
          return child;
        }
      },
    );
  }

  /// Check if submission has media content
  bool _hasMediaContent(Submission submission) {
    return submission.photoUrls.isNotEmpty ||
        submission.videoUrls.isNotEmpty ||
        submission.documentUrls.isNotEmpty;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
