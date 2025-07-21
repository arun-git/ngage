import '../models/models.dart';
import '../repositories/badge_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/submission_repository.dart';
import 'notification_service.dart';

class BadgeService {
  final BadgeRepository _badgeRepository;
  final EventRepository _eventRepository;
  final SubmissionRepository _submissionRepository;
  final NotificationService _notificationService;

  BadgeService({
    required BadgeRepository badgeRepository,
    required EventRepository eventRepository,
    required SubmissionRepository submissionRepository,
    required NotificationService notificationService,
  })  : _badgeRepository = badgeRepository,
        _eventRepository = eventRepository,
        _submissionRepository = submissionRepository,
        _notificationService = notificationService;

  // Update member streak
  Future<MemberStreak> updateStreak({
    required String memberId,
    required StreakType type,
    required DateTime activityDate,
  }) async {
    try {
      final existingStreak = await _badgeRepository.getMemberStreak(memberId, type);
      
      if (existingStreak == null) {
        // Create new streak
        final newStreak = MemberStreak(
          id: _generateStreakId(memberId, type),
          memberId: memberId,
          type: type,
          currentStreak: 1,
          longestStreak: 1,
          lastActivityDate: activityDate,
          streakStartDate: activityDate,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _badgeRepository.storeMemberStreak(newStreak);
        return newStreak;
      } else {
        // Update existing streak
        final daysSinceLastActivity = activityDate.difference(existingStreak.lastActivityDate).inDays;
        
        int newCurrentStreak;
        bool isActive;
        DateTime streakStartDate;
        
        if (daysSinceLastActivity == 1) {
          // Continue streak
          newCurrentStreak = existingStreak.currentStreak + 1;
          isActive = true;
          streakStartDate = existingStreak.streakStartDate;
        } else if (daysSinceLastActivity == 0) {
          // Same day activity, no change to streak
          return existingStreak;
        } else {
          // Streak broken, start new
          newCurrentStreak = 1;
          isActive = true;
          streakStartDate = activityDate;
        }
        
        final updatedStreak = MemberStreak(
          id: existingStreak.id,
          memberId: memberId,
          type: type,
          currentStreak: newCurrentStreak,
          longestStreak: newCurrentStreak > existingStreak.longestStreak 
              ? newCurrentStreak 
              : existingStreak.longestStreak,
          lastActivityDate: activityDate,
          streakStartDate: streakStartDate,
          isActive: isActive,
          createdAt: existingStreak.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _badgeRepository.storeMemberStreak(updatedStreak);
        
        // Check for streak milestones
        await _checkStreakMilestones(memberId, updatedStreak);
        
        return updatedStreak;
      }
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  // Get member streaks
  Future<List<MemberStreak>> getMemberStreaks(String memberId) async {
    try {
      return await _badgeRepository.getMemberStreaks(memberId);
    } catch (e) {
      throw Exception('Failed to get member streaks: $e');
    }
  }

  // Update member points
  Future<MemberPoints> updateMemberPoints({
    required String memberId,
    required int pointsToAdd,
    required String category,
  }) async {
    try {
      return await _updateMemberPoints(memberId, pointsToAdd, category);
    } catch (e) {
      throw Exception('Failed to update member points: $e');
    }
  }

  // Get member points
  Future<MemberPoints?> getMemberPoints(String memberId) async {
    try {
      return await _badgeRepository.getMemberPoints(memberId);
    } catch (e) {
      throw Exception('Failed to get member points: $e');
    }
  }

  // Award badge to member
  Future<void> awardBadge({
    required String memberId,
    required String badgeId,
    required String eventId,
  }) async {
    try {
      final badge = await _badgeRepository.getBadgeById(badgeId);
      if (badge == null) {
        throw Exception('Badge not found');
      }

      final memberBadge = MemberBadge(
        id: _generateMemberBadgeId(memberId, badgeId),
        memberId: memberId,
        badgeId: badgeId,
        eventId: eventId,
        awardedAt: DateTime.now(),
        isVisible: true,
      );

      await _badgeRepository.storeMemberBadge(memberBadge);
      
      // Send notification
      await _sendBadgeNotification(memberId, badge);
    } catch (e) {
      throw Exception('Failed to award badge: $e');
    }
  }

  // Get member badges
  Future<List<MemberBadge>> getMemberBadges(String memberId) async {
    try {
      return await _badgeRepository.getMemberBadges(memberId);
    } catch (e) {
      throw Exception('Failed to get member badges: $e');
    }
  }

  // Check and award milestone badges
  Future<void> checkMilestoneBadges(String memberId) async {
    try {
      final milestones = await _badgeRepository.getMemberMilestones(memberId);
      
      for (final milestone in milestones) {
        if (milestone.isCompleted && !milestone.badgeAwarded) {
          await _awardMilestoneRewards(memberId, milestone);
        }
      }
    } catch (e) {
      throw Exception('Failed to check milestone badges: $e');
    }
  }

  // Private helper methods
  Future<void> _checkStreakMilestones(String memberId, MemberStreak streak) async {
    // Check for streak milestone achievements
    final milestones = [5, 10, 30, 100]; // Days
    
    for (final milestone in milestones) {
      if (streak.currentStreak == milestone) {
        await _awardStreakMilestone(memberId, streak.type, milestone);
      }
    }
  }

  Future<void> _awardStreakMilestone(String memberId, StreakType type, int days) async {
    // Award streak milestone badge
    final badgeId = 'streak_${type.name}_${days}days';
    
    try {
      await awardBadge(
        memberId: memberId,
        badgeId: badgeId,
        eventId: 'system', // System-generated badge
      );
    } catch (e) {
      // Badge might not exist or already awarded
      print('Could not award streak milestone badge: $e');
    }
  }

  Future<MemberPoints> _updateMemberPoints(String memberId, int pointsToAdd, String category) async {
    final existingPoints = await _badgeRepository.getMemberPoints(memberId);
    
    if (existingPoints == null) {
      final newPoints = MemberPoints(
        id: _generateMemberPointsId(memberId),
        memberId: memberId,
        totalPoints: pointsToAdd,
        categoryPoints: {category: pointsToAdd},
        level: _calculateLevel(pointsToAdd),
        levelTitle: _getLevelTitle(_calculateLevel(pointsToAdd)),
        currentLevelPoints: pointsToAdd,
        nextLevelPoints: _getNextLevelPoints(_calculateLevel(pointsToAdd)),
        lastUpdated: DateTime.now(),
      );
      
      await _badgeRepository.storeMemberPoints(newPoints);
      return newPoints;
    } else {
      final newTotalPoints = existingPoints.totalPoints + pointsToAdd;
      final newCategoryPoints = Map<String, int>.from(existingPoints.categoryPoints);
      newCategoryPoints[category] = (newCategoryPoints[category] ?? 0) + pointsToAdd;
      
      final newLevel = _calculateLevel(newTotalPoints);
      
      final updatedPoints = MemberPoints(
        id: existingPoints.id,
        memberId: memberId,
        totalPoints: newTotalPoints,
        categoryPoints: newCategoryPoints,
        level: newLevel,
        levelTitle: _getLevelTitle(newLevel),
        currentLevelPoints: _getCurrentLevelPoints(newTotalPoints, newLevel),
        nextLevelPoints: _getNextLevelPoints(newLevel),
        lastUpdated: DateTime.now(),
      );
      
      await _badgeRepository.storeMemberPoints(updatedPoints);
      return updatedPoints;
    }
  }

  Future<void> _awardMilestoneRewards(String memberId, MemberMilestone milestone) async {
    // Award points for milestone completion
    await _updateMemberPoints(memberId, milestone.rewardPoints, 'milestone');
    
    // Award milestone badge if specified
    if (milestone.badgeId != null) {
      await awardBadge(
        memberId: memberId,
        badgeId: milestone.badgeId!,
        eventId: 'system',
      );
    }
    
    // Mark milestone as badge awarded
    final updatedMilestone = MemberMilestone(
      id: milestone.id,
      memberId: milestone.memberId,
      milestoneId: milestone.milestoneId,
      currentProgress: milestone.currentProgress,
      targetProgress: milestone.targetProgress,
      isCompleted: milestone.isCompleted,
      completedAt: milestone.completedAt,
      badgeAwarded: true,
      rewardPoints: milestone.rewardPoints,
      badgeId: milestone.badgeId,
    );
    
    await _badgeRepository.storeMemberMilestone(updatedMilestone);
    
    // Send milestone notification
    await _sendMilestoneNotification(memberId, milestone);
  }

  Future<void> _sendBadgeNotification(String memberId, Badge badge) async {
    final notification = Notification(
      id: 'badge_${badge.id}_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: memberId,
      type: NotificationType.badgeAwarded,
      title: 'Badge Earned!',
      message: 'You earned the "${badge.name}" badge!',
      data: {'badgeId': badge.id, 'badgeName': badge.name},
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    await _notificationService.sendNotification(notification);
  }

  Future<void> _sendMilestoneNotification(String memberId, MemberMilestone milestone) async {
    final notification = Notification(
      id: 'milestone_${milestone.id}_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: memberId,
      type: NotificationType.milestoneCompleted,
      title: 'Milestone Completed!',
      message: 'You completed a milestone and earned ${milestone.rewardPoints} points!',
      data: {'milestoneId': milestone.milestoneId, 'points': milestone.rewardPoints},
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    await _notificationService.sendNotification(notification);
  }

  // Utility methods
  int _calculateLevel(int totalPoints) {
    // Simple level calculation: every 1000 points = 1 level
    return (totalPoints / 1000).floor() + 1;
  }

  String _getLevelTitle(int level) {
    if (level <= 5) return 'Beginner';
    if (level <= 10) return 'Intermediate';
    if (level <= 20) return 'Advanced';
    if (level <= 50) return 'Expert';
    return 'Master';
  }

  int _getCurrentLevelPoints(int totalPoints, int level) {
    return totalPoints - ((level - 1) * 1000);
  }

  int _getNextLevelPoints(int level) {
    return level * 1000;
  }

  String _generateMemberBadgeId(String memberId, String badgeId) {
    return '${memberId}_${badgeId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateStreakId(String memberId, StreakType type) {
    return '${memberId}_${type.name}_streak';
  }

  String _generateMemberPointsId(String memberId) {
    return '${memberId}_points';
  }

  String _generateMemberMilestoneId(String memberId, String milestoneId) {
    return '${memberId}_$milestoneId';
  }

  // Get points leaderboard
  Future<List<Map<String, dynamic>>> getPointsLeaderboard({
    String? groupId,
    int limit = 50,
  }) async {
    try {
      return await _badgeRepository.getPointsLeaderboard(
        groupId: groupId,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get points leaderboard: $e');
    }
  }

  // Get member badges with details
  Future<List<Map<String, dynamic>>> getMemberBadgesWithDetails(String memberId) async {
    try {
      final memberBadges = await _badgeRepository.getMemberBadges(memberId);
      final badgeDetails = <Map<String, dynamic>>[];

      for (final memberBadge in memberBadges) {
        final badge = await _badgeRepository.getBadge(memberBadge.badgeId);
        if (badge != null) {
          badgeDetails.add({
            'memberBadge': memberBadge.toJson(),
            'badge': badge.toJson(),
          });
        }
      }

      return badgeDetails;
    } catch (e) {
      throw Exception('Failed to get member badges with details: $e');
    }
  }

  // Get member milestones
  Future<List<Map<String, dynamic>>> getMemberMilestones(String memberId) async {
    try {
      final memberMilestones = await _badgeRepository.getMemberMilestones(memberId);
      final milestoneDetails = <Map<String, dynamic>>[];

      for (final memberMilestone in memberMilestones) {
        milestoneDetails.add({
          'memberMilestone': memberMilestone.toJson(),
        });
      }

      return milestoneDetails;
    } catch (e) {
      throw Exception('Failed to get member milestones: $e');
    }
  }
}