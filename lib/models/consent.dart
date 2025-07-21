import '../models/enums.dart';

/// Represents a user's consent for specific data usage
class Consent {
  final String id;
  final String memberId;
  final ConsentType consentType;
  final bool granted;
  final String? purpose;
  final String? description;
  final DateTime grantedAt;
  final DateTime? revokedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Consent({
    required this.id,
    required this.memberId,
    required this.consentType,
    required this.granted,
    this.purpose,
    this.description,
    required this.grantedAt,
    this.revokedAt,
    this.expiresAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this consent with updated fields
  Consent copyWith({
    String? id,
    String? memberId,
    ConsentType? consentType,
    bool? granted,
    String? purpose,
    String? description,
    DateTime? grantedAt,
    DateTime? revokedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consent(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      consentType: consentType ?? this.consentType,
      granted: granted ?? this.granted,
      purpose: purpose ?? this.purpose,
      description: description ?? this.description,
      grantedAt: grantedAt ?? this.grantedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if consent is currently valid
  bool get isValid {
    if (!granted || revokedAt != null) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Revoke this consent
  Consent revoke() {
    return copyWith(
      granted: false,
      revokedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'consentType': consentType.value,
      'granted': granted,
      'purpose': purpose,
      'description': description,
      'grantedAt': grantedAt.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (Firestore document)
  factory Consent.fromJson(Map<String, dynamic> json) {
    return Consent(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      consentType: ConsentType.fromString(json['consentType'] as String),
      granted: json['granted'] as bool,
      purpose: json['purpose'] as String?,
      description: json['description'] as String?,
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      revokedAt: json['revokedAt'] != null 
          ? DateTime.parse(json['revokedAt'] as String) 
          : null,
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String) 
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Consent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Consent(id: $id, memberId: $memberId, consentType: ${consentType.value}, granted: $granted)';
  }
}

/// Data for creating a new consent
class CreateConsentData {
  final String memberId;
  final ConsentType consentType;
  final bool granted;
  final String? purpose;
  final String? description;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  const CreateConsentData({
    required this.memberId,
    required this.consentType,
    required this.granted,
    this.purpose,
    this.description,
    this.expiresAt,
    this.metadata,
  });
}