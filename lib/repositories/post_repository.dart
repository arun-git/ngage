import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';

/// Repository for post data access and Firebase operations
/// 
/// Handles all Firebase Firestore operations for posts, comments, and likes
/// including real-time updates and file storage operations.
class PostRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // Collection references
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _postLikesCollection => _firestore.collection('post_likes');
  CollectionReference get _postCommentsCollection => _firestore.collection('post_comments');
  CollectionReference get _commentLikesCollection => _firestore.collection('comment_likes');

  /// Create a new post
  Future<Post> createPost(Post post) async {
    await _postsCollection.doc(post.id).set(post.toJson());
    return post;
  }

  /// Get posts for a specific group with pagination
  Future<List<Post>> getGroupPosts({
    required String groupId,
    int limit = 20,
    String? lastPostId,
  }) async {
    Query query = _postsCollection
        .where('groupId', isEqualTo: groupId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastPostId != null) {
      final lastDoc = await _postsCollection.doc(lastPostId).get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList();
  }

  /// Get posts for multiple groups (for user's feed)
  Future<List<Post>> getFeedPosts({
    required List<String> groupIds,
    int limit = 20,
    String? lastPostId,
  }) async {
    if (groupIds.isEmpty) return [];

    // Firestore 'in' queries are limited to 10 items, so we need to batch
    final List<Post> allPosts = [];
    
    for (int i = 0; i < groupIds.length; i += 10) {
      final batch = groupIds.skip(i).take(10).toList();
      
      Query query = _postsCollection
          .where('groupId', whereIn: batch)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null && i == 0) {
        final lastDoc = await _postsCollection.doc(lastPostId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
      
      allPosts.addAll(posts);
    }

    // Sort all posts by creation date and limit
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPosts.take(limit).toList();
  }

  /// Get a specific post by ID
  Future<Post?> getPost(String postId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) return null;
    
    return Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  /// Update a post
  Future<Post> updatePost(Post post) async {
    await _postsCollection.doc(post.id).update(post.toJson());
    return post;
  }

  /// Delete a post (soft delete)
  Future<void> deletePost(String postId) async {
    await _postsCollection.doc(postId).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Upload media files to Firebase Storage
  Future<List<String>> uploadMediaFiles(List<File> files) async {
    final List<String> urls = [];
    
    for (final file in files) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('posts/media/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    
    return urls;
  }

  /// Like a post
  Future<void> likePost(PostLike like) async {
    final batch = _firestore.batch();
    
    // Add the like
    batch.set(_postLikesCollection.doc(like.id), like.toJson());
    
    // Increment like count on post
    batch.update(_postsCollection.doc(like.postId), {
      'likeCount': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String memberId) async {
    final likeQuery = await _postLikesCollection
        .where('postId', isEqualTo: postId)
        .where('memberId', isEqualTo: memberId)
        .get();
    
    if (likeQuery.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    
    // Remove the like
    batch.delete(likeQuery.docs.first.reference);
    
    // Decrement like count on post
    batch.update(_postsCollection.doc(postId), {
      'likeCount': FieldValue.increment(-1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
  }

  /// Get a specific post like
  Future<PostLike?> getPostLike(String postId, String memberId) async {
    final query = await _postLikesCollection
        .where('postId', isEqualTo: postId)
        .where('memberId', isEqualTo: memberId)
        .get();
    
    if (query.docs.isEmpty) return null;
    
    final doc = query.docs.first;
    return PostLike.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  /// Get post likes
  Future<List<PostLike>> getPostLikes(String postId, int limit) async {
    final query = await _postLikesCollection
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    
    return query.docs
        .map((doc) => PostLike.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList();
  }

  /// Add a comment to a post
  Future<PostComment> addComment(PostComment comment) async {
    final batch = _firestore.batch();
    
    // Add the comment
    batch.set(_postCommentsCollection.doc(comment.id), comment.toJson());
    
    // Increment comment count on post
    batch.update(_postsCollection.doc(comment.postId), {
      'commentCount': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
    return comment;
  }

  /// Get comments for a post
  Future<List<PostComment>> getPostComments({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  }) async {
    Query query = _postCommentsCollection
        .where('postId', isEqualTo: postId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .limit(limit);

    if (lastCommentId != null) {
      final lastDoc = await _postCommentsCollection.doc(lastCommentId).get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PostComment.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList();
  }

  /// Get a specific comment by ID
  Future<PostComment?> getComment(String commentId) async {
    final doc = await _postCommentsCollection.doc(commentId).get();
    if (!doc.exists) return null;
    
    return PostComment.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  /// Update a comment
  Future<PostComment> updateComment(PostComment comment) async {
    await _postCommentsCollection.doc(comment.id).update(comment.toJson());
    return comment;
  }

  /// Delete a comment (soft delete)
  Future<void> deleteComment(String commentId) async {
    final batch = _firestore.batch();
    
    // Get the comment to find the post ID
    final commentDoc = await _postCommentsCollection.doc(commentId).get();
    if (!commentDoc.exists) return;
    
    final comment = PostComment.fromJson({...commentDoc.data() as Map<String, dynamic>, 'id': commentId});
    
    // Soft delete the comment
    batch.update(_postCommentsCollection.doc(commentId), {
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    // Decrement comment count on post
    batch.update(_postsCollection.doc(comment.postId), {
      'commentCount': FieldValue.increment(-1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
  }

  /// Like a comment
  Future<void> likeComment(CommentLike like) async {
    final batch = _firestore.batch();
    
    // Add the like
    batch.set(_commentLikesCollection.doc(like.id), like.toJson());
    
    // Increment like count on comment
    batch.update(_postCommentsCollection.doc(like.commentId), {
      'likeCount': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
  }

  /// Unlike a comment
  Future<void> unlikeComment(String commentId, String memberId) async {
    final likeQuery = await _commentLikesCollection
        .where('commentId', isEqualTo: commentId)
        .where('memberId', isEqualTo: memberId)
        .get();
    
    if (likeQuery.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    
    // Remove the like
    batch.delete(likeQuery.docs.first.reference);
    
    // Decrement like count on comment
    batch.update(_postCommentsCollection.doc(commentId), {
      'likeCount': FieldValue.increment(-1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
  }

  /// Get a specific comment like
  Future<CommentLike?> getCommentLike(String commentId, String memberId) async {
    final query = await _commentLikesCollection
        .where('commentId', isEqualTo: commentId)
        .where('memberId', isEqualTo: memberId)
        .get();
    
    if (query.docs.isEmpty) return null;
    
    final doc = query.docs.first;
    return CommentLike.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  /// Search posts by content
  Future<List<Post>> searchPosts({
    required String query,
    required List<String> groupIds,
    int limit = 20,
  }) async {
    // Note: Firestore doesn't support full-text search natively
    // This is a simple implementation that searches for exact matches
    // In production, you might want to use Algolia or similar service
    
    final List<Post> allPosts = [];
    
    for (int i = 0; i < groupIds.length; i += 10) {
      final batch = groupIds.skip(i).take(10).toList();
      
      final snapshot = await _postsCollection
          .where('groupId', whereIn: batch)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();
      
      final posts = snapshot.docs
          .map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .where((post) => post.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      allPosts.addAll(posts);
    }
    
    // Sort and limit results
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPosts.take(limit).toList();
  }

  /// Get posts by a specific author
  Future<List<Post>> getAuthorPosts({
    required String authorId,
    required List<String> groupIds,
    int limit = 20,
    String? lastPostId,
  }) async {
    final List<Post> allPosts = [];
    
    for (int i = 0; i < groupIds.length; i += 10) {
      final batch = groupIds.skip(i).take(10).toList();
      
      Query query = _postsCollection
          .where('authorId', isEqualTo: authorId)
          .where('groupId', whereIn: batch)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null && i == 0) {
        final lastDoc = await _postsCollection.doc(lastPostId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
      
      allPosts.addAll(posts);
    }
    
    // Sort and limit results
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPosts.take(limit).toList();
  }

  /// Get real-time stream of posts for a group
  Stream<List<Post>> getGroupPostsStream({
    required String groupId,
    int limit = 20,
  }) {
    return _postsCollection
        .where('groupId', isEqualTo: groupId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  /// Get real-time stream of comments for a post
  Stream<List<PostComment>> getPostCommentsStream({
    required String postId,
    int limit = 50,
  }) {
    return _postCommentsCollection
        .where('postId', isEqualTo: postId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }
}