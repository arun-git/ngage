import 'enums.dart';
import 'validation.dart';

/// Submission model
/// 
/// Represents a submission for an event by a team. Submissions can contain
/// various types of content (photos, videos, text) and have a status lifecycle.
class Submission {
  final String id;
  final String eventId;
  final String teamId;
  final String submittedBy; // Member ID
  final Map<String, dynamic> content; // Photos, videos, text
  final SubmissionStatus status;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Submission({
    required this.id,
    required this.eventId,
    required this.teamId,
    required this.submittedBy,
    this.content = const {},
    this.status = SubmissionStatus.draft,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Submission from JSON data
  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      teamId: json['teamId'] as String,
      submittedBy: json['submittedBy'] as String,
      content: Map<String, dynamic>.from(json['content'] as Map? ?? {}),
      status: SubmissionStatus.fromString(json['status'] as String),
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Submission to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'teamId': teamId,
      'submittedBy': submittedBy,
      'content': content,
      'status': status.value,
      'submittedAt': submittedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Submission with updated fields
  Submission copyWith({
    String? id,
    String? eventId,
    String? teamId,
    String? submittedBy,
    Map<String, dynamic>? content,
    SubmissionStatus? status,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Submission(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      teamId: teamId ?? this.teamId,
      submittedBy: submittedBy ?? this.submittedBy,
      content: content ?? this.content,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if submission is in draft status
  bool get isDraft => status == SubmissionStatus.draft;

  /// Check if submission has been submitted
  bool get isSubmitted => status != SubmissionStatus.draft;

  /// Check if submission is under review
  bool get isUnderReview => status == SubmissionStatus.underReview;

  /// Check if submission is approved
  bool get isApproved => status == SubmissionStatus.approved;

  /// Check if submission is rejected
  bool get isRejected => status == SubmissionStatus.rejected;

  /// Check if submission can be edited
  bool get canBeEdited => isDraft;

  /// Get content value by key
  T? getContent<T>(String key, [T? defaultValue]) {
    final value = content[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Get text content
  String? get textContent => getContent<String>('text');

  /// Get photo URLs
  List<String> get photoUrls {
    final photos = getContent<List>('photos', []);
    return photos?.cast<String>() ?? [];
  }

  /// Get video URLs
  List<String> get videoUrls {
    final videos = getContent<List>('videos', []);
    return videos?.cast<String>() ?? [];
  }

  /// Get document URLs
  List<String> get documentUrls {
    final documents = getContent<List>('documents', []);
    return documents?.cast<String>() ?? [];
  }

  /// Get all file URLs
  List<String> get allFileUrls {
    return [...photoUrls, ...videoUrls, ...documentUrls];
  }

  /// Check if submission has any content
  bool get hasContent {
    return textContent?.isNotEmpty == true || allFileUrls.isNotEmpty;
  }

  /// Update content field
  Submission updateContent(String key, dynamic value) {
    final newContent = Map<String, dynamic>.from(content);
    newContent[key] = value;
    return copyWith(content: newContent);
  }

  /// Remove content field
  Submission removeContent(String key) {
    final newContent = Map<String, dynamic>.from(content);
    newContent.remove(key);
    return copyWith(content: newContent);
  }

  /// Add text content
  Submission addTextContent(String text) {
    return updateContent('text', text);
  }

  /// Add photo URL
  Submission addPhoto(String photoUrl) {
    final currentPhotos = photoUrls;
    final newPhotos = [...currentPhotos, photoUrl];
    return updateContent('photos', newPhotos);
  }

  /// Add video URL
  Submission addVideo(String videoUrl) {
    final currentVideos = videoUrls;
    final newVideos = [...currentVideos, videoUrl];
    return updateContent('videos', newVideos);
  }

  /// Add document URL
  Submission addDocument(String documentUrl) {
    final currentDocuments = documentUrls;
    final newDocuments = [...currentDocuments, documentUrl];
    return updateContent('documents', newDocuments);
  }

  /// Submit the submission (change status to submitted)
  Submission submit() {
    if (!canBeEdited) {
      throw StateError('Cannot submit a submission that is not in draft status');
    }
    
    if (!hasContent) {
      throw StateError('Cannot submit empty submission');
    }
    
    return copyWith(
      status: SubmissionStatus.submitted,
      submittedAt: DateTime.now(),
    );
  }

  /// Validate Submission data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Submission ID'),
      Validators.validateId(eventId, 'Event ID'),
      Validators.validateId(teamId, 'Team ID'),
      Validators.validateId(submittedBy, 'Submitted by member ID'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    // If submitted, must have submittedAt timestamp
    if (isSubmitted && submittedAt == null) {
      additionalErrors.add('Submitted submissions must have a submission timestamp');
    }
    
    // If draft, should not have submittedAt timestamp
    if (isDraft && submittedAt != null) {
      additionalErrors.add('Draft submissions should not have a submission timestamp');
    }
    
    // submittedAt should be after createdAt
    if (submittedAt != null && submittedAt!.isBefore(createdAt)) {
      additionalErrors.add('Submission timestamp must be after creation timestamp');
    }
    
    // Validate content structure
    if (content.isNotEmpty) {
      // Validate text content length
      final text = textContent;
      if (text != null && text.length > 5000) {
        additionalErrors.add('Text content must not exceed 5000 characters');
      }
      
      // Validate file URL lists
      for (final fileList in [photoUrls, videoUrls, documentUrls]) {
        for (final url in fileList) {
          if (url.isEmpty) {
            additionalErrors.add('File URLs cannot be empty');
            break;
          }
        }
      }
      
      // Check for reasonable file limits
      if (photoUrls.length > 20) {
        additionalErrors.add('Cannot have more than 20 photos');
      }
      
      if (videoUrls.length > 5) {
        additionalErrors.add('Cannot have more than 5 videos');
      }
      
      if (documentUrls.length > 10) {
        additionalErrors.add('Cannot have more than 10 documents');
      }
    }

    final baseValidation = Validators.combine(results);
    
    if (additionalErrors.isNotEmpty) {
      final allErrors = [...baseValidation.errors, ...additionalErrors];
      return ValidationResult.invalid(allErrors);
    }
    
    return baseValidation;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Submission &&
        other.id == id &&
        other.eventId == eventId &&
        other.teamId == teamId &&
        other.submittedBy == submittedBy &&
        _mapEquals(other.content, content) &&
        other.status == status &&
        other.submittedAt == submittedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventId,
      teamId,
      submittedBy,
      content.toString(),
      status,
      submittedAt,
      createdAt,
      updatedAt,
    );
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }

  @override
  String toString() {
    return 'Submission(id: $id, eventId: $eventId, teamId: $teamId, status: ${status.value}, hasContent: $hasContent)';
  }
}