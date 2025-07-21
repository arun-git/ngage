import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';
import '../repositories/badge_repository.dart';
import '../services/badge_service.dart';
import 'event_providers.dart';
import 'submission_providers.dart';
import 'notification_providers.dart';

// Helper classes
class LeaderboardParams {
  final String? groupId;
  final int limit;

  const LeaderboardParams({
    this.groupId,
    this.limit = 50,
  });
}

class GamificationSummary {
  final int totalBadges;
  final int totalPoints;
  final int activeStreaks;
  final int longestStreak;
  final int completedMilestones;
  final int totalMilestones;
  final List<Map<String, dynamic>> recentBadges;
  final Map<String, int> pointsBreakdown;

  const GamificationSummary({
    required this.totalBadges,
    required this.totalPoints,
    required this.activeStreaks,
    required this.longestStreak,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.recentBadges,
    required this.pointsBreakdown,
  });
}

// Repository provider
final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(FirebaseFirestore.instance);
});

// Service provider
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final submissionRepository = ref.watch(submissionRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  return BadgeService(
    badgeRepository: badgeRepository,
    eventRepository: eventRepository,
    submissionRepository: submissionRepository,
    notificationService: notificationService,
  );
});

// Member badges provider
final memberBadgesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, memberId) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getMemberBadgesWithDetails(memberId);
});

// Member streaks provider
final memberStreaksProvider = FutureProvider.family<List<MemberStreak>, String>((ref, memberId) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getMemberStreaks(memberId);
});

// Member points provider
final memberPointsProvider = FutureProvider.family<MemberPoints?, String>((ref, memberId) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getMemberPoints(memberId);
});

// Points leaderboard provider
final pointsLeaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, LeaderboardParams>((ref, params) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getPointsLeaderboard(
    groupId: params.groupId,
    limit: params.limit,
  );
});

// Member milestones provider
final memberMilestonesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, memberId) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getMemberMilestones(memberId);
});

// Active badges provider
final activeBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  final repository = ref.watch(badgeRepositoryProvider);
  return repository.getActiveBadges();
});

// Badge details provider
final badgeProvider = FutureProvider.family<Badge?, String>((ref, badgeId) async {
  final repository = ref.watch(badgeRepositoryProvider);
  return repository.getBadge(badgeId);
});

// Member gamification summary provider
final memberGamificationSummaryProvider = FutureProvider.family<GamificationSummary, String>((ref, memberId) async {
  final badgesAsync = ref.watch(memberBadgesProvider(memberId));
  final pointsAsync = ref.watch(memberPointsProvider(memberId));
  final streaksAsync = ref.watch(memberStreaksProvider(memberId));
  final milestonesAsync = ref.watch(memberMilestonesProvider(memberId));

  final badges = await badgesAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<Map<String, dynamic>>[]),
    error: (error, stack) => Future.error(error),
  );
  final points = await pointsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(null),
    error: (error, stack) => Future.error(error),
  );
  final streaks = await streaksAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<MemberStreak>[]),
    error: (error, stack) => Future.error(error),
  );
  final milestones = await milestonesAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<Map<String, dynamic>>[]),
    error: (error, stack) => Future.error(error),
  );

  return GamificationSummary(
    totalBadges: badges.length,
    totalPoints: points?.totalPoints ?? 0,
    activeStreaks: streaks.where((s) => s.isActive).length,
    longestStreak: streaks.isNotEmpty 
        ? streaks.map((s) => s.longestStreak).reduce((a, b) => a > b ? a : b)
        : 0,
    completedMilestones: milestones.where((m) => m['memberMilestone'].isCompleted).length,
    totalMilestones: milestones.length,
    recentBadges: badges.take(3).toList(),
    pointsBreakdown: points?.categoryPoints ?? {},
  );
});

