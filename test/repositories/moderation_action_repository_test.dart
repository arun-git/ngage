import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../lib/models/moderation_action.dart';
import '../../lib/repositories/moderation_action_repository.dart';

void main() {
  group('ModerationActionRepository', () {
    late ModerationActionRepository repository;
    late FakeFirebaseFirestore firestore;
    late ModerationAction testAction;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ModerationActionRepository(firestore: firestore);
      
      testAction = ModerationAction(
        id: 'action123',
        moderatorId: 'moderator456',
        targetId: 'target789',
        targetType: ModerationTargetType.post,
        actionType: ModerationActionType.hide,
        reason: 'Inappropriate content',
        notes: 'Hidden due to policy violation',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('createAction', () {
      test('should create a new action successfully', () async {
        final actionId = await repository.createAction(testAction);
        
        expect(actionId, isNotEmpty);
        
        final doc = await firestore.collection('moderation_actions').doc(actionId).get();
        expect(doc.exists, isTrue);
        
        final data = doc.data()!;
        expect(data['moderatorId'], equals('moderator456'));
        expect(data['targetId'], equals('target789'));
        expect(data['targetType'], equals('post'));
        expect(data['actionType'], equals('hide'));
        expect(data['isActive'], isTrue);
      });
    });

    group('getAction', () {
      test('should return action when it exists', () async {
        final actionId = await repository.createAction(testAction);
        
        final retrievedAction = await repository.getAction(actionId);
        
        expect(retrievedAction, isNotNull);
        expect(retrievedAction!.moderatorId, equals('moderator456'));
        expect(retrievedAction.targetId, equals('target789'));
        expect(retrievedAction.targetType, equals(ModerationTargetType.post));
        expect(retrievedAction.actionType, equals(ModerationActionType.hide));
      });

      test('should return null when action does not exist', () async {
        final retrievedAction = await repository.getAction('nonexistent');
        
        expect(retrievedAction, isNull);
      });
    });

    group('getActionsForTarget', () {
      test('should return actions for specific target', () async {
        // Create multiple actions for the same target
        final action1 = testAction;
        final action2 = testAction.copyWith(
          moderatorId: 'moderator2',
          actionType: ModerationActionType.delete,
        );
        
        await repository.createAction(action1);
        await repository.createAction(action2);
        
        // Create an action for different target
        final differentTargetAction = testAction.copyWith(
          targetId: 'different_target',
        );
        await repository.createAction(differentTargetAction);
        
        final actions = await repository.getActionsForTarget(
          'target789',
          ModerationTargetType.post,
        );
        
        expect(actions, hasLength(2));
        expect(actions.every((a) => a.targetId == 'target789'), isTrue);
        expect(actions.every((a) => a.targetType == ModerationTargetType.post), isTrue);
      });
    });

    group('getActiveActionsForTarget', () {
      test('should return only active actions for target', () async {
        final activeAction = testAction;
        final inactiveAction = testAction.copyWith(
          moderatorId: 'moderator2',
          isActive: false,
        );
        
        await repository.createAction(activeAction);
        await repository.createAction(inactiveAction);
        
        final activeActions = await repository.getActiveActionsForTarget(
          'target789',
          ModerationTargetType.post,
        );
        
        expect(activeActions, hasLength(1));
        expect(activeActions.first.isActive, isTrue);
      });

      test('should filter out expired actions', () async {
        final expiredAction = testAction.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final validAction = testAction.copyWith(
          moderatorId: 'moderator2',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        
        await repository.createAction(expiredAction);
        await repository.createAction(validAction);
        
        final activeActions = await repository.getActiveActionsForTarget(
          'target789',
          ModerationTargetType.post,
        );
        
        expect(activeActions, hasLength(1));
        expect(activeActions.first.moderatorId, equals('moderator2'));
      });
    });

    group('getActionsByModerator', () {
      test('should return actions by specific moderator', () async {
        final action1 = testAction;
        final action2 = testAction.copyWith(targetId: 'target2');
        final differentModeratorAction = testAction.copyWith(
          moderatorId: 'different_moderator',
          targetId: 'target3',
        );
        
        await repository.createAction(action1);
        await repository.createAction(action2);
        await repository.createAction(differentModeratorAction);
        
        final moderatorActions = await repository.getActionsByModerator('moderator456');
        
        expect(moderatorActions, hasLength(2));
        expect(moderatorActions.every((a) => a.moderatorId == 'moderator456'), isTrue);
      });

      test('should respect limit parameter', () async {
        for (int i = 0; i < 5; i++) {
          await repository.createAction(testAction.copyWith(targetId: 'target$i'));
        }
        
        final limitedActions = await repository.getActionsByModerator(
          'moderator456',
          limit: 3,
        );
        
        expect(limitedActions, hasLength(3));
      });
    });

    group('getActionsByType', () {
      test('should return actions of specific type', () async {
        final hideAction = testAction;
        final deleteAction = testAction.copyWith(
          targetId: 'target2',
          actionType: ModerationActionType.delete,
        );
        final warnAction = testAction.copyWith(
          targetId: 'target3',
          actionType: ModerationActionType.warn,
        );
        
        await repository.createAction(hideAction);
        await repository.createAction(deleteAction);
        await repository.createAction(warnAction);
        
        final hideActions = await repository.getActionsByType(ModerationActionType.hide);
        final deleteActions = await repository.getActionsByType(ModerationActionType.delete);
        
        expect(hideActions, hasLength(1));
        expect(hideActions.first.actionType, equals(ModerationActionType.hide));
        
        expect(deleteActions, hasLength(1));
        expect(deleteActions.first.actionType, equals(ModerationActionType.delete));
      });
    });

    group('updateActionStatus', () {
      test('should update action status successfully', () async {
        final actionId = await repository.createAction(testAction);
        
        await repository.updateActionStatus(actionId, false);
        
        final updatedAction = await repository.getAction(actionId);
        
        expect(updatedAction!.isActive, isFalse);
      });
    });

    group('deactivateAction', () {
      test('should deactivate action successfully', () async {
        final actionId = await repository.createAction(testAction);
        
        await repository.deactivateAction(actionId);
        
        final updatedAction = await repository.getAction(actionId);
        
        expect(updatedAction!.isActive, isFalse);
      });
    });

    group('deleteAction', () {
      test('should delete action successfully', () async {
        final actionId = await repository.createAction(testAction);
        
        // Verify action exists
        final actionBeforeDelete = await repository.getAction(actionId);
        expect(actionBeforeDelete, isNotNull);
        
        await repository.deleteAction(actionId);
        
        // Verify action is deleted
        final actionAfterDelete = await repository.getAction(actionId);
        expect(actionAfterDelete, isNull);
      });
    });

    group('getModerationStatistics', () {
      test('should return correct statistics', () async {
        // Create actions with different types
        await repository.createAction(testAction); // hide
        await repository.createAction(testAction.copyWith(
          targetId: 'target2',
          actionType: ModerationActionType.delete,
        ));
        await repository.createAction(testAction.copyWith(
          targetId: 'target3',
          actionType: ModerationActionType.suspend,
        ));
        await repository.createAction(testAction.copyWith(
          targetId: 'target4',
          actionType: ModerationActionType.ban,
        ));
        
        final stats = await repository.getModerationStatistics();
        
        expect(stats['hidden'], equals(1));
        expect(stats['deleted'], equals(1));
        expect(stats['suspended'], equals(1));
        expect(stats['banned'], equals(1));
        expect(stats['totalActive'], equals(4));
      });
    });

    group('isContentHidden', () {
      test('should return true when content is hidden', () async {
        await repository.createAction(testAction);
        
        final isHidden = await repository.isContentHidden(
          'target789',
          ModerationTargetType.post,
        );
        
        expect(isHidden, isTrue);
      });

      test('should return true when content is deleted', () async {
        final deleteAction = testAction.copyWith(
          actionType: ModerationActionType.delete,
        );
        await repository.createAction(deleteAction);
        
        final isHidden = await repository.isContentHidden(
          'target789',
          ModerationTargetType.post,
        );
        
        expect(isHidden, isTrue);
      });

      test('should return false when content is not hidden or deleted', () async {
        final warnAction = testAction.copyWith(
          actionType: ModerationActionType.warn,
        );
        await repository.createAction(warnAction);
        
        final isHidden = await repository.isContentHidden(
          'target789',
          ModerationTargetType.post,
        );
        
        expect(isHidden, isFalse);
      });
    });

    group('isUserRestricted', () {
      test('should return true when user is suspended', () async {
        final suspendAction = testAction.copyWith(
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.suspend,
        );
        await repository.createAction(suspendAction);
        
        final isRestricted = await repository.isUserRestricted('target789');
        
        expect(isRestricted, isTrue);
      });

      test('should return true when user is banned', () async {
        final banAction = testAction.copyWith(
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.ban,
        );
        await repository.createAction(banAction);
        
        final isRestricted = await repository.isUserRestricted('target789');
        
        expect(isRestricted, isTrue);
      });

      test('should return false when user is not restricted', () async {
        final warnAction = testAction.copyWith(
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.warn,
        );
        await repository.createAction(warnAction);
        
        final isRestricted = await repository.isUserRestricted('target789');
        
        expect(isRestricted, isFalse);
      });
    });

    group('getUserRestrictions', () {
      test('should return user restrictions', () async {
        final suspendAction = testAction.copyWith(
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.suspend,
        );
        final warnAction = testAction.copyWith(
          targetId: 'target789',
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.warn,
          moderatorId: 'moderator2',
        );
        final hideAction = testAction.copyWith(
          targetId: 'target789',
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.hide,
          moderatorId: 'moderator3',
        );
        
        await repository.createAction(suspendAction);
        await repository.createAction(warnAction);
        await repository.createAction(hideAction); // Should not be included
        
        final restrictions = await repository.getUserRestrictions('target789');
        
        expect(restrictions, hasLength(2));
        expect(restrictions.any((r) => r.actionType == ModerationActionType.suspend), isTrue);
        expect(restrictions.any((r) => r.actionType == ModerationActionType.warn), isTrue);
        expect(restrictions.any((r) => r.actionType == ModerationActionType.hide), isFalse);
      });
    });

    group('cleanupExpiredActions', () {
      test('should deactivate expired actions', () async {
        final expiredAction = testAction.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final validAction = testAction.copyWith(
          targetId: 'target2',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        
        final expiredActionId = await repository.createAction(expiredAction);
        final validActionId = await repository.createAction(validAction);
        
        await repository.cleanupExpiredActions();
        
        final expiredActionAfterCleanup = await repository.getAction(expiredActionId);
        final validActionAfterCleanup = await repository.getAction(validActionId);
        
        expect(expiredActionAfterCleanup!.isActive, isFalse);
        expect(validActionAfterCleanup!.isActive, isTrue);
      });
    });
  });
}