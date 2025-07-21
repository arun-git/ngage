import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/models.dart';

void main() {
  group('PostComment Model Tests', () {
    late PostComment testComment;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testComment = PostComment(
        id: 'comment_1',
        postId: 'post_1',
        authorId: 'member_1',
        content: 'This is a test comment',
        parentCommentId: null,
        likeCount: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    test('should create PostComment with all properties', () {
      expect(testComment.id, equals('comment_1'));
      expect(testComment.postId, equals('post_1'));
      expect(testComment.authorId, equals('member_1'));
      expect(testComment.content, equals('This is a test comment'));
      expect(testComment.parentCommentId, isNull);
      expect(testComment.likeCount, equals(2));
      expect(testComment.isActive, equals(true));
      expect(testComment.createdAt, equals(testDate));
      expect(testComment.updatedAt, equals(testDate));
    });

    test('should create PostComment with default values', () {
      final defaultComment = PostComment(
        id: 'comment_2',
        postId: 'post_1',
        authorId: 'member_1',
        content: 'Simple comment',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(defaultComment.parentCommentId, isNull);
      expect(defaultComment.likeCount, equals(0));
      expect(defaultComment.isActive, equals(true));
    });

    test('should serialize to JSON correctly', () {
      final json = testComment.toJson();

      expect(json['id'], equals('comment_1'));
      expect(json['postId'], equals('post_1'));
      expect(json['authorId'], equals('member_1'));
      expect(json['content'], equals('This is a test comment'));
      expect(json['parentCommentId'], isNull);
      expect(json['likeCount'], equals(2));
      expect(json['isActive'], equals(true));
      expect(json['createdAt'], equals(testDate.toIso8601String()));
      expect(json['updatedAt'], equals(testDate.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'comment_1',
        'postId': 'post_1',
        'authorId': 'member_1',
        'content': 'This is a test comment',
        'parentCommentId': null,
        'likeCount': 2,
        'isActive': true,
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      final comment = PostComment.fromJson(json);

      expect(comment.id, equals('comment_1'));
      expect(comment.postId, equals('post_1'));
      expect(comment.authorId, equals('member_1'));
      expect(comment.content, equals('This is a test comment'));
      expect(comment.parentCommentId, isNull);
      expect(comment.likeCount, equals(2));
      expect(comment.isActive, equals(true));
      expect(comment.createdAt, equals(testDate));
      expect(comment.updatedAt, equals(testDate));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'comment_2',
        'postId': 'post_1',
        'authorId': 'member_1',
        'content': 'Simple comment',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      final comment = PostComment.fromJson(json);

      expect(comment.parentCommentId, isNull);
      expect(comment.likeCount, equals(0));
      expect(comment.isActive, equals(true));
    });

    test('should create copy with updated fields', () {
      final updatedComment = testComment.copyWith(
        content: 'Updated comment',
        likeCount: 5,
      );

      expect(updatedComment.id, equals(testComment.id));
      expect(updatedComment.content, equals('Updated comment'));
      expect(updatedComment.likeCount, equals(5));
      expect(updatedComment.postId, equals(testComment.postId));
    });

    test('should detect reply status correctly', () {
      expect(testComment.isReply, isFalse);
      expect(testComment.isTopLevel, isTrue);

      final replyComment = testComment.copyWith(parentCommentId: 'parent_1');
      expect(replyComment.isReply, isTrue);
      expect(replyComment.isTopLevel, isFalse);
    });

    test('should generate content preview correctly', () {
      final longContent = 'A' * 150;
      final longComment = testComment.copyWith(content: longContent);

      expect(longComment.contentPreview.length, equals(103)); // 100 + '...'
      expect(longComment.contentPreview.endsWith('...'), isTrue);

      expect(testComment.contentPreview, equals(testComment.content));
    });

    test('should validate comment data correctly', () {
      // Valid comment
      final validResult = testComment.validate();
      expect(validResult.isValid, isTrue);

      // Invalid comment - empty content
      final emptyContentComment = testComment.copyWith(content: '');
      final emptyResult = emptyContentComment.validate();
      expect(emptyResult.isValid, isFalse);
      expect(emptyResult.errorMessage, contains('cannot be empty'));

      // Invalid comment - content too long
      final longContent = 'A' * 1001;
      final longComment = testComment.copyWith(content: longContent);
      final longResult = longComment.validate();
      expect(longResult.isValid, isFalse);
      expect(longResult.errorMessage, contains('must not exceed 1000 characters'));
    });

    test('should implement equality correctly', () {
      final identicalComment = PostComment(
        id: 'comment_1',
        postId: 'post_1',
        authorId: 'member_1',
        content: 'This is a test comment',
        parentCommentId: null,
        likeCount: 2,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final differentComment = testComment.copyWith(content: 'Different content');

      expect(testComment, equals(identicalComment));
      expect(testComment, isNot(equals(differentComment)));
      expect(testComment.hashCode, equals(identicalComment.hashCode));
    });
  });
}