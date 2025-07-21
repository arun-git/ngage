import 'validation.dart';

/// Member profile model
/// 
/// Represents a member profile that can be claimed by users. Members can exist
/// before users sign up (through bulk import) and get claimed when users authenticate
/// with matching email or phone numbers.
class Member {
  final String id;
  final String? userId; // Nullable until claimed
  final String email;
  final String? phone;
  final String? externalId; // For bulk imports
  final String firstName;
  final String lastName;
  final String? category; // Department/House/Division
  final String? title; // Job title/Role/Year level
  final String? profilePhoto;
  final String? bio;
  final bool isActive;
  final DateTime? importedAt;
  final DateTime? claimedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Member({
    required this.id,
    this.userId,
    required this.email,
    this.phone,
    this.externalId,
    required this.firstName,
    required this.lastName,
    this.category,
    this.title,
    this.profilePhoto,
    this.bio,
    this.isActive = true,
    this.importedAt,
    this.claimedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Member from JSON data
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      externalId: json['externalId'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      category: json['category'] as String?,
      title: json['title'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      bio: json['bio'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      importedAt: json['importedAt'] != null 
          ? DateTime.parse(json['importedAt'] as String) 
          : null,
      claimedAt: json['claimedAt'] != null 
          ? DateTime.parse(json['claimedAt'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Member to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'phone': phone,
      'externalId': externalId,
      'firstName': firstName,
      'lastName': lastName,
      'category': category,
      'title': title,
      'profilePhoto': profilePhoto,
      'bio': bio,
      'isActive': isActive,
      'importedAt': importedAt?.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Member with updated fields
  Member copyWith({
    String? id,
    String? userId,
    String? email,
    String? phone,
    String? externalId,
    String? firstName,
    String? lastName,
    String? category,
    String? title,
    String? profilePhoto,
    String? bio,
    bool? isActive,
    DateTime? importedAt,
    DateTime? claimedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      externalId: externalId ?? this.externalId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      category: category ?? this.category,
      title: title ?? this.title,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      importedAt: importedAt ?? this.importedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Check if member is claimed by a user
  bool get isClaimed => userId != null;

  /// Check if member was imported via bulk import
  bool get wasImported => importedAt != null;

  /// Validate Member data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Member ID'),
      Validators.validateEmail(email),
      Validators.validateOptionalPhone(phone),
      Validators.validateName(firstName, 'First name'),
      Validators.validateName(lastName, 'Last name'),
      Validators.validateDescription(category, maxLength: 100),
      Validators.validateDescription(title, maxLength: 100),
      Validators.validateDescription(bio, maxLength: 1000),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    // Claimed member validation
    if (userId != null && claimedAt == null) {
      additionalErrors.add('Claimed members must have both userId and claimedAt');
    }
    
    if (userId == null && claimedAt != null) {
      additionalErrors.add('Unclaimed members should not have userId or claimedAt');
    }
    
    // claimedAt should be after importedAt if both exist
    if (importedAt != null && claimedAt != null && claimedAt!.isBefore(importedAt!)) {
      additionalErrors.add('Claimed date must be after imported date');
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
    
    return other is Member &&
        other.id == id &&
        other.userId == userId &&
        other.email == email &&
        other.phone == phone &&
        other.externalId == externalId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.category == category &&
        other.title == title &&
        other.profilePhoto == profilePhoto &&
        other.bio == bio &&
        other.isActive == isActive &&
        other.importedAt == importedAt &&
        other.claimedAt == claimedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      email,
      phone,
      externalId,
      firstName,
      lastName,
      category,
      title,
      profilePhoto,
      bio,
      isActive,
      importedAt,
      claimedAt,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Member(id: $id, userId: $userId, email: $email, fullName: $fullName, isActive: $isActive, isClaimed: $isClaimed)';
  }
}