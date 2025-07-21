import 'dart:io';
import '../models/models.dart';
import '../repositories/post_repository.dart';

/// Service for managing social posts and engagement
/// 
/// Handles post creation, updates, deletion, and engagement tracking
/// including likes and comments with proper group-based filtering.
class PostService {
  final PostRepository _postRepository;

  PostService(this._postRepository);

  /// Create a new post
  Future<Post> createPost({
    required String groupId,
    required String authorId,
    required String content,
    List<File>? mediaFiles,
  }) async {
    // Upload media files if provided
    List<String> mediaUrls = [];
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      mediaUrls = await _postRepository.uploadMediaFiles(mediaFiles);
    }

    // Determine content type
    PostContentType contentType = PostContentType.text;
    if (mediaUrls.isNotEmpty) {
      contentType = content.trim().isNotEmpty 
          ? PostContentType.mixed 
          : PostContentType.image; // Assuming images for now
    }

    final now = DateTime.now();
    final post = Post(
      id: _generateId(),
      groupId: groupId,
      authorId: authorId,
      content: content,
      mediaUrls: mediaUrls,
      contentType: contentType,
      createdAt: now,
      updatedAt: now,
    );

    // Validate post data
    final validation = post.validate();
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join(', '));
    }

    return await _postRepository.createPost(post);
  }

  /// Get posts for a specific group with pagination
  Future<List<Post>> getGroupPosts({
    required String groupId,
    int limit = 20,
    String? lastPostId,
  }) async {
    return await _postRepository.getGroupPosts(
      groupId: groupId,
      limit: limit,
      lastPostId: lastPostId,
    );
  }

  /// Get posts for multiple groups (for user's feed)
  Future<List<Post>> getFeedPosts({
    required List<String> groupIds,
    int limit = 20,
    String? lastPostId,
  }) async {
    if (groupIds.isEmpty) {
      return [];
    }

    return await _postRepository.getFeedPosts(
      groupIds: groupIds,
      limit: limit,
      lastPostId: lastPostId,
    );
  }

  /// Get a specific post by ID
  Future<Post?> getPost(String postId) async {
    return await _postRepository.getPost(postId);
  }

  /// Update a post (only content can be updated)
  Future<Post> updatePost({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    final existingPost = await _postRepository.getPost(postId);
    if (existingPost == null) {
      throw ArgumentError('Post not found');
    }

    // Verify the author can update this post
    if (existingPost.authorId != authorId) {
      throw ArgumentError('Only the post author can update the post');
    }

    final updatedPost = existingPost.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    // Validate updated post data
    final validation = updatedPost.validate();
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join(', '));
    }

    return await _postRepository.updatePost(updatedPost);
  }

  /// Delete a post (soft delete)
  Future<void> deletePost({
    required String postId,
    required String authorId,
  }) async {
    final existingPost = await _postRepository.getPost(postId);
    if (existingPost == null) {
      throw ArgumentError('Post not found');
    }

    // Verify the author can delete this post
    if (existingPost.authorId != authorId) {
      throw ArgumentError('Only the post author can delete the post');
    }

    await _postRepository.deletePost(postId);
  }

  /// Like a post
  Future<void> likePost({
    required String postId,
    required String memberId,
  }) async {
    // Check if already liked
    final existingLike = await _postRepository.getPostLike(postId, memberId);
    if (existingLike != null) {
      throw ArgumentError('Post already liked by this member');
    }

    final like = PostLike(
      id: _generateId(),
      postId: postId,
      memberId: memberId,
      createdAt: DateTime.now(),
    );

    // Validate like data
    final validation = like.validate();
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join(', '));
    }

    await _postRepository.likePost(like);
  }

  /// Unlike a post
  Future<void> unlikePost({
    required String postId,
    required String memberId,
  }) async {
    final existingLike = await _postRepository.getPostLike(postId, memberId);
    if (existingLike == null) {
      throw ArgumentError('Post not liked by this member');
    }

    await _postRepository.unlikePost(postId, memberId);
  }

  /// Check if a post is liked by a member
  Future<bool> isPostLiked({
    required String postId,
    required String memberId,
  }) async {
    final like = await _postRepository.getPostLike(postId, memberId);
    return like != null;
  }

  /// Get post likes
  Future<List<PostLike>> getPostLikes({
    required String postId,
    int limit = 50,
  }) async {
    return await _postRepository.getPostLikes(postId, limit);
  }

  /// Add a comment to a post
  Future<PostComment> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    final comment = PostComment(
      id: _generateId(),
      postId: postId,
      authorId: authorId,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validate comment data
    final validation = comment.validate();
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join(', '));
    }

    return await _postRepository.addComment(comment);
  }

  /// Get comments for a post
  Future<List<PostComment>> getPostComments({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  }) async {
    return await _postRepository.getPostComments(
      postId: postId,
      limit: limit,
      lastCommentId: lastCommentId,
    );
  }

  /// Update a comment
  Future<PostComment> updateComment({
    required String commentId,
    required String authorId,
    required String content,
  }) async {
    final existingComment = await _postRepository.getComment(commentId);
    if (existingComment == null) {
      throw ArgumentError('Comment not found');
    }

    // Verify the author can update this comment
    if (existingComment.authorId != authorId) {
      throw ArgumentError('Only the comment author can update the comment');
    }

    final updatedComment = existingComment.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    // Validate updated comment data
    final validation = updatedComment.validate();
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join(', '));
    }

    return await _postRepository.updateComment(updatedComment);
  }

  /// Delete a comment (soft delete)
  Future<void> deleteComment({
    required String commentId,
    required String authorId,
  }) async {
    final existingComment = await _postRepository.getComment(commentId);
    if (existingComment == null) {
      throw ArgumentError('Comment not found');
    }

    // Verify the author can delete this comment
    if (existingComment.authorId != authorId) {
      throw ArgumentError('Only the comment author can delete the comment');
    }

    await _postRepository.deleteComment(commentId);
  }

  /// Like a comment
  Future<void> likeComment({
    required String commentId,
    required String memberId,
  }) async {
    // Check if already liked
    final existingLike = await _postRepository.getCommentLike(commentId, memberId);
    if (existingLike != null) {
      throw ArgumentError('Comment already liked by this member');
    }

    final like = CommentLike(
      id: _generateId(),
      commentId: commentId,
      memberId: memberId,
      createdAt: DateTime.now(),
    );

    // Validate like data
    final validation = like.validate();
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join(', '));
    }

    await _postRepository.likeComment(like);
  }

  /// Unlike a comment
  Future<void> unlikeComment({
    required String commentId,
    required String memberId,
  }) async {
    final existingLike = await _postRepository.getCommentLike(commentId, memberId);
    if (existingLike == null) {
      throw ArgumentError('Comment not liked by this member');
    }

    await _postRepository.unlikeComment(commentId, memberId);
  }

  /// Check if a comment is liked by a member
  Future<bool> isCommentLiked({
    required String commentId,
    required String memberId,
  }) async {
    final like = await _postRepository.getCommentLike(commentId, memberId);
    return like != null;
  }

  /// Get engagement metrics for a post
  Future<Map<String, dynamic>> getPostEngagement(String postId) async {
    final post = await _postRepository.getPost(postId);
    if (post == null) {
      throw ArgumentError('Post not found');
    }

    final likes = await _postRepository.getPostLikes(postId, 1000);
    final comments = await _postRepository.getPostComments(postId: postId, limit: 1000);

    return {
      'postId': postId,
      'likeCount': likes.length,
      'commentCount': comments.length,
      'engagementRate': _calculateEngagementRate(likes.length, comments.length),
      'lastActivity': _getLastActivityTime(likes, comments),
    };
  }

  /// Search posts by content
  Future<List<Post>> searchPosts({
    required String query,
    required List<String> groupIds,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty || groupIds.isEmpty) {
      return [];
    }

    return await _postRepository.searchPosts(
      query: query.trim(),
      groupIds: groupIds,
      limit: limit,
    );
  }

  /// Get posts by a specific author
  Future<List<Post>> getAuthorPosts({
    required String authorId,
    required List<String> groupIds,
    int limit = 20,
    String? lastPostId,
  }) async {
    return await _postRepository.getAuthorPosts(
      authorId: authorId,
      groupIds: groupIds,
      limit: limit,
      lastPostId: lastPostId,
    );
  }

  /// Calculate engagement rate based on likes and comments
  double _calculateEngagementRate(int likes, int comments) {
    final totalEngagement = likes + comments;
    if (totalEngagement == 0) return 0.0;
    
    // Simple engagement rate calculation
    // In a real app, this might consider views, shares, etc.
    return (totalEngagement * 1.0);
  }

  /// Get the most recent activity time from likes and comments
  DateTime? _getLastActivityTime(List<PostLike> likes, List<PostComment> comments) {
    DateTime? lastActivity;

    if (likes.isNotEmpty) {
      final lastLike = likes.reduce((a, b) => 
          a.createdAt.isAfter(b.createdAt) ? a : b);
      lastActivity = lastLike.createdAt;
    }

    if (comments.isNotEmpty) {
      final lastComment = comments.reduce((a, b) => 
          a.createdAt.isAfter(b.createdAt) ? a : b);
      if (lastActivity == null || lastComment.createdAt.isAfter(lastActivity)) {
        lastActivity = lastComment.createdAt;
      }
    }

    return lastActivity;
  }

  /// Generate a unique ID for posts, comments, and likes
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}