import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/moderation_action.dart';

class ModerationActionRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'moderation_actions';

  ModerationActionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _actionsRef => _firestore.collection(_collection);

  /// Create a new moderation action
  Future<String> createAction(ModerationAction action) async {
    try {
      final docRef = await _actionsRef.add(action.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create moderation action: $e');
    }
  }

  /// Get a moderation action by ID
  Future<ModerationAction?> getAction(String actionId) async {
    try {
      final doc = await _actionsRef.doc(actionId).get();
      if (!doc.exists) return null;
      return ModerationAction.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get moderation action: $e');
    }
  }

  /// Get all actions for a specific target
  Future<List<ModerationAction>> getActionsForTarget(
    String targetId,
    ModerationTargetType targetType,
  ) async {
    try {
      final query = await _actionsRef
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType.name)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ModerationAction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get actions for target: $e');
    }
  }

  /// Get active actions for a specific target
  Future<List<ModerationAction>> getActiveActionsForTarget(
    String targetId,
    ModerationTargetType targetType,
  ) async {
    try {
      final query = await _actionsRef
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType.name)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final actions = query.docs
          .map((doc) => ModerationAction.fromFirestore(doc))
          .toList();

      // Filter out expired actions
      return actions.where((action) => !action.isExpired).toList();
    } catch (e) {
      throw Exception('Failed to get active actions for target: $e');
    }
  }

  /// Get actions by moderator
  Future<List<ModerationAction>> getActionsByModerator(
    String moderatorId, {
    int? limit,
  }) async {
    try {
      Query query = _actionsRef
          .where('moderatorId', isEqualTo: moderatorId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ModerationAction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get actions by moderator: $e');
    }
  }

  /// Get actions by type
  Future<List<ModerationAction>> getActionsByType(
    ModerationActionType actionType, {
    int? limit,
  }) async {
    try {
      Query query = _actionsRef
          .where('actionType', isEqualTo: actionType.name)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ModerationAction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get actions by type: $e');
    }
  }

  /// Update action status
  Future<void> updateActionStatus(String actionId, bool isActive) async {
    try {
      await _actionsRef.doc(actionId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update action status: $e');
    }
  }

  /// Deactivate action
  Future<void> deactivateAction(String actionId) async {
    return updateActionStatus(actionId, false);
  }

  /// Delete a moderation action
  Future<void> deleteAction(String actionId) async {
    try {
      await _actionsRef.doc(actionId).delete();
    } catch (e) {
      throw Exception('Failed to delete moderation action: $e');
    }
  }

  /// Get moderation statistics
  Future<Map<String, int>> getModerationStatistics() async {
    try {
      final hideQuery = await _actionsRef
          .where('actionType', isEqualTo: ModerationActionType.hide.name)
          .where('isActive', isEqualTo: true)
          .get();
      
      final deleteQuery = await _actionsRef
          .where('actionType', isEqualTo: ModerationActionType.delete.name)
          .where('isActive', isEqualTo: true)
          .get();
      
      final suspendQuery = await _actionsRef
          .where('actionType', isEqualTo: ModerationActionType.suspend.name)
          .where('isActive', isEqualTo: true)
          .get();
      
      final banQuery = await _actionsRef
          .where('actionType', isEqualTo: ModerationActionType.ban.name)
          .where('isActive', isEqualTo: true)
          .get();

      return {
        'hidden': hideQuery.docs.length,
        'deleted': deleteQuery.docs.length,
        'suspended': suspendQuery.docs.length,
        'banned': banQuery.docs.length,
        'totalActive': hideQuery.docs.length + 
                      deleteQuery.docs.length + 
                      suspendQuery.docs.length + 
                      banQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get moderation statistics: $e');
    }
  }

  /// Check if content is hidden
  Future<bool> isContentHidden(String contentId, ModerationTargetType targetType) async {
    try {
      final actions = await getActiveActionsForTarget(contentId, targetType);
      return actions.any((action) => 
          action.actionType == ModerationActionType.hide ||
          action.actionType == ModerationActionType.delete);
    } catch (e) {
      throw Exception('Failed to check if content is hidden: $e');
    }
  }

  /// Check if user is suspended or banned
  Future<bool> isUserRestricted(String userId) async {
    try {
      final actions = await getActiveActionsForTarget(userId, ModerationTargetType.user);
      return actions.any((action) => 
          action.actionType == ModerationActionType.suspend ||
          action.actionType == ModerationActionType.ban);
    } catch (e) {
      throw Exception('Failed to check if user is restricted: $e');
    }
  }

  /// Get user restrictions
  Future<List<ModerationAction>> getUserRestrictions(String userId) async {
    try {
      final actions = await getActiveActionsForTarget(userId, ModerationTargetType.user);
      return actions.where((action) => 
          action.actionType == ModerationActionType.suspend ||
          action.actionType == ModerationActionType.ban ||
          action.actionType == ModerationActionType.warn).toList();
    } catch (e) {
      throw Exception('Failed to get user restrictions: $e');
    }
  }

  /// Clean up expired actions
  Future<void> cleanupExpiredActions() async {
    try {
      final now = Timestamp.now();
      final expiredQuery = await _actionsRef
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': now,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup expired actions: $e');
    }
  }
}