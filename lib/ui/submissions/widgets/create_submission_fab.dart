import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event.dart';
import '../../../providers/event_submission_integration_providers.dart';
import '../submission_screen.dart';

/// Floating Action Button for creating submissions
class CreateSubmissionFAB extends ConsumerWidget {
  final Event event;
  final String teamId;
  final String memberId;

  const CreateSubmissionFAB({
    super.key,
    required this.event,
    required this.teamId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if team can submit
    final canSubmitAsync = ref.watch(canTeamSubmitToEventProvider((
      eventId: event.id,
      teamId: teamId,
    )));

    // Check if team already has a submission
    final teamSubmissionAsync = ref.watch(teamSubmissionForEventProvider((
      eventId: event.id,
      teamId: teamId,
    )));

    return canSubmitAsync.when(
      data: (canSubmit) => teamSubmissionAsync.when(
        data: (submission) {
          if (!canSubmit && submission == null) {
            // Team cannot submit and has no submission
            return const SizedBox.shrink();
          }

          if (submission != null && !submission.canBeEdited) {
            // Submission exists but cannot be edited
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _navigateToSubmission(context, submission),
            icon: Icon(submission == null ? Icons.add : Icons.edit),
            label: Text(submission == null ? 'Submit Entry' : 'Continue'),
            tooltip: submission == null
                ? 'Create new submission for ${event.title}'
                : 'Continue editing submission',
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToSubmission(BuildContext context, submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: event.id,
          teamId: teamId,
          memberId: memberId,
          submissionId: submission?.id,
        ),
      ),
    );
  }
}

/// Simple FAB for submission creation without async checks
class SimpleCreateSubmissionFAB extends StatelessWidget {
  final Event event;
  final String teamId;
  final String memberId;
  final String? submissionId;

  const SimpleCreateSubmissionFAB({
    super.key,
    required this.event,
    required this.teamId,
    required this.memberId,
    this.submissionId,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if event is active and has submission deadline
    if (event.status != EventStatus.active ||
        event.submissionDeadline == null) {
      return const SizedBox.shrink();
    }

    // Check if deadline has passed
    if (DateTime.now().isAfter(event.submissionDeadline!)) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _navigateToSubmission(context),
      icon: Icon(submissionId == null ? Icons.add : Icons.edit),
      label: Text(submissionId == null ? 'Submit Entry' : 'Continue'),
      tooltip: submissionId == null
          ? 'Create new submission for ${event.title}'
          : 'Continue editing submission',
    );
  }

  void _navigateToSubmission(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: event.id,
          teamId: teamId,
          memberId: memberId,
          submissionId: submissionId,
        ),
      ),
    );
  }
}
