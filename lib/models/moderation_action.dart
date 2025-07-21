import 'package:cloud_firestore/cloud_firestore.dart';

enum ModerationActionType {
  hide,
  delete,
  warn,
  suspend,
  ban,
  approve,
  dismiss,
}

enum ModerationTargetType {
  post,
  comment,
  user,
  submission,
}

class ModerationAction {
  final String id;
  final String moderatorId; // Admin member ID who took action
  final String targetId; // ID of the content or user being moderated
  final ModerationTargetType targetType;
  final ModerationActionType actionType;
  final String? reason;
  final String? notes;
  final String? reportId; // Associated report ID if applicable
  final DateTime? expiresAt; // For temporary actions like suspensions
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ModerationAction({
    required this.id,
    required this.moderatorId,
    required this.targetId,
    required this.targetType,
    required this.actionType,
    this.reason,
    this.notes,
    this.reportId,
    this.expiresAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModerationAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationAction(
      id: doc.id,
      moderatorId: data['moderatorId'] as String,
      targetId: data['targetId'] as String,
      targetType: ModerationTargetType.values.firstWhere(
        (e) => e.name == data['targetType'],
      ),
      actionType: ModerationActionType.values.firstWhere(
        (e) => e.name == data['actionType'],
      ),
      reason: data['reason'] as String?,
      notes: data['notes'] as String?,
      reportId: data['reportId'] as String?,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'moderatorId': moderatorId,
      'targetId': targetId,
      'targetType': targetType.name,
      'actionType': actionType.name,
      'reason': reason,
      'notes': notes,
      'reportId': reportId,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ModerationAction copyWith({
    String? id,
    String? moderatorId,
    String? targetId,
    ModerationTargetType? targetType,
    ModerationActionType? actionType,
    String? reason,
    String? notes,
    String? reportId,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModerationAction(
      id: id ?? this.id,
      moderatorId: moderatorId ?? this.moderatorId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      actionType: actionType ?? this.actionType,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      reportId: reportId ?? this.reportId,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModerationAction &&
        other.id == id &&
        other.moderatorId == moderatorId &&
        other.targetId == targetId &&
        other.targetType == targetType &&
        other.actionType == actionType &&
        other.reason == reason &&
        other.notes == notes &&
        other.reportId == reportId &&
        other.expiresAt == expiresAt &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      moderatorId,
      targetId,
      targetType,
      actionType,
      reason,
      notes,
      reportId,
      expiresAt,
      isActive,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ModerationAction(id: $id, moderatorId: $moderatorId, targetId: $targetId, actionType: $actionType, isActive: $isActive)';
  }
}