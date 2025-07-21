import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/models.dart';

void main() {
  group('Post Model Tests', () {
    late Post testPost;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testPost = Post(
        id: 'post_1',
        groupId: 'group_1',
        authorId: 'member_1',
        content: 'This is a test post',
        mediaUrls: ['https://example.com/image1.jpg'],
        contentType: PostContentType.mixed,
        likeCount: 5,
        commentCount: 3,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    test('should create Post with all properties', () {
      expect(testPost.id, equals('post_1'));
      expect(testPost.groupId, equals('group_1'));
      expect(testPost.authorId, equals('member_1'));
      expect(testPost.content, equals('This is a test post'));
      expect(testPost.mediaUrls, equals(['https://example.com/image1.jpg']));
      expect(testPost.contentType, equals(PostContentType.mixed));
      expect(testPost.likeCount, equals(5));
      expect(testPost.commentCount, equals(3));
      expect(testPost.isActive, equals(true));
      expect(testPost.createdAt, equals(testDate));
      expect(testPost.updatedAt, equals(testDate));
    });

    test('should create Post with default values', () {
      final defaultPost = Post(
        id: 'post_2',
        groupId: 'group_1',
        authorId: 'member_1',
        content: 'Simple post',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(defaultPost.mediaUrls, isEmpty);
      expect(defaultPost.contentType, equals(PostContentType.text));
      expect(defaultPost.likeCount, equals(0));
      expect(defaultPost.commentCount, equals(0));
      expect(defaultPost.isActive, equals(true));
    });

    test('should serialize to JSON correctly', () {
      final json = testPost.toJson();

      expect(json['id'], equals('post_1'));
      expect(json['groupId'], equals('group_1'));
      expect(json['authorId'], equals('member_1'));
      expect(json['content'], equals('This is a test post'));
      expect(json['mediaUrls'], equals(['https://example.com/image1.jpg']));
      expect(json['contentType'], equals('mixed'));
      expect(json['likeCount'], equals(5));
      expect(json['commentCount'], equals(3));
      expect(json['isActive'], equals(true));
      expect(json['createdAt'], equals(testDate.toIso8601String()));
      expect(json['updatedAt'], equals(testDate.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'post_1',
        'groupId': 'group_1',
        'authorId': 'member_1',
        'content': 'This is a test post',
        'mediaUrls': ['https://example.com/image1.jpg'],
        'contentType': 'mixed',
        'likeCount': 5,
        'commentCount': 3,
        'isActive': true,
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      final post = Post.fromJson(json);

      expect(post.id, equals('post_1'));
      expect(post.groupId, equals('group_1'));
      expect(post.authorId, equals('member_1'));
      expect(post.content, equals('This is a test post'));
      expect(post.mediaUrls, equals(['https://example.com/image1.jpg']));
      expect(post.contentType, equals(PostContentType.mixed));
      expect(post.likeCount, equals(5));
      expect(post.commentCount, equals(3));
      expect(post.isActive, equals(true));
      expect(post.createdAt, equals(testDate));
      expect(post.updatedAt, equals(testDate));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'post_2',
        'groupId': 'group_1',
        'authorId': 'member_1',
        'content': 'Simple post',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      final post = Post.fromJson(json);

      expect(post.mediaUrls, isEmpty);
      expect(post.contentType, equals(PostContentType.text));
      expect(post.likeCount, equals(0));
      expect(post.commentCount, equals(0));
      expect(post.isActive, equals(true));
    });

    test('should create copy with updated fields', () {
      final updatedPost = testPost.copyWith(
        content: 'Updated content',
        likeCount: 10,
      );

      expect(updatedPost.id, equals(testPost.id));
      expect(updatedPost.content, equals('Updated content'));
      expect(updatedPost.likeCount, equals(10));
      expect(updatedPost.commentCount, equals(testPost.commentCount));
    });

    test('should detect media content correctly', () {
      expect(testPost.hasMedia, isTrue);
      
      final textOnlyPost = testPost.copyWith(mediaUrls: []);
      expect(textOnlyPost.hasMedia, isFalse);
    });

    test('should detect text-only content correctly', () {
      final textOnlyPost = Post(
        id: 'post_3',
        groupId: 'group_1',
        authorId: 'member_1',
        content: 'Text only',
        contentType: PostContentType.text,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(textOnlyPost.isTextOnly, isTrue);
      expect(testPost.isTextOnly, isFalse);
    });

    test('should generate content preview correctly', () {
      final longContent = 'A' * 150;
      final longPost = testPost.copyWith(content: longContent);

      expect(longPost.contentPreview.length, equals(103)); // 100 + '...'
      expect(longPost.contentPreview.endsWith('...'), isTrue);

      expect(testPost.contentPreview, equals(testPost.content));
    });

    test('should validate post data correctly', () {
      // Valid post
      final validResult = testPost.validate();
      expect(validResult.isValid, isTrue);

      // Invalid post - empty content
      final emptyContentPost = testPost.copyWith(content: '');
      final emptyResult = emptyContentPost.validate();
      expect(emptyResult.isValid, isFalse);
      expect(emptyResult.errorMessage, contains('cannot be empty'));

      // Invalid post - content too long
      final longContent = 'A' * 5001;
      final longPost = testPost.copyWith(content: longContent);
      final longResult = longPost.validate();
      expect(longResult.isValid, isFalse);
      expect(longResult.errorMessage, contains('must not exceed 5000 characters'));

      // Invalid post - too many media files
      final tooManyMedia = List.generate(11, (i) => 'url$i');
      final tooManyMediaPost = testPost.copyWith(mediaUrls: tooManyMedia);
      final tooManyResult = tooManyMediaPost.validate();
      expect(tooManyResult.isValid, isFalse);
      expect(tooManyResult.errorMessage, contains('cannot have more than 10 media files'));
    });

    test('should implement equality correctly', () {
      final identicalPost = Post(
        id: 'post_1',
        groupId: 'group_1',
        authorId: 'member_1',
        content: 'This is a test post',
        mediaUrls: ['https://example.com/image1.jpg'],
        contentType: PostContentType.mixed,
        likeCount: 5,
        commentCount: 3,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final differentPost = testPost.copyWith(content: 'Different content');

      expect(testPost, equals(identicalPost));
      expect(testPost, isNot(equals(differentPost)));
      expect(testPost.hashCode, equals(identicalPost.hashCode));
    });
  });

  group('PostContentType Tests', () {
    test('should convert from string correctly', () {
      expect(PostContentType.fromString('text'), equals(PostContentType.text));
      expect(PostContentType.fromString('image'), equals(PostContentType.image));
      expect(PostContentType.fromString('video'), equals(PostContentType.video));
      expect(PostContentType.fromString('mixed'), equals(PostContentType.mixed));
      expect(PostContentType.fromString('invalid'), equals(PostContentType.text));
    });

    test('should have correct string values', () {
      expect(PostContentType.text.value, equals('text'));
      expect(PostContentType.image.value, equals('image'));
      expect(PostContentType.video.value, equals('video'));
      expect(PostContentType.mixed.value, equals('mixed'));
    });
  });
}