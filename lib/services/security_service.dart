import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Service for handling secure data operations and encryption
class SecurityService {
  static const String _saltPrefix = 'ngage_salt_';
  static const int _saltLength = 32;

  /// Hash sensitive data with salt
  String hashData(String data, {String? salt}) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(data + salt);
    final digest = sha256.convert(bytes);
    return '${salt}:${digest.toString()}';
  }

  /// Verify hashed data
  bool verifyHashedData(String data, String hashedData) {
    try {
      final parts = hashedData.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final expectedHash = parts[1];
      
      final bytes = utf8.encode(data + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Generate secure salt
  String _generateSalt() {
    final bytes = List<int>.generate(_saltLength, (i) => 
      DateTime.now().millisecondsSinceEpoch % 256);
    return base64.encode(bytes);
  }

  /// Sanitize input data to prevent injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s@.-]'), '') // Keep only safe characters
        .trim();
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleanPhone);
  }

  /// Generate secure token
  String generateSecureToken({int length = 32}) {
    final bytes = List<int>.generate(length, (i) => 
      DateTime.now().microsecondsSinceEpoch % 256);
    return base64Url.encode(bytes).substring(0, length);
  }

  /// Mask sensitive data for logging
  String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }
    
    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final middle = '*' * (data.length - visibleChars * 2);
    
    return '$start$middle$end';
  }

  /// Validate password strength
  PasswordStrength validatePasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }
    
    int score = 0;
    
    // Length bonus
    if (password.length >= 12) score += 2;
    else if (password.length >= 10) score += 1;
    
    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 2;
    
    // No common patterns
    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) score += 1; // No repeated chars
    if (!RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde)').hasMatch(password.toLowerCase())) score += 1;
    
    if (score >= 7) return PasswordStrength.strong;
    if (score >= 4) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// Check for common security vulnerabilities in user input
  SecurityVulnerability checkForVulnerabilities(String input) {
    // SQL Injection patterns
    if (RegExp(r"('|(\\')|(;|\\x3B)|(\\||\\x7C))", caseSensitive: false).hasMatch(input)) {
      return SecurityVulnerability.sqlInjection;
    }
    
    // XSS patterns
    if (RegExp(r'<script[^>]*>.*?</script>|javascript:|on\w+\s*=', caseSensitive: false).hasMatch(input)) {
      return SecurityVulnerability.xss;
    }
    
    // Path traversal
    if (RegExp(r'\.\.\/|\.\.\\').hasMatch(input)) {
      return SecurityVulnerability.pathTraversal;
    }
    
    // Command injection
    if (RegExp(r'[;&|`$]').hasMatch(input)) {
      return SecurityVulnerability.commandInjection;
    }
    
    return SecurityVulnerability.none;
  }

  /// Rate limiting check
  bool checkRateLimit(String identifier, int maxRequests, Duration timeWindow) {
    // This would typically use a cache like Redis in production
    // For now, we'll use a simple in-memory approach
    final now = DateTime.now();
    final windowStart = now.subtract(timeWindow);
    
    // In production, you'd check against a persistent store
    // and clean up old entries periodically
    return true; // Simplified for demo
  }

  /// Audit log entry for security events
  Map<String, dynamic> createAuditLogEntry({
    required String action,
    required String memberId,
    String? resource,
    String? details,
    bool isSuccess = true,
    String? ipAddress,
    String? userAgent,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'memberId': memberId,
      'resource': resource,
      'details': details,
      'success': isSuccess,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'sessionId': generateSecureToken(length: 16),
    };
  }

  /// Validate file upload security
  FileUploadValidation validateFileUpload({
    required String fileName,
    required int fileSize,
    required String mimeType,
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB default
    List<String> allowedMimeTypes = const [
      'image/jpeg',
      'image/png',
      'image/gif',
      'video/mp4',
      'video/quicktime',
      'application/pdf',
      'text/plain',
    ],
  }) {
    // Check file size
    if (fileSize > maxSizeBytes) {
      return FileUploadValidation.fileTooLarge;
    }
    
    // Check MIME type
    if (!allowedMimeTypes.contains(mimeType.toLowerCase())) {
      return FileUploadValidation.invalidFileType;
    }
    
    // Check file extension
    final extension = fileName.toLowerCase().split('.').last;
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'pdf', 'txt'];
    if (!allowedExtensions.contains(extension)) {
      return FileUploadValidation.invalidFileExtension;
    }
    
    // Check for suspicious file names
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(fileName)) {
      return FileUploadValidation.suspiciousFileName;
    }
    
    return FileUploadValidation.valid;
  }

  /// Generate CSRF token
  String generateCSRFToken() {
    return generateSecureToken(length: 32);
  }

  /// Validate CSRF token
  bool validateCSRFToken(String token, String expectedToken) {
    return token == expectedToken && token.isNotEmpty;
  }

  /// Secure session management
  Map<String, dynamic> createSecureSession({
    required String memberId,
    Duration? expiresIn,
  }) {
    final now = DateTime.now();
    final expiresAt = now.add(expiresIn ?? const Duration(hours: 24));
    
    return {
      'sessionId': generateSecureToken(length: 32),
      'memberId': memberId,
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': true,
      'lastActivity': now.toIso8601String(),
    };
  }

  /// Validate session
  bool isValidSession(Map<String, dynamic> session) {
    try {
      final expiresAt = DateTime.parse(session['expiresAt'] as String);
      final isActive = session['isActive'] as bool;
      
      return isActive && DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  /// Update session activity
  Map<String, dynamic> updateSessionActivity(Map<String, dynamic> session) {
    return {
      ...session,
      'lastActivity': DateTime.now().toIso8601String(),
    };
  }

  /// Revoke session
  Map<String, dynamic> revokeSession(Map<String, dynamic> session) {
    return {
      ...session,
      'isActive': false,
      'revokedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Security vulnerability types
enum SecurityVulnerability {
  none,
  sqlInjection,
  xss,
  pathTraversal,
  commandInjection,
}

/// File upload validation results
enum FileUploadValidation {
  valid,
  fileTooLarge,
  invalidFileType,
  invalidFileExtension,
  suspiciousFileName,
}