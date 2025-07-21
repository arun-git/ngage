import 'validation.dart';

/// Content types supported in posts
enum PostContentType {
  text('text'),
  image('image'),
  video('video'),
  mixed('mixed');

  const PostContentType(this.value);
  final String value;

  static PostContentType fromString(String value) {
    return PostContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PostContentType.text,
    );
  }
}

/// Social post model for user-generated content
/// 
/// Posts can contain text, images, videos, or a combination of content types.
/// They are associated with groups and can be liked and commented on by members.
class Post {
  final String id;
  final String groupId;
  final String authorId; // Member ID of the post author
  final String content; // Text content
  final List<String> mediaUrls; // URLs for images/videos
  final PostContentType contentType;
  final int likeCount;
  final int commentCount;
  final bool isActive; // For soft deletion/moderation
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.content,
    this.mediaUrls = const [],
    this.contentType = PostContentType.text,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Post from JSON data
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      content: json['content'] as String,
      mediaUrls: List<String>.from(json['mediaUrls'] as List? ?? []),
      contentType: PostContentType.fromString(json['contentType'] as String? ?? 'text'),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Post to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'authorId': authorId,
      'content': content,
      'mediaUrls': mediaUrls,
      'contentType': contentType.value,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Post with updated fields
  Post copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? content,
    List<String>? mediaUrls,
    PostContentType? contentType,
    int? likeCount,
    int? commentCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      contentType: contentType ?? this.contentType,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if post has media content
  bool get hasMedia => mediaUrls.isNotEmpty;

  /// Check if post has only text content
  bool get isTextOnly => contentType == PostContentType.text && mediaUrls.isEmpty;

  /// Get content preview (first 100 characters)
  String get contentPreview {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  /// Validate Post data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Post ID'),
      Validators.validateId(groupId, 'Group ID'),
      Validators.validateId(authorId, 'Author ID'),
      Validators.validateRequired(content, 'Content'),
      _validateContent(),
      _validateMediaUrls(),
    ];

    return Validators.combine(results);
  }

  ValidationResult _validateContent() {
    if (content.trim().isEmpty) {
      return ValidationResult.singleError('Post content cannot be empty');
    }

    if (content.length > 5000) {
      return ValidationResult.singleError('Post content must not exceed 5000 characters');
    }

    return ValidationResult.valid();
  }

  ValidationResult _validateMediaUrls() {
    if (mediaUrls.length > 10) {
      return ValidationResult.singleError('Posts cannot have more than 10 media files');
    }

    for (final url in mediaUrls) {
      if (url.trim().isEmpty) {
        return ValidationResult.singleError('Media URLs cannot be empty');
      }
    }

    return ValidationResult.valid();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post &&
        other.id == id &&
        other.groupId == groupId &&
        other.authorId == authorId &&
        other.content == content &&
        _listEquals(other.mediaUrls, mediaUrls) &&
        other.contentType == contentType &&
        other.likeCount == likeCount &&
        other.commentCount == commentCount &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      authorId,
      content,
      mediaUrls.toString(),
      contentType,
      likeCount,
      commentCount,
      isActive,
      createdAt,
      updatedAt,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}