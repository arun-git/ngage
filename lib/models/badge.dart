import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';

part 'badge.g.dart';

@JsonSerializable()
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType category;
  final BadgeRarity rarity;
  final Map<String, dynamic> criteria;
  final int pointValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.rarity,
    required this.criteria,
    required this.pointValue,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

@JsonSerializable()
class MemberBadge {
  final String id;
  final String memberId;
  final String badgeId;
  final DateTime awardedAt;
  final String? eventId;
  final String? submissionId;
  final Map<String, dynamic>? metadata;
  final bool isVisible;

  const MemberBadge({
    required this.id,
    required this.memberId,
    required this.badgeId,
    required this.awardedAt,
    this.eventId,
    this.submissionId,
    this.metadata,
    this.isVisible = true,
  });

  factory MemberBadge.fromJson(Map<String, dynamic> json) => _$MemberBadgeFromJson(json);
  Map<String, dynamic> toJson() => _$MemberBadgeToJson(this);
}

@JsonSerializable()
class MemberStreak {
  final String id;
  final String memberId;
  final StreakType type;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final DateTime streakStartDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberStreak({
    required this.id,
    required this.memberId,
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.streakStartDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemberStreak.fromJson(Map<String, dynamic> json) => _$MemberStreakFromJson(json);
  Map<String, dynamic> toJson() => _$MemberStreakToJson(this);
}

@JsonSerializable()
class MemberPoints {
  final String id;
  final String memberId;
  final int totalPoints;
  final Map<String, int> categoryPoints;
  final int level;
  final String levelTitle;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final DateTime lastUpdated;

  const MemberPoints({
    required this.id,
    required this.memberId,
    required this.totalPoints,
    required this.categoryPoints,
    required this.level,
    required this.levelTitle,
    required this.currentLevelPoints,
    required this.nextLevelPoints,
    required this.lastUpdated,
  });

  factory MemberPoints.fromJson(Map<String, dynamic> json) => _$MemberPointsFromJson(json);
  Map<String, dynamic> toJson() => _$MemberPointsToJson(this);
}

@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final AchievementType type;
  final Map<String, dynamic> requirements;
  final int pointReward;
  final String? badgeId;
  final bool isRepeatable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.requirements,
    required this.pointReward,
    this.badgeId,
    required this.isRepeatable,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

@JsonSerializable()
class MemberAchievement {
  final String id;
  final String memberId;
  final String achievementId;
  final DateTime unlockedAt;
  final String? eventId;
  final Map<String, dynamic>? context;
  final int pointsAwarded;

  const MemberAchievement({
    required this.id,
    required this.memberId,
    required this.achievementId,
    required this.unlockedAt,
    this.eventId,
    this.context,
    required this.pointsAwarded,
  });

  factory MemberAchievement.fromJson(Map<String, dynamic> json) => _$MemberAchievementFromJson(json);
  Map<String, dynamic> toJson() => _$MemberAchievementToJson(this);
}

@JsonSerializable()
class Milestone {
  final String id;
  final String name;
  final String description;
  final MilestoneType type;
  final int targetValue;
  final int pointReward;
  final String? badgeId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Milestone({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.pointReward,
    this.badgeId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => _$MilestoneFromJson(json);
  Map<String, dynamic> toJson() => _$MilestoneToJson(this);
}

@JsonSerializable()
class MemberMilestone {
  final String id;
  final String memberId;
  final String milestoneId;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool badgeAwarded;
  final int rewardPoints;
  final String? badgeId;

  const MemberMilestone({
    required this.id,
    required this.memberId,
    required this.milestoneId,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    this.completedAt,
    this.badgeAwarded = false,
    required this.rewardPoints,
    this.badgeId,
  });

  factory MemberMilestone.fromJson(Map<String, dynamic> json) => _$MemberMilestoneFromJson(json);
  Map<String, dynamic> toJson() => _$MemberMilestoneToJson(this);
}

