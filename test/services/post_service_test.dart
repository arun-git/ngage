import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/post_repository.dart';
import 'package:ngage/services/post_service.dart';

import 'post_service_test.mocks.dart';

@GenerateMocks([PostRepository])
void main() {
  group('PostService Tests', () {
    late PostService postService;
    late MockPostRepository mockRepository;
    late DateTime testDate;

    setUp(() {
      mockRepository = MockPostRepository();
      postService = PostService(mockRepository);
      testDate = DateTime.now();
    });

    group('createPost', () {
      test('should create post successfully with text content only', () async {
        final expectedPost = Post(
          id: 'post_1',
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Test post content',
          contentType: PostContentType.text,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockRepository.createPost(any))
            .thenAnswer((_) async => expectedPost);

        final result = await postService.createPost(
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Test post content',
        );

        expect(result.groupId, equals('group_1'));
        expect(result.authorId, equals('member_1'));
        expect(result.content, equals('Test post content'));
        expect(result.contentType, equals(PostContentType.text));
        expect(result.mediaUrls, isEmpty);

        verify(mockRepository.createPost(any)).called(1);
      });

      test('should create post with media files', () async {
        final mediaUrls = ['https://example.com/image1.jpg'];
        final expectedPost = Post(
          id: 'post_1',
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Post with media',
          mediaUrls: mediaUrls,
          contentType: PostContentType.mixed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockRepository.uploadMediaFiles(any))
            .thenAnswer((_) async => mediaUrls);
        when(mockRepository.createPost(any))
            .thenAnswer((_) async => expectedPost);

        final result = await postService.createPost(
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Post with media',
          mediaFiles: [], // Mock files would be here
        );

        expect(result.contentType, equals(PostContentType.mixed));
        expect(result.mediaUrls, equals(mediaUrls));

        verify(mockRepository.uploadMediaFiles(any)).called(1);
        verify(mockRepository.createPost(any)).called(1);
      });

      test('should throw error for invalid post data', () async {
        expect(
          () => postService.createPost(
            groupId: '',
            authorId: 'member_1',
            content: 'Test content',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getGroupPosts', () {
      test('should return group posts successfully', () async {
        final expectedPosts = [
          Post(
            id: 'post_1',
            groupId: 'group_1',
            authorId: 'member_1',
            content: 'Post 1',
            createdAt: testDate,
            updatedAt: testDate,
          ),
          Post(
            id: 'post_2',
            groupId: 'group_1',
            authorId: 'member_2',
            content: 'Post 2',
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        when(mockRepository.getGroupPosts(
          groupId: 'group_1',
          limit: 20,
          lastPostId: null,
        )).thenAnswer((_) async => expectedPosts);

        final result = await postService.getGroupPosts(groupId: 'group_1');

        expect(result, equals(expectedPosts));
        verify(mockRepository.getGroupPosts(
          groupId: 'group_1',
          limit: 20,
          lastPostId: null,
        )).called(1);
      });
    });

    group('getFeedPosts', () {
      test('should return feed posts for multiple groups', () async {
        final groupIds = ['group_1', 'group_2'];
        final expectedPosts = [
          Post(
            id: 'post_1',
            groupId: 'group_1',
            authorId: 'member_1',
            content: 'Post 1',
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        when(mockRepository.getFeedPosts(
          groupIds: groupIds,
          limit: 20,
          lastPostId: null,
        )).thenAnswer((_) async => expectedPosts);

        final result = await postService.getFeedPosts(groupIds: groupIds);

        expect(result, equals(expectedPosts));
        verify(mockRepository.getFeedPosts(
          groupIds: groupIds,
          limit: 20,
          lastPostId: null,
        )).called(1);
      });

      test('should return empty list for empty group IDs', () async {
        final result = await postService.getFeedPosts(groupIds: []);
        expect(result, isEmpty);
        verifyNever(mockRepository.getFeedPosts(
          groupIds: any,
          limit: any,
          lastPostId: any,
        ));
      });
    });

    group('likePost', () {
      test('should like post successfully', () async {
        when(mockRepository.getPostLike('post_1', 'member_1'))
            .thenAnswer((_) async => null);
        when(mockRepository.likePost(any))
            .thenAnswer((_) async => {});

        await postService.likePost(
          postId: 'post_1',
          memberId: 'member_1',
        );

        verify(mockRepository.getPostLike('post_1', 'member_1')).called(1);
        verify(mockRepository.likePost(any)).called(1);
      });

      test('should throw error if post already liked', () async {
        final existingLike = PostLike(
          id: 'like_1',
          postId: 'post_1',
          memberId: 'member_1',
          createdAt: testDate,
        );

        when(mockRepository.getPostLike('post_1', 'member_1'))
            .thenAnswer((_) async => existingLike);

        expect(
          () => postService.likePost(
            postId: 'post_1',
            memberId: 'member_1',
          ),
          throwsA(isA<ArgumentError>()),
        );

        verify(mockRepository.getPostLike('post_1', 'member_1')).called(1);
        verifyNever(mockRepository.likePost(any));
      });
    });

    group('unlikePost', () {
      test('should unlike post successfully', () async {
        final existingLike = PostLike(
          id: 'like_1',
          postId: 'post_1',
          memberId: 'member_1',
          createdAt: testDate,
        );

        when(mockRepository.getPostLike('post_1', 'member_1'))
            .thenAnswer((_) async => existingLike);
        when(mockRepository.unlikePost('post_1', 'member_1'))
            .thenAnswer((_) async => {});

        await postService.unlikePost(
          postId: 'post_1',
          memberId: 'member_1',
        );

        verify(mockRepository.getPostLike('post_1', 'member_1')).called(1);
        verify(mockRepository.unlikePost('post_1', 'member_1')).called(1);
      });

      test('should throw error if post not liked', () async {
        when(mockRepository.getPostLike('post_1', 'member_1'))
            .thenAnswer((_) async => null);

        expect(
          () => postService.unlikePost(
            postId: 'post_1',
            memberId: 'member_1',
          ),
          throwsA(isA<ArgumentError>()),
        );

        verify(mockRepository.getPostLike('post_1', 'member_1')).called(1);
        verifyNever(mockRepository.unlikePost(any, any));
      });
    });

    group('addComment', () {
      test('should add comment successfully', () async {
        final expectedComment = PostComment(
          id: 'comment_1',
          postId: 'post_1',
          authorId: 'member_1',
          content: 'Test comment',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockRepository.addComment(any))
            .thenAnswer((_) async => expectedComment);

        final result = await postService.addComment(
          postId: 'post_1',
          authorId: 'member_1',
          content: 'Test comment',
        );

        expect(result.postId, equals('post_1'));
        expect(result.authorId, equals('member_1'));
        expect(result.content, equals('Test comment'));

        verify(mockRepository.addComment(any)).called(1);
      });

      test('should throw error for invalid comment data', () async {
        expect(
          () => postService.addComment(
            postId: 'post_1',
            authorId: 'member_1',
            content: '',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('updatePost', () {
      test('should update post successfully', () async {
        final existingPost = Post(
          id: 'post_1',
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Original content',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updatedPost = existingPost.copyWith(
          content: 'Updated content',
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getPost('post_1'))
            .thenAnswer((_) async => existingPost);
        when(mockRepository.updatePost(any))
            .thenAnswer((_) async => updatedPost);

        final result = await postService.updatePost(
          postId: 'post_1',
          authorId: 'member_1',
          content: 'Updated content',
        );

        expect(result.content, equals('Updated content'));
        verify(mockRepository.getPost('post_1')).called(1);
        verify(mockRepository.updatePost(any)).called(1);
      });

      test('should throw error if post not found', () async {
        when(mockRepository.getPost('post_1'))
            .thenAnswer((_) async => null);

        expect(
          () => postService.updatePost(
            postId: 'post_1',
            authorId: 'member_1',
            content: 'Updated content',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error if not post author', () async {
        final existingPost = Post(
          id: 'post_1',
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Original content',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockRepository.getPost('post_1'))
            .thenAnswer((_) async => existingPost);

        expect(
          () => postService.updatePost(
            postId: 'post_1',
            authorId: 'member_2', // Different author
            content: 'Updated content',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getPostEngagement', () {
      test('should calculate engagement metrics correctly', () async {
        final post = Post(
          id: 'post_1',
          groupId: 'group_1',
          authorId: 'member_1',
          content: 'Test post',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final likes = [
          PostLike(
            id: 'like_1',
            postId: 'post_1',
            memberId: 'member_1',
            createdAt: testDate,
          ),
          PostLike(
            id: 'like_2',
            postId: 'post_1',
            memberId: 'member_2',
            createdAt: testDate.add(const Duration(minutes: 5)),
          ),
        ];

        final comments = [
          PostComment(
            id: 'comment_1',
            postId: 'post_1',
            authorId: 'member_1',
            content: 'Comment 1',
            createdAt: testDate.add(const Duration(minutes: 10)),
            updatedAt: testDate.add(const Duration(minutes: 10)),
          ),
        ];

        when(mockRepository.getPost('post_1'))
            .thenAnswer((_) async => post);
        when(mockRepository.getPostLikes('post_1', 1000))
            .thenAnswer((_) async => likes);
        when(mockRepository.getPostComments(postId: 'post_1', limit: 1000))
            .thenAnswer((_) async => comments);

        final result = await postService.getPostEngagement('post_1');

        expect(result['postId'], equals('post_1'));
        expect(result['likeCount'], equals(2));
        expect(result['commentCount'], equals(1));
        expect(result['engagementRate'], equals(3.0));
        expect(result['lastActivity'], isNotNull);
      });
    });
  });
}