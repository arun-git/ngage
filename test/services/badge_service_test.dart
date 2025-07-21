import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/services/badge_service.dart';
import 'package:ngage/repositories/badge_repository.dart';
import 'package:ngage/repositories/member_repository.dart';
import 'package:ngage/repositories/event_repository.dart';
import 'package:ngage/repositories/submission_repository.dart';
import 'package:ngage/repositories/post_repository.dart';
import 'package:ngage/services/notification_service.dart';

import 'badge_service_test.mocks.dart';

@GenerateMocks([
  BadgeRepository,
  MemberRepository,
  EventRepository,
  SubmissionRepository,
  PostRepository,
  NotificationService,
])
void main() {
  group('BadgeService Tests', () {
    late BadgeService badgeService;
    late MockBadgeRepository mockBadgeRepository;
    late MockMemberRepository mockMemberRepository;
    late MockEventRepository mockEventRepository;
    late MockSubmissionRepository mockSubmissionRepository;
    late MockPostRepository mockPostRepository;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockBadgeRepository = MockBadgeRepository();
      mockMemberRepository = MockMemberRepository();
      mockEventRepository = MockEventRepository();
      mockSubmissionRepository = MockSubmissionRepository();
      mockPostRepository = MockPostRepository();
      mockNotificationService = MockNotificationService();

      badgeService = BadgeService(
        badgeRepository: mockBadgeRepository,
        memberRepository: mockMemberRepository,
        eventRepository: mockEventRepository,
        submissionRepository: mockSubmissionRepository,
        postRepository: mockPostRepository,
        notificationService: mockNotificationService,
      );
    });

    group('getAllBadges', () {
      test('should return all badges from repository', () async {
        // Arrange
        final badges = [
          Badge(
            id: 'badge_1',
            name: 'Test Badge 1',
            description: 'First test badge',
            iconUrl: '/badges/1.png',
            type: BadgeType.participation,
            criteria: {'eventCount': 1},
            pointValue: 10,
            rarity: BadgeRarity.common,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Badge(
            id: 'badge_2',
            name: 'Test Badge 2',
            description: 'Second test badge',
            iconUrl: '/badges/2.png',
            type: BadgeType.performance,
            criteria: {'winCount': 1},
            pointValue: 25,
            rarity: BadgeRarity.uncommon,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockBadgeRepository.getAllBadges()).thenAnswer((_) async => badges);

        // Act
        final result = await badgeService.getAllBadges();

        // Assert
        expect(result, equals(badges));
        verify(mockBadgeRepository.getAllBadges()).called(1);
      });
    });

    group('getMemberBadges', () {
      test('should return member badges from repository', () async {
        // Arrange
        const memberId = 'member_1';
        final memberBadges = [
          MemberBadge(
            id: 'member_badge_1',
            memberId: memberId,
            badgeId: 'badge_1',
            earnedAt: DateTime.now(),
          ),
        ];

        when(mockBadgeRepository.getMemberBadges(memberId))
            .thenAnswer((_) async => memberBadges);

        // Act
        final result = await badgeService.getMemberBadges(memberId);

        // Assert
        expect(result, equals(memberBadges));
        verify(mockBadgeRepository.getMemberBadges(memberId)).called(1);
      });
    });

    group('getMemberAchievement', () {
      test('should return existing achievement', () async {
        // Arrange
        const memberId = 'member_1';
        final achievement = MemberAchievement(
          id: 'achievement_1',
          memberId: memberId,
          totalPoints: 100,
          currentLevelPoints: 0,
          nextLevelPoints: 100,
          level: 2,
          levelTitle: 'Participant',
          categoryPoints: {'participation': 100},
          lastUpdated: DateTime.now(),
        );

        when(mockBadgeRepository.getMemberAchievement(memberId))
            .thenAnswer((_) async => achievement);

        // Act
        final result = await badgeService.getMemberAchievement(memberId);

        // Assert
        expect(result, equals(achievement));
        verify(mockBadgeRepository.getMemberAchievement(memberId)).called(1);
      });

      test('should create initial achievement if none exists', () async {
        // Arrange
        const memberId = 'member_1';

        when(mockBadgeRepository.getMemberAchievement(memberId))
            .thenThrow(Exception('Member achievement not found'));
        when(mockBadgeRepository.saveMemberAchievement(any))
            .thenAnswer((_) async {});

        // Act
        final result = await badgeService.getMemberAchievement(memberId);

        // Assert
        expect(result.memberId, equals(memberId));
        expect(result.totalPoints, equals(0));
        expect(result.level, equals(1));
        expect(result.levelTitle, equals('Newcomer'));
        verify(mockBadgeRepository.saveMemberAchievement(any)).called(1);
      });
    });

    group('awardBadge', () {
      test('should award badge if not already earned', () async {
        // Arrange
        const memberId = 'member_1';
        const badgeId = 'badge_1';
        final badge = Badge(
          id: badgeId,
          name: 'Test Badge',
          description: 'A test badge',
          iconUrl: '/badges/test.png',
          type: BadgeType.participation,
          criteria: {},
          pointValue: 50,
          rarity: BadgeRarity.common,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final achievement = MemberAchievement(
          id: 'achievement_1',
          memberId: memberId,
          totalPoints: 0,
          currentLevelPoints: 0,
          nextLevelPoints: 100,
          level: 1,
          levelTitle: 'Newcomer',
          categoryPoints: {},
          lastUpdated: DateTime.now(),
        );

        when(mockBadgeRepository.getMemberBadges(memberId))
            .thenAnswer((_) async => []);
        when(mockBadgeRepository.getBadge(badgeId))
            .thenAnswer((_) async => badge);
        when(mockBadgeRepository.saveMemberBadge(any))
            .thenAnswer((_) async {});
        when(mockBadgeRepository.getMemberAchievement(memberId))
            .thenAnswer((_) async => achievement);
        when(mockBadgeRepository.saveMemberAchievement(any))
            .thenAnswer((_) async {});
        when(mockNotificationService.sendNotification(
          recipientId: anyNamed('recipientId'),
          type: anyNamed('type'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {});

        // Act
        final result = await badgeService.awardBadge(memberId, badgeId);

        // Assert
        expect(result, isNotNull);
        expect(result!.memberId, equals(memberId));
        expect(result.badgeId, equals(badgeId));
        verify(mockBadgeRepository.saveMemberBadge(any)).called(1);
        verify(mockBadgeRepository.saveMemberAchievement(any)).called(1);
        verify(mockNotificationService.sendNotification(
          recipientId: anyNamed('recipientId'),
          type: anyNamed('type'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          data: anyNamed('data'),
        )).called(1);
      });

      test('should not award badge if already earned', () async {
        // Arrange
        const memberId = 'member_1';
        const badgeId = 'badge_1';
        final existingBadge = MemberBadge(
          id: 'member_badge_1',
          memberId: memberId,
          badgeId: badgeId,
          earnedAt: DateTime.now(),
        );

        when(mockBadgeRepository.getMemberBadges(memberId))
            .thenAnswer((_) async => [existingBadge]);

        // Act
        final result = await badgeService.awardBadge(memberId, badgeId);

        // Assert
        expect(result, isNull);
        verifyNever(mockBadgeRepository.saveMemberBadge(any));
      });
    });

    group('updateStreak', () {
      test('should create new streak if none exists', () async {
        // Arrange
        const memberId = 'member_1';
        const streakType = StreakType.participation;

        when(mockBadgeRepository.getMemberStreak(memberId, streakType))
            .thenAnswer((_) async => null);
        when(mockBadgeRepository.saveMemberStreak(any))
            .thenAnswer((_) async {});
        when(mockBadgeRepository.getStreakBadges(streakType))
            .thenAnswer((_) async => []);

        // Act
        await badgeService.updateStreak(memberId, streakType);

        // Assert
        verify(mockBadgeRepository.saveMemberStreak(any)).called(1);
      });

      test('should update existing streak correctly', () async {
        // Arrange
        const memberId = 'member_1';
        const streakType = StreakType.participation;
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

        final existingStreak = MemberStreak(
          id: 'streak_1',
          memberId: memberId,
          type: streakType,
          currentStreak: 3,
          longestStreak: 5,
          lastActivityDate: yesterdayDate,
          streakStartDate: DateTime.now().subtract(const Duration(days: 3)),
        );

        when(mockBadgeRepository.getMemberStreak(memberId, streakType))
            .thenAnswer((_) async => existingStreak);
        when(mockBadgeRepository.saveMemberStreak(any))
            .thenAnswer((_) async {});
        when(mockBadgeRepository.getStreakBadges(streakType))
            .thenAnswer((_) async => []);

        // Act
        await badgeService.updateStreak(memberId, streakType);

        // Assert
        final captured = verify(mockBadgeRepository.saveMemberStreak(captureAny)).captured;
        final updatedStreak = captured.first as MemberStreak;
        expect(updatedStreak.currentStreak, equals(4)); // Incremented
      });

      test('should reset streak if not consecutive', () async {
        // Arrange
        const memberId = 'member_1';
        const streakType = StreakType.participation;
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final twoDaysAgoDate = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);

        final existingStreak = MemberStreak(
          id: 'streak_1',
          memberId: memberId,
          type: streakType,
          currentStreak: 3,
          longestStreak: 5,
          lastActivityDate: twoDaysAgoDate,
          streakStartDate: DateTime.now().subtract(const Duration(days: 5)),
        );

        when(mockBadgeRepository.getMemberStreak(memberId, streakType))
            .thenAnswer((_) async => existingStreak);
        when(mockBadgeRepository.saveMemberStreak(any))
            .thenAnswer((_) async {});
        when(mockBadgeRepository.getStreakBadges(streakType))
            .thenAnswer((_) async => []);

        // Act
        await badgeService.updateStreak(memberId, streakType);

        // Assert
        final captured = verify(mockBadgeRepository.saveMemberStreak(captureAny)).captured;
        final updatedStreak = captured.first as MemberStreak;
        expect(updatedStreak.currentStreak, equals(1)); // Reset to 1
      });
    });

    group('checkAndAwardBadges', () {
      test('should check and award eligible badges', () async {
        // Arrange
        const memberId = 'member_1';
        final badges = [
          Badge(
            id: 'badge_1',
            name: 'First Event',
            description: 'Participated in first event',
            iconUrl: '/badges/first.png',
            type: BadgeType.participation,
            criteria: {'eventCount': 1},
            pointValue: 10,
            rarity: BadgeRarity.common,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final events = [
          Event(
            id: 'event_1',
            groupId: 'group_1',
            title: 'Test Event',
            description: 'A test event',
            eventType: EventType.competition,
            status: EventStatus.completed,
            createdBy: 'creator_1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockBadgeRepository.getAllBadges()).thenAnswer((_) async => badges);
        when(mockBadgeRepository.getMemberBadges(memberId)).thenAnswer((_) async => []);
        when(mockEventRepository.getMemberEvents(memberId)).thenAnswer((_) async => events);
        when(mockBadgeRepository.getBadge('badge_1')).thenAnswer((_) async => badges.first);
        when(mockBadgeRepository.saveMemberBadge(any)).thenAnswer((_) async {});
        when(mockBadgeRepository.getMemberAchievement(memberId)).thenThrow(Exception('Not found'));
        when(mockBadgeRepository.saveMemberAchievement(any)).thenAnswer((_) async {});
        when(mockNotificationService.sendNotification(
          recipientId: anyNamed('recipientId'),
          type: anyNamed('type'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {});

        // Act
        final result = await badgeService.checkAndAwardBadges(memberId);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.badgeId, equals('badge_1'));
        verify(mockBadgeRepository.saveMemberBadge(any)).called(1);
      });
    });

    group('getAchievementLeaderboard', () {
      test('should return leaderboard from repository', () async {
        // Arrange
        final leaderboard = [
          {
            'achievement': MemberAchievement(
              id: 'achievement_1',
              memberId: 'member_1',
              totalPoints: 500,
              currentLevelPoints: 0,
              nextLevelPoints: 250,
              level: 4,
              levelTitle: 'Achiever',
              categoryPoints: {},
              lastUpdated: DateTime.now(),
            ),
            'rank': 1,
          },
        ];

        when(mockBadgeRepository.getAchievementLeaderboard(limit: 10, groupId: null))
            .thenAnswer((_) async => leaderboard);

        // Act
        final result = await badgeService.getAchievementLeaderboard();

        // Assert
        expect(result, equals(leaderboard));
        verify(mockBadgeRepository.getAchievementLeaderboard(limit: 10, groupId: null)).called(1);
      });
    });

    group('createPredefinedBadges', () {
      test('should create predefined badges if they do not exist', () async {
        // Arrange
        when(mockBadgeRepository.getBadge(any)).thenAnswer((_) async => null);
        when(mockBadgeRepository.saveBadge(any)).thenAnswer((_) async {});

        // Act
        await badgeService.createPredefinedBadges();

        // Assert
        verify(mockBadgeRepository.saveBadge(any)).called(greaterThan(0));
      });

      test('should not create badges that already exist', () async {
        // Arrange
        final existingBadge = Badge(
          id: 'first_event',
          name: 'First Steps',
          description: 'Participated in your first event',
          iconUrl: '/badges/first_steps.png',
          type: BadgeType.participation,
          criteria: {'eventCount': 1},
          pointValue: 10,
          rarity: BadgeRarity.common,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockBadgeRepository.getBadge('first_event'))
            .thenAnswer((_) async => existingBadge);
        when(mockBadgeRepository.getBadge(argThat(isNot('first_event'))))
            .thenAnswer((_) async => null);
        when(mockBadgeRepository.saveBadge(any)).thenAnswer((_) async {});

        // Act
        await badgeService.createPredefinedBadges();

        // Assert
        // Should save all badges except the existing one
        verify(mockBadgeRepository.saveBadge(argThat(predicate<Badge>((badge) => badge.id != 'first_event'))))
            .called(greaterThan(0));
        verifyNever(mockBadgeRepository.saveBadge(argThat(predicate<Badge>((badge) => badge.id == 'first_event'))));
      });
    });
  });
}