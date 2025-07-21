import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/judging_providers.dart';
import '../../providers/submission_providers.dart';
import 'widgets/scoring_form_widget.dart';

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
  ConsumerState<JudgeSubmissionScreen> createState() => _JudgeSubmissionScreenState();
}

class _JudgeSubmissionScreenState extends ConsumerState<JudgeSubmissionScreen> {
  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(submissionProvider(widget.submissionId));
    final eventRubricsAsync = ref.watch(eventRubricsProvider(widget.eventId));
    final existingScoreAsync = ref.watch(judgeScoreProvider(
      widget.submissionId, 
      widget.judgeId,
    ));

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
                onPressed: () => ref.refresh(submissionProvider(widget.submissionId)),
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
                  onPressed: () => ref.refresh(eventRubricsProvider(widget.eventId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (rubrics) => _buildJudgingInterface(
            context, 
            submission, 
            rubrics, 
            existingScoreAsync.value,
          ),
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
            Text('No scoring rubrics available for this event'),
            SizedBox(height: 8),
            Text(
              'Contact the event organizer to set up scoring criteria',
              style: TextStyle(color: Colors.grey),
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
          // Submission details
          _buildSubmissionCard(submission),
          
          const SizedBox(height: 24),
          
          // Scoring forms for each rubric
          ...rubrics.map((rubric) => Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: ScoringFormWidget(
              submissionId: widget.submissionId,
              eventId: widget.eventId,
              judgeId: widget.judgeId,
              rubric: rubric,
              existingScore: existingScore,
              onScoreSubmitted: () {
                // Refresh the score data
                ref.refresh(judgeScoreProvider(
                  widget.submissionId, 
                  widget.judgeId,
                ));
              },
            ),
          )),
          
          // Judge comments section (if not already in rubric)
          if (rubrics.every((r) => r.criteria.isEmpty)) 
            _buildCommentsOnlySection(existingScore),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Submission submission) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Submission Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildStatusChip(submission.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Submission content
            if (submission.content.isNotEmpty) ...[
              Text(
                'Content:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...submission.content.entries.map((entry) => 
                _buildContentItem(entry.key, entry.value)
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
    );
  }

  Widget _buildStatusChip(SubmissionStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case SubmissionStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case SubmissionStatus.submitted:
        color = Colors.blue;
        label = 'Submitted';
        break;
      case SubmissionStatus.underReview:
        color = Colors.orange;
        label = 'Under Review';
        break;
      case SubmissionStatus.approved:
        color = Colors.green;
        label = 'Approved';
        break;
      case SubmissionStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildContentItem(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$key:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsOnlySection(Score? existingScore) {
    final commentsController = TextEditingController(
      text: existingScore?.comments ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judge Comments',
              style: Theme.of(context).textTheme.titleMedium,
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
            ElevatedButton(
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
              child: const Text('Save Comment'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}