import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../lib/models/moderation_action.dart';

void main() {
  group('ModerationAction', () {
    late ModerationAction testAction;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testAction = ModerationAction(
        id: 'action123',
        moderatorId: 'moderator456',
        targetId: 'target789',
        targetType: ModerationTargetType.post,
        actionType: ModerationActionType.hide,
        reason: 'Inappropriate content',
        notes: 'Hidden due to policy violation',
        isActive: true,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    test('should create ModerationAction with required fields', () {
      expect(testAction.id, equals('action123'));
      expect(testAction.moderatorId, equals('moderator456'));
      expect(testAction.targetId, equals('target789'));
      expect(testAction.targetType, equals(ModerationTargetType.post));
      expect(testAction.actionType, equals(ModerationActionType.hide));
      expect(testAction.isActive, isTrue);
    });

    test('should create ModerationAction with optional fields', () {
      expect(testAction.reason, equals('Inappropriate content'));
      expect(testAction.notes, equals('Hidden due to policy violation'));
      expect(testAction.reportId, isNull);
      expect(testAction.expiresAt, isNull);
    });

    test('should convert to Firestore format correctly', () {
      final firestoreData = testAction.toFirestore();

      expect(firestoreData['moderatorId'], equals('moderator456'));
      expect(firestoreData['targetId'], equals('target789'));
      expect(firestoreData['targetType'], equals('post'));
      expect(firestoreData['actionType'], equals('hide'));
      expect(firestoreData['reason'], equals('Inappropriate content'));
      expect(firestoreData['notes'], equals('Hidden due to policy violation'));
      expect(firestoreData['reportId'], isNull);
      expect(firestoreData['expiresAt'], isNull);
      expect(firestoreData['isActive'], isTrue);
      expect(firestoreData['createdAt'], isA<Timestamp>());
      expect(firestoreData['updatedAt'], isA<Timestamp>());
    });

    test('should create from Firestore document correctly', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('actions').doc('action123');
      
      await docRef.set({
        'moderatorId': 'moderator456',
        'targetId': 'target789',
        'targetType': 'post',
        'actionType': 'hide',
        'reason': 'Inappropriate content',
        'notes': 'Hidden due to policy violation',
        'reportId': null,
        'expiresAt': null,
        'isActive': true,
        'createdAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
      });

      final doc = await docRef.get();
      final action = ModerationAction.fromFirestore(doc);

      expect(action.id, equals('action123'));
      expect(action.moderatorId, equals('moderator456'));
      expect(action.targetId, equals('target789'));
      expect(action.targetType, equals(ModerationTargetType.post));
      expect(action.actionType, equals(ModerationActionType.hide));
      expect(action.reason, equals('Inappropriate content'));
      expect(action.notes, equals('Hidden due to policy violation'));
      expect(action.isActive, isTrue);
    });

    test('should create copyWith correctly', () {
      final updatedAction = testAction.copyWith(
        isActive: false,
        notes: 'Action reversed',
      );

      expect(updatedAction.id, equals(testAction.id));
      expect(updatedAction.moderatorId, equals(testAction.moderatorId));
      expect(updatedAction.isActive, isFalse);
      expect(updatedAction.notes, equals('Action reversed'));
      expect(updatedAction.reason, equals(testAction.reason));
    });

    test('should handle expiration correctly', () {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));

      final futureAction = testAction.copyWith(expiresAt: futureDate);
      final pastAction = testAction.copyWith(expiresAt: pastDate);
      final noExpiryAction = testAction.copyWith(expiresAt: null);

      expect(futureAction.isExpired, isFalse);
      expect(pastAction.isExpired, isTrue);
      expect(noExpiryAction.isExpired, isFalse);
    });

    test('should handle equality correctly', () {
      final sameAction = ModerationAction(
        id: 'action123',
        moderatorId: 'moderator456',
        targetId: 'target789',
        targetType: ModerationTargetType.post,
        actionType: ModerationActionType.hide,
        reason: 'Inappropriate content',
        notes: 'Hidden due to policy violation',
        isActive: true,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final differentAction = testAction.copyWith(id: 'different123');

      expect(testAction, equals(sameAction));
      expect(testAction, isNot(equals(differentAction)));
    });

    test('should generate correct hashCode', () {
      final sameAction = ModerationAction(
        id: 'action123',
        moderatorId: 'moderator456',
        targetId: 'target789',
        targetType: ModerationTargetType.post,
        actionType: ModerationActionType.hide,
        reason: 'Inappropriate content',
        notes: 'Hidden due to policy violation',
        isActive: true,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(testAction.hashCode, equals(sameAction.hashCode));
    });

    test('should generate correct toString', () {
      final stringRepresentation = testAction.toString();
      
      expect(stringRepresentation, contains('ModerationAction'));
      expect(stringRepresentation, contains('action123'));
      expect(stringRepresentation, contains('moderator456'));
      expect(stringRepresentation, contains('target789'));
      expect(stringRepresentation, contains('hide'));
      expect(stringRepresentation, contains('true'));
    });

    group('Enums', () {
      test('ModerationActionType should have all expected values', () {
        expect(ModerationActionType.values, hasLength(7));
        expect(ModerationActionType.values, contains(ModerationActionType.hide));
        expect(ModerationActionType.values, contains(ModerationActionType.delete));
        expect(ModerationActionType.values, contains(ModerationActionType.warn));
        expect(ModerationActionType.values, contains(ModerationActionType.suspend));
        expect(ModerationActionType.values, contains(ModerationActionType.ban));
        expect(ModerationActionType.values, contains(ModerationActionType.approve));
        expect(ModerationActionType.values, contains(ModerationActionType.dismiss));
      });

      test('ModerationTargetType should have all expected values', () {
        expect(ModerationTargetType.values, hasLength(4));
        expect(ModerationTargetType.values, contains(ModerationTargetType.post));
        expect(ModerationTargetType.values, contains(ModerationTargetType.comment));
        expect(ModerationTargetType.values, contains(ModerationTargetType.user));
        expect(ModerationTargetType.values, contains(ModerationTargetType.submission));
      });
    });

    group('Expiration scenarios', () {
      test('should handle temporary suspension correctly', () {
        final suspensionAction = ModerationAction(
          id: 'suspend123',
          moderatorId: 'moderator456',
          targetId: 'user789',
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.suspend,
          reason: 'Temporary suspension',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          isActive: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(suspensionAction.isExpired, isFalse);
        expect(suspensionAction.expiresAt, isNotNull);
      });

      test('should handle permanent ban correctly', () {
        final banAction = ModerationAction(
          id: 'ban123',
          moderatorId: 'moderator456',
          targetId: 'user789',
          targetType: ModerationTargetType.user,
          actionType: ModerationActionType.ban,
          reason: 'Permanent ban',
          expiresAt: null, // Permanent
          isActive: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(banAction.isExpired, isFalse);
        expect(banAction.expiresAt, isNull);
      });
    });
  });
}