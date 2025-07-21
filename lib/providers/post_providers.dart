import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/post_repository.dart';
import '../services/post_service.dart';

/// Provider for PostRepository
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

/// Provider for PostService
final postServiceProvider = Provider<PostService>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return PostService(repository);
});

/// Provider for group posts with pagination
final groupPostsProvider = FutureProvider.family<List<Post>, GroupPostsParams>((ref, params) async {
  final service = ref.watch(postServiceProvider);
  return service.getGroupPosts(
    groupId: params.groupId,
    limit: params.limit,
    lastPostId: params.lastPostId,
  );
});

/// Provider for user's social feed
final socialFeedProvider = FutureProvider.family<List<Post>, SocialFeedParams>((ref, params) async {
  final service = ref.watch(postServiceProvider);
  return service.getFeedPosts(
    groupIds: params.groupIds,
    limit: params.limit,
    lastPostId: params.lastPostId,
  );
});

/// Provider for a specific post
final postProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  final service = ref.watch(postServiceProvider);
  return service.getPost(postId);
});

/// Provider for post comments
final postCommentsProvider = FutureProvider.family<List<PostComment>, PostCommentsParams>((ref, params) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPostComments(
    postId: params.postId,
    limit: params.limit,
    lastCommentId: params.lastCommentId,
  );
});

/// Provider for post likes
final postLikesProvider = FutureProvider.family<List<PostLike>, PostLikesParams>((ref, params) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPostLikes(params.postId, params.limit);
});

/// Provider for checking if a post is liked by current user
final isPostLikedProvider = FutureProvider.family<bool, PostLikeCheckParams>((ref, params) async {
  final service = ref.watch(postServiceProvider);
  return service.isPostLiked(
    postId: params.postId,
    memberId: params.memberId,
  );
});

/// Provider for checking if a comment is liked by current user
final isCommentLikedProvider = FutureProvider.family<bool, CommentLikeCheckParams>((ref, params) async {
  final service = ref.watch(postServiceProvider);
  return service.isCommentLiked(
    commentId: params.commentId,
    memberId: params.memberId,
  );
});

/// Provider for post engagement metrics
final postEngagementProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, postId) async {
  final service = ref.watch(postServiceProvider);
  return service.getPostEngagement(postId);
});

/// Provider for searching posts
final searchPostsProvider = FutureProvider.family<List<Post>, SearchPostsParams>((ref, params) async {
  final service = ref.watch(postServiceProvider);
  return service.searchPosts(
    query: params.query,
    groupIds: params.groupIds,
    limit: params.limit,
  );
});

/// Provider for author posts
final authorPostsProvider = FutureProvider.family<List<Post>, AuthorPostsParams>((ref, params) async {
  final service = ref.watch(postServiceProvider);
  return service.getAuthorPosts(
    authorId: params.authorId,
    groupIds: params.groupIds,
    limit: params.limit,
    lastPostId: params.lastPostId,
  );
});

/// Stream provider for real-time group posts
final groupPostsStreamProvider = StreamProvider.family<List<Post>, GroupPostsStreamParams>((ref, params) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getGroupPostsStream(
    groupId: params.groupId,
    limit: params.limit,
  );
});

/// Stream provider for real-time post comments
final postCommentsStreamProvider = StreamProvider.family<List<PostComment>, PostCommentsStreamParams>((ref, params) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPostCommentsStream(
    postId: params.postId,
    limit: params.limit,
  );
});

// Parameter classes for providers

class GroupPostsParams {
  final String groupId;
  final int limit;
  final String? lastPostId;

  const GroupPostsParams({
    required this.groupId,
    this.limit = 20,
    this.lastPostId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPostsParams &&
        other.groupId == groupId &&
        other.limit == limit &&
        other.lastPostId == lastPostId;
  }

  @override
  int get hashCode => Object.hash(groupId, limit, lastPostId);
}

class SocialFeedParams {
  final List<String> groupIds;
  final int limit;
  final String? lastPostId;

  const SocialFeedParams({
    required this.groupIds,
    this.limit = 20,
    this.lastPostId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialFeedParams &&
        _listEquals(other.groupIds, groupIds) &&
        other.limit == limit &&
        other.lastPostId == lastPostId;
  }

  @override
  int get hashCode => Object.hash(groupIds.toString(), limit, lastPostId);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class PostCommentsParams {
  final String postId;
  final int limit;
  final String? lastCommentId;

  const PostCommentsParams({
    required this.postId,
    this.limit = 50,
    this.lastCommentId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostCommentsParams &&
        other.postId == postId &&
        other.limit == limit &&
        other.lastCommentId == lastCommentId;
  }

  @override
  int get hashCode => Object.hash(postId, limit, lastCommentId);
}

class PostLikesParams {
  final String postId;
  final int limit;

  const PostLikesParams({
    required this.postId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostLikesParams &&
        other.postId == postId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(postId, limit);
}

class PostLikeCheckParams {
  final String postId;
  final String memberId;

  const PostLikeCheckParams({
    required this.postId,
    required this.memberId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostLikeCheckParams &&
        other.postId == postId &&
        other.memberId == memberId;
  }

  @override
  int get hashCode => Object.hash(postId, memberId);
}

class CommentLikeCheckParams {
  final String commentId;
  final String memberId;

  const CommentLikeCheckParams({
    required this.commentId,
    required this.memberId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentLikeCheckParams &&
        other.commentId == commentId &&
        other.memberId == memberId;
  }

  @override
  int get hashCode => Object.hash(commentId, memberId);
}

class SearchPostsParams {
  final String query;
  final List<String> groupIds;
  final int limit;

  const SearchPostsParams({
    required this.query,
    required this.groupIds,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchPostsParams &&
        other.query == query &&
        _listEquals(other.groupIds, groupIds) &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(query, groupIds.toString(), limit);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class AuthorPostsParams {
  final String authorId;
  final List<String> groupIds;
  final int limit;
  final String? lastPostId;

  const AuthorPostsParams({
    required this.authorId,
    required this.groupIds,
    this.limit = 20,
    this.lastPostId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorPostsParams &&
        other.authorId == authorId &&
        _listEquals(other.groupIds, groupIds) &&
        other.limit == limit &&
        other.lastPostId == lastPostId;
  }

  @override
  int get hashCode => Object.hash(authorId, groupIds.toString(), limit, lastPostId);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class GroupPostsStreamParams {
  final String groupId;
  final int limit;

  const GroupPostsStreamParams({
    required this.groupId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPostsStreamParams &&
        other.groupId == groupId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(groupId, limit);
}

class PostCommentsStreamParams {
  final String postId;
  final int limit;

  const PostCommentsStreamParams({
    required this.postId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostCommentsStreamParams &&
        other.postId == postId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(postId, limit);
}