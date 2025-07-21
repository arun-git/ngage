import 'validation.dart';

/// Post like model for tracking user engagement
/// 
/// Represents a like on a post by a member. Used for engagement tracking
/// and displaying like counts on posts.
class PostLike {
  final String id;
  final String postId;
  final String memberId; // Member who liked the post
  final DateTime createdAt;

  const PostLike({
    required this.id,
    required this.postId,
    required this.memberId,
    required this.createdAt,
  });

  /// Create PostLike from JSON data
  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: json['id'] as String,
      postId: json['postId'] as String,
      memberId: json['memberId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert PostLike to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'memberId': memberId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of PostLike with updated fields
  PostLike copyWith({
    String? id,
    String? postId,
    String? memberId,
    DateTime? createdAt,
  }) {
    return PostLike(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      memberId: memberId ?? this.memberId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validate PostLike data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Like ID'),
      Validators.validateId(postId, 'Post ID'),
      Validators.validateId(memberId, 'Member ID'),
    ];

    return Validators.combine(results);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostLike &&
        other.id == id &&
        other.postId == postId &&
        other.memberId == memberId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, postId, memberId, createdAt);
  }
}