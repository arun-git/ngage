import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_repository.dart';
import 'member_repository.dart';
import 'event_repository.dart';
import 'score_repository.dart';
import 'scoring_rubric_repository.dart';
import 'submission_repository.dart';
import 'team_repository.dart';
import 'group_repository.dart';
import 'judge_comment_repository.dart';
import 'judge_assignment_repository.dart';
import 'leaderboard_repository.dart';
import 'post_repository.dart';
import 'notification_repository.dart';
import 'slack_integration_repository.dart';
import 'integration_repository.dart';

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Provider for MemberRepository
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

/// Provider for EventRepository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Provider for ScoreRepository
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepository();
});

/// Provider for ScoringRubricRepository
final scoringRubricRepositoryProvider = Provider<ScoringRubricRepository>((ref) {
  return ScoringRubricRepository();
});

/// Provider for SubmissionRepository
final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository();
});

/// Provider for TeamRepository
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});

/// Provider for GroupRepository
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

/// Provider for JudgeCommentRepository
final judgeCommentRepositoryProvider = Provider<JudgeCommentRepository>((ref) {
  return JudgeCommentRepository();
});

/// Provider for JudgeAssignmentRepository
final judgeAssignmentRepositoryProvider = Provider<JudgeAssignmentRepository>((ref) {
  return JudgeAssignmentRepository();
});

/// Provider for LeaderboardRepository
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

/// Provider for PostRepository
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider for SlackIntegrationRepository
final slackIntegrationRepositoryProvider = Provider<SlackIntegrationRepository>((ref) {
  return SlackIntegrationRepository();
});

/// Provider for IntegrationRepository
final integrationRepositoryProvider = Provider<IntegrationRepository>((ref) {
  return IntegrationRepository();
});