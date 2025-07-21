import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngage/models/models.dart';

void main() {
  group('Badge Model Tests', () {
    final testBadge = Badge(
      id: 'test_badge_1',
      name: 'Test Badge',
      description: 'A test badge for unit testing',
      iconUrl: '/badges/test.png',
      type: BadgeType.participation,
      criteria: {'eventCount': 5},
      pointValue: 50,
      rarity: BadgeRarity.common,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should create Badge with all properties', () {
      expect(testBadge.id, equals('test_badge_1'));
      expect(testBadge.name, equals('Test Badge'));
      expect(testBadge.description, equals('A test badge for unit testing'));
      expect(testBadge.iconUrl, equals('/badges/test.png'));
      expect(testBadge.type, equals(BadgeType.participation));
      expect(testBadge.criteria, equals({'eventCount': 5}));
      expect(testBadge.pointValue, equals(50));
      expect(testBadge.rarity, equals(BadgeRarity.common));
      expect(testBadge.isActive, isTrue);
    });

    test('should convert Badge to JSON correctly', () {
      final json = testBadge.toJson();

      expect(json['id'], equals('test_badge_1'));
      expect(json['name'], equals('Test Badge'));
      expect(json['description'], equals('A test badge for unit testing'));
      expect(json['iconUrl'], equals('/badges/test.png'));
      expect(json['type'], equals('participation'));
      expect(json['criteria'], equals({'eventCount': 5}));
      expect(json['pointValue'], equals(50));
      expect(json['rarity'], equals('common'));
      expect(json['isActive'], isTrue);
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['updatedAt'], isA<Timestamp>());
    });

    test('should create Badge from JSON correctly', () {
      final json = {
        'id': 'test_badge_2',
        'name': 'JSON Badge',
        'description': 'Badge created from JSON',
        'iconUrl': '/badges/json.png',
        'type': 'performance',
        'criteria': {'winCount': 3},
        'pointValue': 100,
        'rarity': 'rare',
        'isActive': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 2, 2)),
      };

      final badge = Badge.fromJson(json);

      expect(badge.id, equals('test_badge_2'));
      expect(badge.name, equals('JSON Badge'));
      expect(badge.description, equals('Badge created from JSON'));
      expect(badge.iconUrl, equals('/badges/json.png'));
      expect(badge.type, equals(BadgeType.performance));
      expect(badge.criteria, equals({'winCount': 3}));
      expect(badge.pointValue, equals(100));
      expect(badge.rarity, equals(BadgeRarity.rare));
      expect(badge.isActive, isFalse);
    });

    test('should handle unknown enum values gracefully', () {
      final json = {
        'id': 'test_badge_3',
        'name': 'Unknown Badge',
        'description': 'Badge with unknown enums',
        'iconUrl': '/badges/unknown.png',
        'type': 'unknown_type',
        'criteria': {},
        'pointValue': 25,
        'rarity': 'unknown_rarity',
        'createdAt': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 3, 2)),
      };

      final badge = Badge.fromJson(json);

      expect(badge.type, equals(BadgeType.participation)); // Default fallback
      expect(badge.rarity, equals(BadgeRarity.common)); // Default fallback
    });

    test('should create copy with updated properties', () {
      final updatedBadge = testBadge.copyWith(
        name: 'Updated Badge',
        pointValue: 75,
        isActive: false,
      );

      expect(updatedBadge.id, equals(testBadge.id));
      expect(updatedBadge.name, equals('Updated Badge'));
      expect(updatedBadge.pointValue, equals(75));
      expect(updatedBadge.isActive, isFalse);
      expect(updatedBadge.description, equals(testBadge.description));
    });

    test('should implement equality correctly', () {
      final badge1 = Badge(
        id: 'same_id',
        name: 'Badge 1',
        description: 'First badge',
        iconUrl: '/badges/1.png',
        type: BadgeType.participation,
        criteria: {},
        pointValue: 10,
        rarity: BadgeRarity.common,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final badge2 = Badge(
        id: 'same_id',
        name: 'Badge 2',
        description: 'Second badge',
        iconUrl: '/badges/2.png',
        type: BadgeType.performance,
        criteria: {},
        pointValue: 20,
        rarity: BadgeRarity.rare,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final badge3 = Badge(
        id: 'different_id',
        name: 'Badge 1',
        description: 'First badge',
        iconUrl: '/badges/1.png',
        type: BadgeType.participation,
        criteria: {},
        pointValue: 10,
        rarity: BadgeRarity.common,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(badge1, equals(badge2)); // Same ID
      expect(badge1, isNot(equals(badge3))); // Different ID
      expect(badge1.hashCode, equals(badge2.hashCode));
      expect(badge1.hashCode, isNot(equals(badge3.hashCode)));
    });
  });

  group('MemberBadge Model Tests', () {
    final testMemberBadge = MemberBadge(
      id: 'member_badge_1',
      memberId: 'member_1',
      badgeId: 'badge_1',
      earnedAt: DateTime(2024, 1, 15),
      context: {'eventId': 'event_1'},
    );

    test('should create MemberBadge with all properties', () {
      expect(testMemberBadge.id, equals('member_badge_1'));
      expect(testMemberBadge.memberId, equals('member_1'));
      expect(testMemberBadge.badgeId, equals('badge_1'));
      expect(testMemberBadge.earnedAt, equals(DateTime(2024, 1, 15)));
      expect(testMemberBadge.context, equals({'eventId': 'event_1'}));
      expect(testMemberBadge.isVisible, isTrue);
    });

    test('should convert MemberBadge to JSON correctly', () {
      final json = testMemberBadge.toJson();

      expect(json['id'], equals('member_badge_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['badgeId'], equals('badge_1'));
      expect(json['earnedAt'], isA<Timestamp>());
      expect(json['context'], equals({'eventId': 'event_1'}));
      expect(json['isVisible'], isTrue);
    });

    test('should create MemberBadge from JSON correctly', () {
      final json = {
        'id': 'member_badge_2',
        'memberId': 'member_2',
        'badgeId': 'badge_2',
        'earnedAt': Timestamp.fromDate(DateTime(2024, 2, 15)),
        'context': {'submissionId': 'submission_1'},
        'isVisible': false,
      };

      final memberBadge = MemberBadge.fromJson(json);

      expect(memberBadge.id, equals('member_badge_2'));
      expect(memberBadge.memberId, equals('member_2'));
      expect(memberBadge.badgeId, equals('badge_2'));
      expect(memberBadge.context, equals({'submissionId': 'submission_1'}));
      expect(memberBadge.isVisible, isFalse);
    });
  });

  group('MemberStreak Model Tests', () {
    final testStreak = MemberStreak(
      id: 'streak_1',
      memberId: 'member_1',
      type: StreakType.participation,
      currentStreak: 5,
      longestStreak: 10,
      lastActivityDate: DateTime(2024, 1, 20),
      streakStartDate: DateTime(2024, 1, 16),
    );

    test('should create MemberStreak with all properties', () {
      expect(testStreak.id, equals('streak_1'));
      expect(testStreak.memberId, equals('member_1'));
      expect(testStreak.type, equals(StreakType.participation));
      expect(testStreak.currentStreak, equals(5));
      expect(testStreak.longestStreak, equals(10));
      expect(testStreak.lastActivityDate, equals(DateTime(2024, 1, 20)));
      expect(testStreak.streakStartDate, equals(DateTime(2024, 1, 16)));
    });

    test('should convert MemberStreak to JSON correctly', () {
      final json = testStreak.toJson();

      expect(json['id'], equals('streak_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['type'], equals('participation'));
      expect(json['currentStreak'], equals(5));
      expect(json['longestStreak'], equals(10));
      expect(json['lastActivityDate'], isA<Timestamp>());
      expect(json['streakStartDate'], isA<Timestamp>());
    });

    test('should create MemberStreak from JSON correctly', () {
      final json = {
        'id': 'streak_2',
        'memberId': 'member_2',
        'type': 'submission',
        'currentStreak': 3,
        'longestStreak': 7,
        'lastActivityDate': Timestamp.fromDate(DateTime(2024, 2, 20)),
        'streakStartDate': Timestamp.fromDate(DateTime(2024, 2, 18)),
        'metadata': {'category': 'test'},
      };

      final streak = MemberStreak.fromJson(json);

      expect(streak.id, equals('streak_2'));
      expect(streak.memberId, equals('member_2'));
      expect(streak.type, equals(StreakType.submission));
      expect(streak.currentStreak, equals(3));
      expect(streak.longestStreak, equals(7));
      expect(streak.metadata, equals({'category': 'test'}));
    });
  });

  group('MemberAchievement Model Tests', () {
    final testAchievement = MemberAchievement(
      id: 'achievement_1',
      memberId: 'member_1',
      totalPoints: 250,
      currentLevelPoints: 50,
      nextLevelPoints: 100,
      level: 3,
      levelTitle: 'Contributor',
      categoryPoints: {'participation': 150, 'social': 100},
      lastUpdated: DateTime(2024, 1, 25),
    );

    test('should create MemberAchievement with all properties', () {
      expect(testAchievement.id, equals('achievement_1'));
      expect(testAchievement.memberId, equals('member_1'));
      expect(testAchievement.totalPoints, equals(250));
      expect(testAchievement.currentLevelPoints, equals(50));
      expect(testAchievement.nextLevelPoints, equals(100));
      expect(testAchievement.level, equals(3));
      expect(testAchievement.levelTitle, equals('Contributor'));
      expect(testAchievement.categoryPoints, equals({'participation': 150, 'social': 100}));
    });

    test('should convert MemberAchievement to JSON correctly', () {
      final json = testAchievement.toJson();

      expect(json['id'], equals('achievement_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['totalPoints'], equals(250));
      expect(json['currentLevelPoints'], equals(50));
      expect(json['nextLevelPoints'], equals(100));
      expect(json['level'], equals(3));
      expect(json['levelTitle'], equals('Contributor'));
      expect(json['categoryPoints'], equals({'participation': 150, 'social': 100}));
      expect(json['lastUpdated'], isA<Timestamp>());
    });

    test('should create MemberAchievement from JSON correctly', () {
      final json = {
        'id': 'achievement_2',
        'memberId': 'member_2',
        'totalPoints': 500,
        'currentLevelPoints': 0,
        'nextLevelPoints': 250,
        'level': 4,
        'levelTitle': 'Achiever',
        'categoryPoints': {'performance': 300, 'milestone': 200},
        'lastUpdated': Timestamp.fromDate(DateTime(2024, 2, 25)),
      };

      final achievement = MemberAchievement.fromJson(json);

      expect(achievement.id, equals('achievement_2'));
      expect(achievement.memberId, equals('member_2'));
      expect(achievement.totalPoints, equals(500));
      expect(achievement.level, equals(4));
      expect(achievement.levelTitle, equals('Achiever'));
      expect(achievement.categoryPoints, equals({'performance': 300, 'milestone': 200}));
    });
  });
}