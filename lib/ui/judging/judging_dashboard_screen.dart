import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/judging_providers.dart';
import '../../providers/event_providers.dart';
import '../../providers/submission_providers.dart';
import '../../providers/member_providers.dart';
import '../../providers/group_providers.dart';
import 'widgets/rubric_management_widget.dart';
import 'widgets/score_aggregation_widget.dart';
import 'widgets/leaderboard_widget.dart';
import 'judge_submission_screen.dart';

/// Comprehensive judging dashboard for event organizers and judges
class JudgingDashboardScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String currentUserId;

  const JudgingDashboardScreen({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  @override
  ConsumerState<JudgingDashboardScreen> createState() =>
      _JudgingDashboardScreenState();
}

class _JudgingDashboardScreenState extends ConsumerState<JudgingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScoringRubric? _selectedRubric;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return _buildErrorScaffold(context, 'Event not found');
        }

        return activeMemberAsync.when(
          data: (member) {
            if (member == null) {
              return _buildErrorScaffold(context, 'Authentication required');
            }

            // Check if current member has judge or admin permissions
            final membershipAsync = ref.watch(groupMembershipProvider((
              groupId: event.groupId,
              memberId: member.id,
            )));

            return membershipAsync.when(
              data: (membership) {
                if (membership == null || !membership.canJudge) {
                  return _buildAccessDeniedScaffold(context);
                }

                return _buildJudgingDashboard(context, event, membership.role);
              },
              loading: () => _buildLoadingScaffold(context),
              error: (error, _) => _buildErrorScaffold(
                  context, 'Error checking permissions: $error'),
            );
          },
          loading: () => _buildLoadingScaffold(context),
          error: (error, _) =>
              _buildErrorScaffold(context, 'Authentication error: $error'),
        );
      },
      loading: () => _buildLoadingScaffold(context),
      error: (error, _) =>
          _buildErrorScaffold(context, 'Error loading event: $error'),
    );
  }

  Widget _buildJudgingDashboard(
      BuildContext context, Event event, GroupRole userRole) {
    final eventStatsAsync =
        ref.watch(eventScoringStatsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Judging: ${event.title}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.rule), text: 'Rubrics'),
            Tab(icon: Icon(Icons.assignment), text: 'Submissions'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              ref.refresh(eventSubmissionsStreamProvider(widget.eventId));
              ref.refresh(eventScoringStatsProvider(widget.eventId));
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh submissions',
          ),
          // Event statistics chip
          eventStatsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                avatar: const Icon(Icons.score, size: 16),
                label: Text('${stats['totalScores'] ?? 0} scores'),
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRubricsTab(),
          _buildSubmissionsTab(),
          _buildAnalyticsTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildRubricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RubricManagementWidget(
            eventId: widget.eventId,
            createdBy: widget.currentUserId,
            onRubricSelected: (rubric) {
              setState(() => _selectedRubric = rubric);
            },
          ),
          if (_selectedRubric != null) ...[
            const SizedBox(height: 24),
            _buildSelectedRubricCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedRubricCard() {
    if (_selectedRubric == null) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Selected Rubric: ${_selectedRubric!.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_selectedRubric!.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('${_selectedRubric!.criteria.length} criteria'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
                Chip(
                  label: Text(
                      'Max: ${_selectedRubric!.maxPossibleScore.toInt()} pts'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
                if (_selectedRubric!.isTemplate)
                  const Chip(
                    label: Text('Template'),
                    backgroundColor: Colors.purple,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final submissionsAsync =
        ref.watch(eventSubmissionsStreamProvider(widget.eventId));

    return submissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading submissions: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(eventSubmissionsStreamProvider(widget.eventId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (submissions) => _buildSubmissionsList(submissions),
    );
  }

  Widget _buildSubmissionsList(List<Submission> submissions) {
    final submittedSubmissions = submissions
        .where((s) =>
            s.status == SubmissionStatus.submitted ||
            s.status == SubmissionStatus.approved)
        .toList();

    if (submittedSubmissions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No submissions to judge yet'),
            Text(
              'Submissions will appear here once teams submit their entries.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: submittedSubmissions.length,
      itemBuilder: (context, index) {
        final submission = submittedSubmissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(Submission submission) {
    final hasJudgeScoredAsync = ref
        .watch(hasJudgeScoredProvider((submission.id, widget.currentUserId)));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team ${submission.teamId}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${_formatDateTime(submission.submittedAt ?? submission.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildSubmissionStatusChip(submission.status),
              ],
            ),

            const SizedBox(height: 12),

            // Submission content preview
            if (submission.content.isNotEmpty) ...[
              Text(
                'Content:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              ...submission.content.entries
                  .take(3)
                  .map((entry) => SelectableText(
                        '${entry.key}: ${entry.value.toString()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )),
              if (submission.content.length > 3)
                SelectableText(
                  '... and ${submission.content.length - 3} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              const SizedBox(height: 12),
            ],

            // Judge status and actions
            hasJudgeScoredAsync.when(
              data: (hasScored) => Row(
                children: [
                  if (hasScored)
                    const Chip(
                      avatar: Icon(Icons.check, size: 16),
                      label: Text('You have scored this'),
                      backgroundColor: Colors.green,
                    )
                  else
                    const Chip(
                      avatar: Icon(Icons.pending, size: 16),
                      label: Text('Pending your score'),
                      backgroundColor: Colors.orange,
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToJudgeSubmission(submission),
                    icon: Icon(hasScored ? Icons.edit : Icons.score),
                    label: Text(hasScored ? 'Edit Score' : 'Score Now'),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading judge status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatusChip(SubmissionStatus status) {
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

  Widget _buildAnalyticsTab() {
    final submissionsAsync =
        ref.watch(eventSubmissionsStreamProvider(widget.eventId));

    return submissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (submissions) {
        final submittedSubmissions = submissions
            .where((s) =>
                s.status == SubmissionStatus.submitted ||
                s.status == SubmissionStatus.approved)
            .toList();

        if (submittedSubmissions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No analytics available yet'),
                Text(
                  'Analytics will appear once submissions are scored.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: submittedSubmissions.length,
          itemBuilder: (context, index) {
            final submission = submittedSubmissions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team ${submission.teamId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ScoreAggregationWidget(
                    submissionId: submission.id,
                    showIndividualScores: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: LeaderboardWidget(
        eventId: widget.eventId,
        showCriteriaBreakdown: true,
      ),
    );
  }

  void _navigateToJudgeSubmission(Submission submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JudgeSubmissionScreen(
          submissionId: submission.id,
          eventId: widget.eventId,
          judgeId: widget.currentUserId,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judging Dashboard'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judging Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judging Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You need admin or judge permissions to access the judging dashboard.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your group administrator to request judge permissions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
