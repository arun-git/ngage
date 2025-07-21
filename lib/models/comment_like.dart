import 'validation.dart';

/// Like model for comment engagement tracking
/// 
/// Represents a like on a post comment by a member.
/// Used for engagement metrics on comments.
class CommentLike {
  final String id;
  final String commentId;
  final String memberId; // Member who liked the comment
  final DateTime createdAt;

  const CommentLike({
    required this.id,
    required this.commentId,
    required this.memberId,
    required this.createdAt,
  });

  /// Create CommentLike from JSON data
  factory CommentLike.fromJson(Map<String, dynamic> json) {
    return CommentLike(
      id: json['id'] as String,
      commentId: json['commentId'] as String,
      memberId: json['memberId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert CommentLike to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentId': commentId,
      'memberId': memberId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of CommentLike with updated fields
  CommentLike copyWith({
    String? id,
    String? commentId,
    String? memberId,
    DateTime? createdAt,
  }) {
    return CommentLike(
      id: id ?? this.id,
      commentId: commentId ?? this.commentId,
      memberId: memberId ?? this.memberId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validate CommentLike data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Like ID'),
      Validators.validateId(commentId, 'Comment ID'),
      Validators.validateId(memberId, 'Member ID'),
    ];

    return Validators.combine(results);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentLike &&
        other.id == id &&
        other.commentId == commentId &&
        other.memberId == memberId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      commentId,
      memberId,
      createdAt,
    );
  }
}