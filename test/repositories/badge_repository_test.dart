import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/badge_repository.dart';

void main() {
  group('BadgeRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BadgeRepository badgeRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      badgeRepository = BadgeRepository(firestore: fakeFirestore);
    });

    group('Badge Operations', () {
      test('should save and retrieve badge', () async {
        // Arrange
        final badge = Badge(
          id: 'test_badge_1',
          name: 'Test Badge',
          description: 'A test badge',
          iconUrl: '/badges/test.png',
          type: BadgeType.participation,
          criteria: {'eventCount': 5},
          pointValue: 50,
          rarity: BadgeRarity.common,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        // Act
        await badgeRepository.saveBadge(badge);
        final retrievedBadge = await badgeRepository.getBadge(badge.id);

        // Assert
        expect(retrievedBadge, isNotNull);
        expect(retrievedBadge!.id, equals(badge.id));
        expect(retrievedBadge.name, equals(badge.name));
        expect(retrievedBadge.description, equals(badge.description));
        expect(retrievedBadge.type, equals(badge.type));
        expect(retrievedBadge.pointValue, equals(badge.pointValue));
        expect(retrievedBadge.rarity, equals(badge.rarity));
      });

      test('should return null for non-existent badge', () async {
        // Act
        final result = await badgeRepository.getBadge('non_existent_badge');

        // Assert
        expect(result, isNull);
      });

      test('should get all active badges', () async {
        // Arrange
        final badge1 = Badge(
          id: 'badge_1',
          name: 'Active Badge',
          description: 'An active badge',
          iconUrl: '/badges/active.png',
          type: BadgeType.participation,
          criteria: {},
          pointValue: 10,
          rarity: BadgeRarity.common,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final badge2 = Badge(
          id: 'badge_2',
          name: 'Inactive Badge',
          description: 'An inactive badge',
          iconUrl: '/badges/inactive.png',
          type: BadgeType.performance,
          criteria: {},
          pointValue: 20,
          rarity: BadgeRarity.uncommon,
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await badgeRepository.saveBadge(badge1);
        await badgeRepository.saveBadge(badge2);

        // Act
        final result = await badgeRepository.getAllBadges();

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('badge_1'));
        expect(result.first.isActive, isTrue);
      });
    });

    group('MemberBadge Operations', () {
      test('should save and retrieve member badges', () async {
        // Arrange
        const memberId = 'member_1';
        final memberBadge = MemberBadge(
          id: 'member_badge_1',
          memberId: memberId,
          badgeId: 'badge_1',
          earnedAt: DateTime(2024, 1, 15),
          context: {'eventId': 'event_1'},
        );

        // Act
        await badgeRepository.saveMemberBadge(memberBadge);
        final result = await badgeRepository.getMemberBadges(memberId);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals(memberBadge.id));
        expect(result.first.memberId, equals(memberId));
        expect(result.first.badgeId, equals('badge_1'));
        expect(result.first.context, equals({'eventId': 'event_1'}));
      });

      test('should only return visible member badges', () async {
        // Arrange
        const memberId = 'member_1';
        final visibleBadge = MemberBadge(
          id: 'visible_badge',
          memberId: memberId,
          badgeId: 'badge_1',
          earnedAt: DateTime.now(),
          isVisible: true,
        );

        final hiddenBadge = MemberBadge(
          id: 'hidden_badge',
          memberId: memberId,
          badgeId: 'badge_2',
          earnedAt: DateTime.now(),
          isVisible: false,
        );

        await badgeRepository.saveMemberBadge(visibleBadge);
        await badgeRepository.saveMemberBadge(hiddenBadge);

        // Act
        final result = await badgeRepository.getMemberBadges(memberId);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('visible_badge'));
      });

      test('should hide member badge', () async {
        // Arrange
        const memberId = 'member_1';
        final memberBadge = MemberBadge(
          id: 'member_badge_1',
          memberId: memberId,
          badgeId: 'badge_1',
          earnedAt: DateTime.now(),
          isVisible: true,
        );

        await badgeRepository.saveMemberBadge(memberBadge);

        // Act
        await badgeRepository.hideMemberBadge(memberBadge.id);
        final result = await badgeRepository.getMemberBadges(memberId);

        // Assert
        expect(result.length, equals(0)); // Should be hidden
      });

      test('should get recent badge activities', () async {
        // Arrange
        const memberId = 'member_1';
        final now = DateTime.now();
        
        final recentBadge = MemberBadge(
          id: 'recent_badge',
          memberId: memberId,
          badgeId: 'badge_1',
          earnedAt: now,
        );

        final olderBadge = MemberBadge(
          id: 'older_badge',
          memberId: memberId,
          badgeId: 'badge_2',
          earnedAt: now.subtract(const Duration(days: 1)),
        );

        await badgeRepository.saveMemberBadge(recentBadge);
        await badgeRepository.saveMemberBadge(olderBadge);

        // Act
        final result = await badgeRepository.getRecentBadgeActivities(memberId, limit: 1);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('recent_badge')); // Most recent first
      });
    });

    group('MemberAchievement Operations', () {
      test('should save and retrieve member achievement', () async {
        // Arrange
        const memberId = 'member_1';
        final achievement = MemberAchievement(
          id: 'achievement_1',
          memberId: memberId,
          totalPoints: 250,
          currentLevelPoints: 50,
          nextLevelPoints: 100,
          level: 3,
          levelTitle: 'Contributor',
          categoryPoints: {'participation': 150, 'social': 100},
          lastUpdated: DateTime(2024, 1, 25),
        );

        // Act
        await badgeRepository.saveMemberAchievement(achievement);
        final result = await badgeRepository.getMemberAchievement(memberId);

        // Assert
        expect(result.id, equals(achievement.id));
        expect(result.memberId, equals(memberId));
        expect(result.totalPoints, equals(250));
        expect(result.level, equals(3));
        expect(result.levelTitle, equals('Contributor'));
        expect(result.categoryPoints, equals({'participation': 150, 'social': 100}));
      });

      test('should throw exception for non-existent achievement', () async {
        // Act & Assert
        expect(
          () => badgeRepository.getMemberAchievement('non_existent_member'),
          throwsException,
        );
      });
    });

    group('MemberStreak Operations', () {
      test('should save and retrieve member streaks', () async {
        // Arrange
        const memberId = 'member_1';
        final streak = MemberStreak(
          id: 'streak_1',
          memberId: memberId,
          type: StreakType.participation,
          currentStreak: 5,
          longestStreak: 10,
          lastActivityDate: DateTime(2024, 1, 20),
          streakStartDate: DateTime(2024, 1, 16),
        );

        // Act
        await badgeRepository.saveMemberStreak(streak);
        final result = await badgeRepository.getMemberStreaks(memberId);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals(streak.id));
        expect(result.first.memberId, equals(memberId));
        expect(result.first.type, equals(StreakType.participation));
        expect(result.first.currentStreak, equals(5));
        expect(result.first.longestStreak, equals(10));
      });

      test('should get specific member streak by type', () async {
        // Arrange
        const memberId = 'member_1';
        final participationStreak = MemberStreak(
          id: 'participation_streak',
          memberId: memberId,
          type: StreakType.participation,
          currentStreak: 3,
          longestStreak: 5,
        );

        final submissionStreak = MemberStreak(
          id: 'submission_streak',
          memberId: memberId,
          type: StreakType.submission,
          currentStreak: 2,
          longestStreak: 4,
        );

        await badgeRepository.saveMemberStreak(participationStreak);
        await badgeRepository.saveMemberStreak(submissionStreak);

        // Act
        final result = await badgeRepository.getMemberStreak(memberId, StreakType.participation);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('participation_streak'));
        expect(result.type, equals(StreakType.participation));
      });

      test('should return null for non-existent streak', () async {
        // Act
        final result = await badgeRepository.getMemberStreak('member_1', StreakType.participation);

        // Assert
        expect(result, isNull);
      });
    });

    group('Badge Statistics', () {
      test('should calculate badge statistics correctly', () async {
        // Arrange
        const memberId = 'member_1';
        
        // Create badges
        final badge1 = Badge(
          id: 'badge_1',
          name: 'Common Badge',
          description: 'A common badge',
          iconUrl: '/badges/common.png',
          type: BadgeType.participation,
          criteria: {},
          pointValue: 10,
          rarity: BadgeRarity.common,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final badge2 = Badge(
          id: 'badge_2',
          name: 'Rare Badge',
          description: 'A rare badge',
          iconUrl: '/badges/rare.png',
          type: BadgeType.performance,
          criteria: {},
          pointValue: 50,
          rarity: BadgeRarity.rare,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await badgeRepository.saveBadge(badge1);
        await badgeRepository.saveBadge(badge2);

        // Create member badges
        final memberBadge1 = MemberBadge(
          id: 'member_badge_1',
          memberId: memberId,
          badgeId: 'badge_1',
          earnedAt: DateTime.now(),
        );

        await badgeRepository.saveMemberBadge(memberBadge1);

        // Act
        final result = await badgeRepository.getBadgeStatistics(memberId);

        // Assert
        expect(result['totalBadges'], equals(1));
        expect(result['totalAvailable'], equals(2));
        expect(result['completionPercentage'], equals(50));
        expect(result['badgesByType']['participation'], equals(1));
        expect(result['badgesByRarity']['common'], equals(1));
        expect(result['totalPointsFromBadges'], equals(10));
      });
    });

    group('Achievement Leaderboard', () {
      test('should return achievement leaderboard ordered by points', () async {
        // Arrange
        final achievement1 = MemberAchievement(
          id: 'achievement_1',
          memberId: 'member_1',
          totalPoints: 500,
          currentLevelPoints: 0,
          nextLevelPoints: 250,
          level: 4,
          levelTitle: 'Achiever',
          categoryPoints: {},
          lastUpdated: DateTime.now(),
        );

        final achievement2 = MemberAchievement(
          id: 'achievement_2',
          memberId: 'member_2',
          totalPoints: 300,
          currentLevelPoints: 50,
          nextLevelPoints: 100,
          level: 3,
          levelTitle: 'Contributor',
          categoryPoints: {},
          lastUpdated: DateTime.now(),
        );

        await badgeRepository.saveMemberAchievement(achievement1);
        await badgeRepository.saveMemberAchievement(achievement2);

        // Act
        final result = await badgeRepository.getAchievementLeaderboard(limit: 10);

        // Assert
        expect(result.length, equals(2));
        expect((result[0]['achievement'] as MemberAchievement).totalPoints, equals(500));
        expect((result[1]['achievement'] as MemberAchievement).totalPoints, equals(300));
        expect(result[0]['rank'], equals(1));
        expect(result[1]['rank'], equals(2));
      });
    });

    group('Streak Badges', () {
      test('should get streak-related badges', () async {
        // Arrange
        final streakBadge = Badge(
          id: 'streak_badge',
          name: 'Streak Master',
          description: 'Maintained a streak',
          iconUrl: '/badges/streak.png',
          type: BadgeType.milestone,
          criteria: {'streakLength': 7},
          pointValue: 75,
          rarity: BadgeRarity.rare,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final regularBadge = Badge(
          id: 'regular_badge',
          name: 'Regular Badge',
          description: 'A regular badge',
          iconUrl: '/badges/regular.png',
          type: BadgeType.participation,
          criteria: {'eventCount': 1},
          pointValue: 10,
          rarity: BadgeRarity.common,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await badgeRepository.saveBadge(streakBadge);
        await badgeRepository.saveBadge(regularBadge);

        // Act
        final result = await badgeRepository.getStreakBadges(StreakType.participation);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('streak_badge'));
        expect(result.first.criteria.containsKey('streakLength'), isTrue);
      });
    });
  });
}