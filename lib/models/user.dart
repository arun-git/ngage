import 'validation.dart';

/// User authentication model
/// 
/// Represents a user account in the system. Users can have multiple member profiles
/// and can switch between them. The defaultMember field points to the currently
/// active member profile.
class User {
  final String id;
  final String email;
  final String? phone;
  final String? defaultMember; // Foreign key to Members
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.phone,
    this.defaultMember,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      defaultMember: json['defaultMember'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'defaultMember': defaultMember,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? defaultMember,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      defaultMember: defaultMember ?? this.defaultMember,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validate User data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'User ID'),
      Validators.validateEmail(email),
      Validators.validateOptionalPhone(phone),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    return Validators.combine(results);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.phone == phone &&
        other.defaultMember == defaultMember &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      phone,
      defaultMember,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, phone: $phone, defaultMember: $defaultMember, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}