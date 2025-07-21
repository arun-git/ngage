import '../models/enums.dart';

/// Represents a privacy request for GDPR compliance
class PrivacyRequest {
  final String id;
  final String memberId;
  final PrivacyRequestType requestType;
  final PrivacyRequestStatus status;
  final String? description;
  final String? reason;
  final Map<String, dynamic>? requestData;
  final String? processedBy;
  final DateTime? processedAt;
  final String? responseData;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrivacyRequest({
    required this.id,
    required this.memberId,
    required this.requestType,
    required this.status,
    this.description,
    this.reason,
    this.requestData,
    this.processedBy,
    this.processedAt,
    this.responseData,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this privacy request with updated fields
  PrivacyRequest copyWith({
    String? id,
    String? memberId,
    PrivacyRequestType? requestType,
    PrivacyRequestStatus? status,
    String? description,
    String? reason,
    Map<String, dynamic>? requestData,
    String? processedBy,
    DateTime? processedAt,
    String? responseData,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivacyRequest(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      requestData: requestData ?? this.requestData,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      responseData: responseData ?? this.responseData,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if request is still pending
  bool get isPending => status == PrivacyRequestStatus.pending;

  /// Check if request is in progress
  bool get isInProgress => status == PrivacyRequestStatus.inProgress;

  /// Check if request is completed
  bool get isCompleted => status == PrivacyRequestStatus.completed;

  /// Check if request was rejected
  bool get isRejected => status == PrivacyRequestStatus.rejected;

  /// Mark request as in progress
  PrivacyRequest markInProgress(String processedBy) {
    return copyWith(
      status: PrivacyRequestStatus.inProgress,
      processedBy: processedBy,
      processedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Mark request as completed
  PrivacyRequest markCompleted(String responseData) {
    return copyWith(
      status: PrivacyRequestStatus.completed,
      responseData: responseData,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark request as rejected
  PrivacyRequest markRejected(String rejectionReason) {
    return copyWith(
      status: PrivacyRequestStatus.rejected,
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'requestType': requestType.value,
      'status': status.value,
      'description': description,
      'reason': reason,
      'requestData': requestData,
      'processedBy': processedBy,
      'processedAt': processedAt?.toIso8601String(),
      'responseData': responseData,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (Firestore document)
  factory PrivacyRequest.fromJson(Map<String, dynamic> json) {
    return PrivacyRequest(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      requestType: PrivacyRequestType.fromString(json['requestType'] as String),
      status: PrivacyRequestStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      reason: json['reason'] as String?,
      requestData: json['requestData'] as Map<String, dynamic>?,
      processedBy: json['processedBy'] as String?,
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt'] as String) 
          : null,
      responseData: json['responseData'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacyRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PrivacyRequest(id: $id, memberId: $memberId, requestType: ${requestType.value}, status: ${status.value})';
  }
}

/// Data for creating a new privacy request
class CreatePrivacyRequestData {
  final String memberId;
  final PrivacyRequestType requestType;
  final String? description;
  final String? reason;
  final Map<String, dynamic>? requestData;

  const CreatePrivacyRequestData({
    required this.memberId,
    required this.requestType,
    this.description,
    this.reason,
    this.requestData,
  });
}