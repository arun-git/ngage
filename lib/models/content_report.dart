import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  copyright,
  misinformation,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

enum ContentType {
  post,
  comment,
  submission,
}

class ContentReport {
  final String id;
  final String reporterId; // Member ID who reported
  final String contentId; // ID of the reported content
  final ContentType contentType;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final String? reviewedBy; // Admin member ID who reviewed
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.contentId,
    required this.contentType,
    required this.reason,
    this.description,
    required this.status,
    this.reviewedBy,
    this.reviewNotes,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentReport(
      id: doc.id,
      reporterId: data['reporterId'] as String,
      contentId: data['contentId'] as String,
      contentType: ContentType.values.firstWhere(
        (e) => e.name == data['contentType'],
      ),
      reason: ReportReason.values.firstWhere(
        (e) => e.name == data['reason'],
      ),
      description: data['description'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      reviewedBy: data['reviewedBy'] as String?,
      reviewNotes: data['reviewNotes'] as String?,
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'contentId': contentId,
      'contentType': contentType.name,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ContentReport copyWith({
    String? id,
    String? reporterId,
    String? contentId,
    ContentType? contentType,
    ReportReason? reason,
    String? description,
    ReportStatus? status,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentReport &&
        other.id == id &&
        other.reporterId == reporterId &&
        other.contentId == contentId &&
        other.contentType == contentType &&
        other.reason == reason &&
        other.description == description &&
        other.status == status &&
        other.reviewedBy == reviewedBy &&
        other.reviewNotes == reviewNotes &&
        other.reviewedAt == reviewedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      reporterId,
      contentId,
      contentType,
      reason,
      description,
      status,
      reviewedBy,
      reviewNotes,
      reviewedAt,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ContentReport(id: $id, reporterId: $reporterId, contentId: $contentId, contentType: $contentType, reason: $reason, status: $status)';
  }
}