// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      category: $enumDecode(_$BadgeTypeEnumMap, json['category']),
      rarity: $enumDecode(_$BadgeRarityEnumMap, json['rarity']),
      criteria: json['criteria'] as Map<String, dynamic>,
      pointValue: (json['pointValue'] as num).toInt(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'category': _$BadgeTypeEnumMap[instance.category]!,
      'rarity': _$BadgeRarityEnumMap[instance.rarity]!,
      'criteria': instance.criteria,
      'pointValue': instance.pointValue,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$BadgeTypeEnumMap = {
  BadgeType.participation: 'participation',
  BadgeType.performance: 'performance',
  BadgeType.social: 'social',
  BadgeType.milestone: 'milestone',
  BadgeType.special: 'special',
};

const _$BadgeRarityEnumMap = {
  BadgeRarity.common: 'common',
  BadgeRarity.uncommon: 'uncommon',
  BadgeRarity.rare: 'rare',
  BadgeRarity.epic: 'epic',
  BadgeRarity.legendary: 'legendary',
};

MemberBadge _$MemberBadgeFromJson(Map<String, dynamic> json) => MemberBadge(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      badgeId: json['badgeId'] as String,
      awardedAt: DateTime.parse(json['awardedAt'] as String),
      eventId: json['eventId'] as String?,
      submissionId: json['submissionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isVisible: json['isVisible'] as bool? ?? true,
    );

Map<String, dynamic> _$MemberBadgeToJson(MemberBadge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memberId': instance.memberId,
      'badgeId': instance.badgeId,
      'awardedAt': instance.awardedAt.toIso8601String(),
      'eventId': instance.eventId,
      'submissionId': instance.submissionId,
      'metadata': instance.metadata,
      'isVisible': instance.isVisible,
    };

MemberStreak _$MemberStreakFromJson(Map<String, dynamic> json) => MemberStreak(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      type: $enumDecode(_$StreakTypeEnumMap, json['type']),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      lastActivityDate: DateTime.parse(json['lastActivityDate'] as String),
      streakStartDate: DateTime.parse(json['streakStartDate'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MemberStreakToJson(MemberStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memberId': instance.memberId,
      'type': _$StreakTypeEnumMap[instance.type]!,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'lastActivityDate': instance.lastActivityDate.toIso8601String(),
      'streakStartDate': instance.streakStartDate.toIso8601String(),
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$StreakTypeEnumMap = {
  StreakType.dailyLogin: 'dailyLogin',
  StreakType.eventParticipation: 'eventParticipation',
  StreakType.socialEngagement: 'socialEngagement',
  StreakType.submissionStreak: 'submissionStreak',
  StreakType.judgingStreak: 'judgingStreak',
  StreakType.participation: 'participation',
  StreakType.submission: 'submission',
  StreakType.judging: 'judging',
  StreakType.social: 'social',
};

MemberPoints _$MemberPointsFromJson(Map<String, dynamic> json) => MemberPoints(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      totalPoints: (json['totalPoints'] as num).toInt(),
      categoryPoints: Map<String, int>.from(json['categoryPoints'] as Map),
      level: (json['level'] as num).toInt(),
      levelTitle: json['levelTitle'] as String,
      currentLevelPoints: (json['currentLevelPoints'] as num).toInt(),
      nextLevelPoints: (json['nextLevelPoints'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$MemberPointsToJson(MemberPoints instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memberId': instance.memberId,
      'totalPoints': instance.totalPoints,
      'categoryPoints': instance.categoryPoints,
      'level': instance.level,
      'levelTitle': instance.levelTitle,
      'currentLevelPoints': instance.currentLevelPoints,
      'nextLevelPoints': instance.nextLevelPoints,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      requirements: json['requirements'] as Map<String, dynamic>,
      pointReward: (json['pointReward'] as num).toInt(),
      badgeId: json['badgeId'] as String?,
      isRepeatable: json['isRepeatable'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'requirements': instance.requirements,
      'pointReward': instance.pointReward,
      'badgeId': instance.badgeId,
      'isRepeatable': instance.isRepeatable,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AchievementTypeEnumMap = {
  AchievementType.milestone: 'milestone',
  AchievementType.streak: 'streak',
  AchievementType.performance: 'performance',
  AchievementType.social: 'social',
  AchievementType.event: 'event',
  AchievementType.special: 'special',
};

MemberAchievement _$MemberAchievementFromJson(Map<String, dynamic> json) =>
    MemberAchievement(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      achievementId: json['achievementId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      eventId: json['eventId'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      pointsAwarded: (json['pointsAwarded'] as num).toInt(),
    );

Map<String, dynamic> _$MemberAchievementToJson(MemberAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memberId': instance.memberId,
      'achievementId': instance.achievementId,
      'unlockedAt': instance.unlockedAt.toIso8601String(),
      'eventId': instance.eventId,
      'context': instance.context,
      'pointsAwarded': instance.pointsAwarded,
    };

Milestone _$MilestoneFromJson(Map<String, dynamic> json) => Milestone(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$MilestoneTypeEnumMap, json['type']),
      targetValue: (json['targetValue'] as num).toInt(),
      pointReward: (json['pointReward'] as num).toInt(),
      badgeId: json['badgeId'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MilestoneToJson(Milestone instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$MilestoneTypeEnumMap[instance.type]!,
      'targetValue': instance.targetValue,
      'pointReward': instance.pointReward,
      'badgeId': instance.badgeId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$MilestoneTypeEnumMap = {
  MilestoneType.totalPoints: 'totalPoints',
  MilestoneType.eventParticipation: 'eventParticipation',
  MilestoneType.socialPosts: 'socialPosts',
  MilestoneType.badgesEarned: 'badgesEarned',
  MilestoneType.streakDays: 'streakDays',
  MilestoneType.submissionsCount: 'submissionsCount',
  MilestoneType.judgeScores: 'judgeScores',
};

MemberMilestone _$MemberMilestoneFromJson(Map<String, dynamic> json) =>
    MemberMilestone(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      milestoneId: json['milestoneId'] as String,
      currentProgress: (json['currentProgress'] as num).toInt(),
      targetProgress: (json['targetProgress'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      badgeAwarded: json['badgeAwarded'] as bool? ?? false,
      rewardPoints: (json['rewardPoints'] as num).toInt(),
      badgeId: json['badgeId'] as String?,
    );

Map<String, dynamic> _$MemberMilestoneToJson(MemberMilestone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memberId': instance.memberId,
      'milestoneId': instance.milestoneId,
      'currentProgress': instance.currentProgress,
      'targetProgress': instance.targetProgress,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
      'badgeAwarded': instance.badgeAwarded,
      'rewardPoints': instance.rewardPoints,
      'badgeId': instance.badgeId,
    };
