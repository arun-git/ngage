import 'validation.dart';

/// Comment model for post engagement
/// 
/// Represents a comment on a social post by a member.
/// Supports threaded discussions with parent-child relationships.
class PostComment {
  final String id;
  final String postId;
  final String authorId; // Member ID of the comment author
  final String content;
  final String? parentCommentId; // For threaded discussions
  final int likeCount; // Comments can also be liked
  final bool isActive; // For soft deletion/moderation
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentCommentId,
    this.likeCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create PostComment from JSON data
  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      content: json['content'] as String,
      parentCommentId: json['parentCommentId'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert PostComment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'parentCommentId': parentCommentId,
      'likeCount': likeCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of PostComment with updated fields
  PostComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? content,
    String? parentCommentId,
    int? likeCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likeCount: likeCount ?? this.likeCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;

  /// Check if this is a top-level comment
  bool get isTopLevel => parentCommentId == null;

  /// Get content preview (first 100 characters)
  String get contentPreview {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  /// Validate PostComment data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Comment ID'),
      Validators.validateId(postId, 'Post ID'),
      Validators.validateId(authorId, 'Author ID'),
      Validators.validateRequired(content, 'Content'),
      _validateContent(),
    ];

    return Validators.combine(results);
  }

  ValidationResult _validateContent() {
    if (content.trim().isEmpty) {
      return ValidationResult.singleError('Comment content cannot be empty');
    }

    if (content.length > 1000) {
      return ValidationResult.singleError('Comment content must not exceed 1000 characters');
    }

    return ValidationResult.valid();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostComment &&
        other.id == id &&
        other.postId == postId &&
        other.authorId == authorId &&
        other.content == content &&
        other.parentCommentId == parentCommentId &&
        other.likeCount == likeCount &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      postId,
      authorId,
      content,
      parentCommentId,
      likeCount,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}