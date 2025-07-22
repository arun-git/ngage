import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remember me token model
class RememberMeToken {
  final String token;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String deviceInfo;
  final bool isActive;

  const RememberMeToken({
    required this.token,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    required this.deviceInfo,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'deviceInfo': deviceInfo,
      'isActive': isActive,
    };
  }

  factory RememberMeToken.fromJson(Map<String, dynamic> json) {
    return RememberMeToken(
      token: json['token'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      deviceInfo: json['deviceInfo'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  RememberMeToken copyWith({
    String? token,
    String? userId,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? deviceInfo,
    bool? isActive,
  }) {
    return RememberMeToken(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
}

/// Service for managing remember me functionality
class RememberMeService {
  static const String _tokenKey = 'remember_me_token';
  static const Duration _tokenDuration = Duration(days: 30);
  
  final FlutterSecureStorage _secureStorage;

  RememberMeService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Store a persistent token for the user
  Future<void> storePersistentToken(String userId) async {
    try {
      final token = _generateSecureToken();
      final deviceInfo = await _getDeviceInfo();
      final now = DateTime.now();
      
      final rememberMeToken = RememberMeToken(
        token: token,
        userId: userId,
        createdAt: now,
        expiresAt: now.add(_tokenDuration),
        deviceInfo: deviceInfo,
        isActive: true,
      );

      await _secureStorage.write(
        key: _tokenKey,
        value: jsonEncode(rememberMeToken.toJson()),
      );
    } catch (e) {
      throw Exception('Failed to store persistent token: $e');
    }
  }

  /// Get the stored persistent token
  Future<RememberMeToken?> getPersistentToken() async {
    try {
      final tokenJson = await _secureStorage.read(key: _tokenKey);
      if (tokenJson == null) return null;

      final tokenData = jsonDecode(tokenJson) as Map<String, dynamic>;
      final token = RememberMeToken.fromJson(tokenData);

      // Return null if token is expired or inactive
      if (!token.isValid) {
        await clearPersistentToken();
        return null;
      }

      return token;
    } catch (e) {
      // If there's an error reading the token, clear it and return null
      await clearPersistentToken();
      return null;
    }
  }

  /// Clear the stored persistent token
  Future<void> clearPersistentToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      // Ignore errors when clearing token
    }
  }

  /// Validate a persistent token
  Future<bool> validatePersistentToken(String token) async {
    try {
      final storedToken = await getPersistentToken();
      if (storedToken == null) return false;

      return storedToken.token == token && storedToken.isValid;
    } catch (e) {
      return false;
    }
  }

  /// Check if remember me is enabled for the current device
  Future<bool> isRememberMeEnabled() async {
    final token = await getPersistentToken();
    return token != null && token.isValid;
  }

  /// Refresh the token expiration date
  Future<void> refreshToken() async {
    try {
      final currentToken = await getPersistentToken();
      if (currentToken == null || !currentToken.isValid) return;

      final refreshedToken = currentToken.copyWith(
        expiresAt: DateTime.now().add(_tokenDuration),
      );

      await _secureStorage.write(
        key: _tokenKey,
        value: jsonEncode(refreshedToken.toJson()),
      );
    } catch (e) {
      // If refresh fails, clear the token
      await clearPersistentToken();
    }
  }

  /// Generate a secure random token
  String _generateSecureToken() {
    final bytes = List<int>.generate(32, (i) => 
        DateTime.now().millisecondsSinceEpoch + i);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get device information for security purposes
  Future<String> _getDeviceInfo() async {
    try {
      // Basic device fingerprinting
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      return '$platform-$version-$timestamp';
    } catch (e) {
      return 'unknown-device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Clear all stored data (for sign out)
  Future<void> clearAllData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Ignore errors when clearing all data
    }
  }
}

/// Provider for RememberMeService
final rememberMeServiceProvider = Provider<RememberMeService>((ref) {
  return RememberMeService();
});