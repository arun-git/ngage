import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/submission_providers.dart';
import '../../providers/judging_providers.dart';

import '../../providers/member_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/team_providers.dart';
import '../widgets/event_banner_image.dart';
import '../submissions/widgets/deadline_countdown_widget.dart';
import '../submissions/widgets/deadline_status_widget.dart';
import '../submissions/widgets/submission_feed_card.dart';

import '../submissions/submission_screen.dart';
import '../../services/submission_navigation_service.dart';

import '../judging/widgets/rubric_management_widget.dart';
import '../judging/widgets/score_aggregation_widget.dart';
import '../judging/widgets/leaderboard_widget.dart';
import '../judging/judge_submission_screen.dart';

/// Inner page showing event details that replaces the group content
class EventDetailInnerPage extends ConsumerWidget {
  final String eventId;
  final String groupName;
  final VoidCallback onBack;

  const EventDetailInnerPage({
    super.key,
    required this.eventId,
    required this.groupName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventStreamProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return _buildNotFoundContent(context);
        }

        // Check if event is draft and user has admin access
        if (event.isDraft) {
          return _buildDraftEventWithAdminCheck(context, ref, event);
        }

        return _buildEventDetailContent(context, ref, event);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorContent(context, error),
    );
  }

  Widget _buildEventDetailContent(
      BuildContext context, WidgetRef ref, Event event) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: false,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildExpandedHeader(context, event),
                collapseMode: CollapseMode.parallax,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            if (event.judgingCriteria.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildJudgingSection(context, event),
                ),
              ),
          ];
        },
        body: _buildSubmissionsSection(context, ref, event),
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context, Event event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // Account for status bar

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner image on the left
              if (event.bannerImageUrl != null) ...[
                Container(
                  width: 120,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: EventBannerImage(
                      imageUrl: event.bannerImageUrl!,
                      width: 120,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Event info on the right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with Submit Entry button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        if (event.status == EventStatus.active) ...[
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, child) {
                              return ElevatedButton.icon(
                                onPressed: () =>
                                    _createSubmission(context, ref, event),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Submit Entry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Scheduling information
                    _buildCompactScheduling(context, event, isExpanded: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactScheduling(BuildContext context, Event event,
      {bool isExpanded = false}) {
    final textColor = isExpanded ? Colors.white.withOpacity(0.9) : null;
    final iconColor = isExpanded ? Colors.white : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.startTime != null) ...[
          _buildCompactScheduleItem(
            context,
            icon: Icons.play_arrow,
            label: 'Start',
            value: _formatDateTime(event.startTime!),
            color: isExpanded ? Colors.white : Colors.green,
            textColor: textColor,
          ),
          const SizedBox(height: 8),
        ],
        if (event.endTime != null) ...[
          _buildCompactScheduleItem(
            context,
            icon: Icons.stop,
            label: 'End',
            value: _formatDateTime(event.endTime!),
            color: isExpanded ? Colors.white : Colors.red,
            textColor: textColor,
          ),
          const SizedBox(height: 8),
        ],
        if (event.submissionDeadline != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildCompactScheduleItem(
                  context,
                  icon: Icons.access_time,
                  label: 'Deadline',
                  value: _formatDateTime(event.submissionDeadline!),
                  color: isExpanded ? Colors.white : Colors.orange,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 8),
              if (!isExpanded)
                DeadlineStatusWidget(
                  event: event,
                  showTime: false,
                ),
            ],
          ),
        ],
        if (event.startTime == null && event.endTime == null) ...[
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: iconColor ?? Theme.of(context).colorScheme.outline,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Not scheduled',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor ?? Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactScheduleItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor ?? Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildJudgingSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judging Criteria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...event.judgingCriteria.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsSection(
      BuildContext context, WidgetRef ref, Event event) {
    return _buildJudgingDashboardContent(context, ref, event);
  }

  Widget _buildJudgingDashboardContent(
      BuildContext context, WidgetRef ref, Event event) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) return const SizedBox.shrink();

        // Show dashboard tabs for all members
        return _buildEventDashboardTabs(context, ref, event, member.id);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('Error loading member information')),
    );
  }

  Widget _buildEventDashboardTabs(
      BuildContext context, WidgetRef ref, Event event, String currentUserId) {
    // Check if current user is admin to conditionally show rubrics tab
    final membershipAsync = ref.watch(groupMembershipProvider((
      groupId: event.groupId,
      memberId: currentUserId,
    )));

    return membershipAsync.when(
      data: (membership) {
        final isAdmin = membership?.isAdmin ?? false;
        final tabCount = isAdmin ? 4 : 3;

        return DefaultTabController(
          length: tabCount,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: TabBar(
                  tabs: [
                    const Tab(
                        icon: Icon(Icons.assignment), text: 'Submissions'),
                    const Tab(icon: Icon(Icons.leaderboard), text: 'Scores'),
                    const Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                    if (isAdmin)
                      const Tab(icon: Icon(Icons.rule), text: 'Rubrics'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.outline,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildEventSubmissionsTab(
                        context, ref, event.id, currentUserId),
                    _buildLeaderboardTab(context, ref, event.id),
                    _buildAnalyticsTab(context, ref, event.id),
                    if (isAdmin)
                      _buildRubricsTab(context, ref, event.id, currentUserId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading permissions')),
    );
  }

  void _viewSubmissionDetails(BuildContext context, Submission submission) {
    // Navigate directly to the specific submission screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: submission.eventId,
          teamId: submission.teamId,
          memberId: submission.submittedBy,
          submissionId: submission.id,
        ),
      ),
    );
  }

  void _createSubmission(BuildContext context, WidgetRef ref, Event event) {
    final activeMemberAsync = ref.read(activeMemberProvider);

    activeMemberAsync.when(
      data: (member) {
        if (member == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please log in to create a submission')),
          );
          return;
        }

        // Get member's teams and find the one for this group
        final memberTeamsAsync = ref.read(memberTeamsProvider(member.id));

        memberTeamsAsync.when(
          data: (teams) {
            // Find the team that belongs to this event's group
            final groupTeams =
                teams.where((team) => team.groupId == event.groupId).toList();
            final groupTeam = groupTeams.isNotEmpty ? groupTeams.first : null;

            if (groupTeam == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'You must be part of a team in this group to create a submission')),
              );
              return;
            }

            SubmissionNavigationService.showSubmissionActionDialog(
              context,
              event: event,
              teamId: groupTeam.id,
              memberId: member.id,
            );
          },
          loading: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loading team information...')),
            );
          },
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      SelectableText('Error loading team information: $error')),
            );
          },
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading user information...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user information: $error')),
        );
      },
    );
  }

  Widget _buildRubricsTab(BuildContext context, WidgetRef ref, String eventId,
      String currentUserId) {
    // Since this tab is only shown to admins, we can directly show the rubric management
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RubricManagementWidget(
              eventId: eventId,
              createdBy: currentUserId,
              onRubricSelected: (rubric) {
                // Handle rubric selection if needed
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSubmissionsTab(BuildContext context, WidgetRef ref,
      String eventId, String currentUserId) {
    final submissionsAsync = ref.watch(eventSubmissionsStreamProvider(eventId));
    final eventAsync = ref.watch(eventStreamProvider(eventId));

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
                  ref.refresh(eventSubmissionsStreamProvider(eventId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (submissions) => eventAsync.when(
        data: (event) => event != null
            ? _buildEventSubmissionsList(
                context, ref, submissions, currentUserId, eventId, event)
            : const Center(child: Text('Event not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading event')),
      ),
    );
  }

  Widget _buildEventSubmissionsList(
      BuildContext context,
      WidgetRef ref,
      List<Submission> submissions,
      String currentUserId,
      String eventId,
      Event event) {
    // Check if current user can judge
    final membershipAsync = ref.watch(groupMembershipProvider((
      groupId: event.groupId,
      memberId: currentUserId,
    )));

    return membershipAsync.when(
      data: (membership) {
        final canJudge = membership?.canJudge ?? false;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deadline countdown if active (for all users)
              if (event.submissionDeadline != null &&
                  event.status == EventStatus.active) ...[
                DeadlineCountdownWidget(
                  event: event,
                  compact: true,
                ),
                const SizedBox(height: 16),
              ],

              // Submissions list
              Expanded(
                child: _buildSubmissionsListContent(context, ref, submissions,
                    currentUserId, eventId, canJudge),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading permissions')),
    );
  }

  Widget _buildSubmissionsListContent(
      BuildContext context,
      WidgetRef ref,
      List<Submission> submissions,
      String currentUserId,
      String eventId,
      bool canJudge) {
    final submittedSubmissions = submissions
        .where((s) =>
            s.status == SubmissionStatus.submitted ||
            s.status == SubmissionStatus.approved)
        .toList();

    if (submittedSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(canJudge
                ? 'No submissions to judge yet'
                : 'No submissions yet'),
            Text(
              canJudge
                  ? 'Submissions will appear here once teams submit their entries.'
                  : 'Be the first to submit an entry for this event!',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Use staggered media view for both judge and regular member views
    return _buildResponsiveContent(
      context,
      ListView(
        children: [
          // Summary info with role-specific messaging
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  canJudge ? Icons.gavel : Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  canJudge
                      ? '${submittedSubmissions.length} submission${submittedSubmissions.length == 1 ? '' : 's'} to judge'
                      : '${submittedSubmissions.length} submission${submittedSubmissions.length == 1 ? '' : 's'} received',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Individual submission feed cards with role-specific actions
          ...submittedSubmissions
              .map((submission) => _buildSubmissionFeedCardWithActions(
                    context,
                    ref,
                    submission,
                    currentUserId,
                    eventId,
                    canJudge,
                  ))
              .toList(),
        ],
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
          final maxWidth = constraints.maxWidth * 0.6; // 60% of available width
          final constrainedWidth =
              maxWidth.clamp(400.0, 800.0); // Min 400px, Max 800px

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

  /// Builds submission feed card with role-specific actions and info
  Widget _buildSubmissionFeedCardWithActions(
      BuildContext context,
      WidgetRef ref,
      Submission submission,
      String currentUserId,
      String eventId,
      bool canJudge) {
    return Column(
      children: [
        // Base submission feed card
        SubmissionFeedCard(
          submission: submission,
          showTeamInfo: true,
          teamName: _getTeamName(ref, submission.teamId),
          onTap: () => _viewSubmissionDetails(context, submission),
        ),

        // Role-specific actions and info
        if (canJudge) ...[
          const SizedBox(height: 8),
          _buildJudgeActionsCard(
              context, ref, submission, currentUserId, eventId),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds judge-specific actions card that appears below the submission feed card
  Widget _buildJudgeActionsCard(BuildContext context, WidgetRef ref,
      Submission submission, String currentUserId, String eventId) {
    // Get event to check group membership
    final eventAsync = ref.watch(eventStreamProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) return const SizedBox.shrink();

        // Check if current user can judge
        final membershipAsync = ref.watch(groupMembershipProvider((
          groupId: event.groupId,
          memberId: currentUserId,
        )));

        return membershipAsync.when(
          data: (membership) {
            final canJudge = membership?.canJudge ?? false;

            if (!canJudge) {
              return const SizedBox.shrink();
            }

            // Show judge actions
            final hasJudgeScoredAsync = ref
                .watch(hasJudgeScoredProvider((submission.id, currentUserId)));

            return hasJudgeScoredAsync.when(
              data: (hasScored) => Card(
                margin: EdgeInsets.zero,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Judge status chip
                      if (hasScored)
                        Chip(
                          avatar: const Icon(Icons.check, size: 16),
                          label: const Text('Scored'),
                          backgroundColor: Colors.green.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        )
                      else
                        Chip(
                          avatar: const Icon(Icons.pending, size: 16),
                          label: const Text('Pending Score'),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),

                      const Spacer(),

                      // Judge action button
                      ElevatedButton.icon(
                        onPressed: () => _navigateToJudgeSubmission(
                            context, submission, eventId, currentUserId),
                        icon: Icon(
                          hasScored ? Icons.edit : Icons.score,
                          size: 16,
                        ),
                        label: Text(
                          hasScored ? 'Edit Score' : 'Score Now',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAnalyticsTab(
      BuildContext context, WidgetRef ref, String eventId) {
    final submissionsAsync = ref.watch(eventSubmissionsStreamProvider(eventId));

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

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: submittedSubmissions.map((submission) {
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
          }).toList(),
        );
      },
    );
  }

  Widget _buildLeaderboardTab(
      BuildContext context, WidgetRef ref, String eventId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LeaderboardWidget(
        eventId: eventId,
        showCriteriaBreakdown: true,
      ),
    );
  }

  void _navigateToJudgeSubmission(BuildContext context, Submission submission,
      String eventId, String judgeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JudgeSubmissionScreen(
          submissionId: submission.id,
          eventId: eventId,
          judgeId: judgeId,
        ),
      ),
    );
  }

  Widget _buildNotFoundContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64),
          const SizedBox(height: 16),
          const Text('Event not found'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('Back to Events'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading event',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('Back to Events'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  /// Check if any submissions have media files
  bool _hasAnyMediaFiles(List<Submission> submissions) {
    return submissions.any((submission) =>
        submission.photoUrls.isNotEmpty ||
        submission.videoUrls.isNotEmpty ||
        submission.documentUrls.isNotEmpty);
  }

  /// Get team name for display (placeholder implementation)
  String? _getTeamName(WidgetRef ref, String teamId) {
    final teamAsync = ref.watch(teamProvider(teamId));
    return teamAsync.when(
      data: (team) => team?.name,
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// Build draft event with admin access check
  Widget _buildDraftEventWithAdminCheck(
      BuildContext context, WidgetRef ref, Event event) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) {
          return _buildAccessDeniedContent(context);
        }

        // Check if current member is an admin in this group
        final isAdminAsync = ref.watch(isGroupAdminProvider((
          groupId: event.groupId,
          memberId: member.id,
        )));

        return isAdminAsync.when(
          data: (isAdmin) {
            if (isAdmin) {
              // Admin can see draft events
              return _buildEventDetailContent(context, ref, event);
            } else {
              // Non-admin cannot see draft events
              return _buildAccessDeniedContent(context);
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildAccessDeniedContent(context),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildAccessDeniedContent(context),
    );
  }

  /// Build access denied content for non-admin users trying to view draft events
  Widget _buildAccessDeniedContent(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 24),
              Text(
                'Admin Access Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This event is currently in draft status and is only visible to group administrators.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact a group administrator if you need access to this event.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced Schedule Event Dialog with better UX and validation
class _ScheduleEventDialog extends ConsumerStatefulWidget {
  final Event event;
  final VoidCallback? onScheduled;

  const _ScheduleEventDialog({
    required this.event,
    this.onScheduled,
  });

  @override
  ConsumerState<_ScheduleEventDialog> createState() =>
      _ScheduleEventDialogState();
}

class _ScheduleEventDialogState extends ConsumerState<_ScheduleEventDialog> {
  late DateTime startTime;
  late DateTime endTime;
  DateTime? submissionDeadline;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // Initialize with existing times or smart defaults
    startTime = widget.event.startTime ?? now.add(const Duration(hours: 1));
    endTime = widget.event.endTime ?? startTime.add(const Duration(hours: 2));
    submissionDeadline = widget.event.submissionDeadline;

    // Ensure end time is after start time
    if (endTime.isBefore(startTime)) {
      endTime = startTime.add(const Duration(hours: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Schedule Event'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEventTypeLabel(widget.event.eventType).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Start time
              _buildDateTimeField(
                context,
                label: 'Start Time',
                value: startTime,
                onChanged: (newTime) {
                  setState(() {
                    startTime = newTime;
                    // Ensure end time is after start time
                    if (endTime.isBefore(startTime)) {
                      endTime = startTime.add(const Duration(hours: 2));
                    }
                    _errorMessage = null;
                  });
                },
                icon: Icons.play_arrow,
                color: Colors.green,
              ),

              const SizedBox(height: 16),

              // End time
              _buildDateTimeField(
                context,
                label: 'End Time',
                value: endTime,
                onChanged: (newTime) {
                  setState(() {
                    endTime = newTime;
                    _errorMessage = null;
                  });
                },
                icon: Icons.stop,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              // Submission deadline (optional)
              _buildOptionalDateTimeField(
                context,
                label: 'Submission Deadline (Optional)',
                value: submissionDeadline,
                onChanged: (newTime) {
                  setState(() {
                    submissionDeadline = newTime;
                    _errorMessage = null;
                  });
                },
                onCleared: () {
                  setState(() {
                    submissionDeadline = null;
                    _errorMessage = null;
                  });
                },
                icon: Icons.access_time,
                color: Colors.orange,
              ),

              const SizedBox(height: 20),

              // Validation info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduling Rules',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• End time must be after start time\n'
                      '• Submission deadline (if set) should be before or at end time\n'
                      '• All times are in your local timezone',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _scheduleEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Schedule'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(
    BuildContext context, {
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context, value, onChanged),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDateTime(value),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalDateTimeField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
    required VoidCallback onCleared,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (value != null)
              IconButton(
                onPressed: onCleared,
                icon: const Icon(Icons.clear, size: 16),
                tooltip: 'Clear deadline',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            if (value != null) {
              _selectDateTime(context, value, onChanged);
            } else {
              // Set default to end time if not set
              _selectDateTime(context, endTime, onChanged);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value != null ? _formatDateTime(value) : 'Tap to set deadline',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value != null ? null : Colors.grey.shade600,
                    fontStyle: value != null ? null : FontStyle.italic,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(
    BuildContext context,
    DateTime initialValue,
    Function(DateTime) onChanged,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialValue),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(newDateTime);
      }
    }
  }

  Future<void> _scheduleEvent() async {
    // Validate times
    if (endTime.isBefore(startTime)) {
      setState(() {
        _errorMessage = 'End time must be after start time';
      });
      return;
    }

    if (submissionDeadline != null && submissionDeadline!.isAfter(endTime)) {
      setState(() {
        _errorMessage = 'Submission deadline should be before or at end time';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(eventServiceProvider).scheduleEvent(
            widget.event.id,
            startTime: startTime,
            endTime: endTime,
            submissionDeadline: submissionDeadline,
          );

      if (mounted) {
        widget.onScheduled?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to schedule event: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.competition:
        return 'Competition';
      case EventType.challenge:
        return 'Challenge';
      case EventType.survey:
        return 'Survey';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }
}
