import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/models.dart';

void main() {
  group('PostLike Model Tests', () {
    late PostLike testLike;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testLike = PostLike(
        id: 'like_1',
        postId: 'post_1',
        memberId: 'member_1',
        createdAt: testDate,
      );
    });

    test('should create PostLike with all properties', () {
      expect(testLike.id, equals('like_1'));
      expect(testLike.postId, equals('post_1'));
      expect(testLike.memberId, equals('member_1'));
      expect(testLike.createdAt, equals(testDate));
    });

    test('should serialize to JSON correctly', () {
      final json = testLike.toJson();

      expect(json['id'], equals('like_1'));
      expect(json['postId'], equals('post_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['createdAt'], equals(testDate.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'like_1',
        'postId': 'post_1',
        'memberId': 'member_1',
        'createdAt': testDate.toIso8601String(),
      };

      final like = PostLike.fromJson(json);

      expect(like.id, equals('like_1'));
      expect(like.postId, equals('post_1'));
      expect(like.memberId, equals('member_1'));
      expect(like.createdAt, equals(testDate));
    });

    test('should create copy with updated fields', () {
      final updatedLike = testLike.copyWith(
        memberId: 'member_2',
      );

      expect(updatedLike.id, equals(testLike.id));
      expect(updatedLike.postId, equals(testLike.postId));
      expect(updatedLike.memberId, equals('member_2'));
      expect(updatedLike.createdAt, equals(testLike.createdAt));
    });

    test('should validate like data correctly', () {
      // Valid like
      final validResult = testLike.validate();
      expect(validResult.isValid, isTrue);

      // Invalid like - empty ID
      final invalidLike = PostLike(
        id: '',
        postId: 'post_1',
        memberId: 'member_1',
        createdAt: testDate,
      );
      final invalidResult = invalidLike.validate();
      expect(invalidResult.isValid, isFalse);
    });

    test('should implement equality correctly', () {
      final identicalLike = PostLike(
        id: 'like_1',
        postId: 'post_1',
        memberId: 'member_1',
        createdAt: testDate,
      );

      final differentLike = testLike.copyWith(memberId: 'member_2');

      expect(testLike, equals(identicalLike));
      expect(testLike, isNot(equals(differentLike)));
      expect(testLike.hashCode, equals(identicalLike.hashCode));
    });
  });
}