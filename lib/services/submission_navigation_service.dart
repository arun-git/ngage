import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/submission.dart';
import '../ui/submissions/submission_screen.dart';
import '../ui/submissions/submissions_list_screen.dart';

/// Service for handling submission-related navigation
class SubmissionNavigationService {
  /// Navigate to create a new submission
  static Future<void> navigateToCreateSubmission(
    BuildContext context, {
    required String eventId,
    required String teamId,
    required String memberId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: eventId,
          teamId: teamId,
          memberId: memberId,
        ),
      ),
    );
  }

  /// Navigate to edit an existing submission
  static Future<void> navigateToEditSubmission(
    BuildContext context, {
    required String eventId,
    required String teamId,
    required String memberId,
    required String submissionId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: eventId,
          teamId: teamId,
          memberId: memberId,
          submissionId: submissionId,
        ),
      ),
    );
  }

  /// Navigate to view a submission (read-only)
  static Future<void> navigateToViewSubmission(
    BuildContext context, {
    required Submission submission,
  }) async {
    await Navigator.of(context).push(
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

  /// Navigate to submissions list for an event
  static Future<void> navigateToSubmissionsList(
    BuildContext context, {
    required String eventId,
    String? teamId,
    bool isJudgeView = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionsListScreen(
          eventId: eventId,
          teamId: teamId,
          isJudgeView: isJudgeView,
        ),
      ),
    );
  }

  /// Navigate to submission based on current state
  static Future<void> navigateToSubmissionSmart(
    BuildContext context, {
    required String eventId,
    required String teamId,
    required String memberId,
    Submission? existingSubmission,
  }) async {
    if (existingSubmission != null) {
      // Edit existing submission
      await navigateToEditSubmission(
        context,
        eventId: eventId,
        teamId: teamId,
        memberId: memberId,
        submissionId: existingSubmission.id,
      );
    } else {
      // Create new submission
      await navigateToCreateSubmission(
        context,
        eventId: eventId,
        teamId: teamId,
        memberId: memberId,
      );
    }
  }

  /// Show submission action dialog
  static Future<void> showSubmissionActionDialog(
    BuildContext context, {
    required Event event,
    required String teamId,
    required String memberId,
    Submission? existingSubmission,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${event.title} Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (existingSubmission != null) ...[
              Text(
                  'You have a ${existingSubmission.status.value} submission for this event.'),
              const SizedBox(height: 8),
            ],
            if (event.submissionDeadline != null) ...[
              Text('Deadline: ${_formatDateTime(event.submissionDeadline!)}'),
              const SizedBox(height: 8),
            ],
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          if (existingSubmission != null) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop('view'),
              child: const Text('View'),
            ),
            if (existingSubmission.canBeEdited)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('edit'),
                child: const Text('Edit'),
              ),
          ] else ...[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('create'),
              child: const Text('Create Submission'),
            ),
          ],
        ],
      ),
    );

    if (result != null && context.mounted) {
      switch (result) {
        case 'create':
          await navigateToCreateSubmission(
            context,
            eventId: event.id,
            teamId: teamId,
            memberId: memberId,
          );
          break;
        case 'edit':
          if (existingSubmission != null) {
            await navigateToEditSubmission(
              context,
              eventId: event.id,
              teamId: teamId,
              memberId: memberId,
              submissionId: existingSubmission.id,
            );
          }
          break;
        case 'view':
          if (existingSubmission != null) {
            await navigateToViewSubmission(context,
                submission: existingSubmission);
          }
          break;
      }
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
