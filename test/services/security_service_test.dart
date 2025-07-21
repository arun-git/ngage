import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/security_service.dart';

void main() {
  group('SecurityService', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService();
    });

    group('Data Hashing', () {
      test('should hash data with salt', () {
        // Act
        final hashedData = securityService.hashData('sensitive_data');

        // Assert
        expect(hashedData, contains(':'));
        expect(hashedData.split(':'), hasLength(2));
      });

      test('should verify hashed data correctly', () {
        // Arrange
        const originalData = 'test_password';
        final hashedData = securityService.hashData(originalData);

        // Act
        final isValid = securityService.verifyHashedData(originalData, hashedData);

        // Assert
        expect(isValid, isTrue);
      });

      test('should fail verification for incorrect data', () {
        // Arrange
        const originalData = 'test_password';
        const wrongData = 'wrong_password';
        final hashedData = securityService.hashData(originalData);

        // Act
        final isValid = securityService.verifyHashedData(wrongData, hashedData);

        // Assert
        expect(isValid, isFalse);
      });

      test('should handle malformed hash data', () {
        // Act
        final isValid = securityService.verifyHashedData('test', 'malformed_hash');

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Input Sanitization', () {
      test('should remove script tags', () {
        // Arrange
        const input = 'Hello <script>alert("xss")</script> World';

        // Act
        final sanitized = securityService.sanitizeInput(input);

        // Assert
        expect(sanitized, equals('Hello  World'));
      });

      test('should remove HTML tags', () {
        // Arrange
        const input = 'Hello <b>bold</b> and <i>italic</i> text';

        // Act
        final sanitized = securityService.sanitizeInput(input);

        // Assert
        expect(sanitized, equals('Hello bold and italic text'));
      });

      test('should remove unsafe characters', () {
        // Arrange
        const input = 'Hello & <world> with "quotes" and \'apostrophes\'';

        // Act
        final sanitized = securityService.sanitizeInput(input);

        // Assert
        expect(sanitized, equals('Hello  world with quotes and apostrophes'));
      });

      test('should preserve safe characters', () {
        // Arrange
        const input = 'john.doe@example.com with spaces and-dashes';

        // Act
        final sanitized = securityService.sanitizeInput(input);

        // Assert
        expect(sanitized, equals('john.doe@example.com with spaces and-dashes'));
      });
    });

    group('Validation', () {
      test('should validate correct email formats', () {
        // Arrange
        const validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
        ];

        // Act & Assert
        for (final email in validEmails) {
          expect(securityService.isValidEmail(email), isTrue, reason: 'Email: $email');
        }
      });

      test('should reject invalid email formats', () {
        // Arrange
        const invalidEmails = [
          'invalid-email',
          '@example.com',
          'user@',
          'user@.com',
          'user space@example.com',
        ];

        // Act & Assert
        for (final email in invalidEmails) {
          expect(securityService.isValidEmail(email), isFalse, reason: 'Email: $email');
        }
      });

      test('should validate correct phone number formats', () {
        // Arrange
        const validPhones = [
          '+1234567890',
          '1234567890',
          '+44 20 7946 0958',
          '+1-555-123-4567',
        ];

        // Act & Assert
        for (final phone in validPhones) {
          expect(securityService.isValidPhoneNumber(phone), isTrue, reason: 'Phone: $phone');
        }
      });

      test('should reject invalid phone number formats', () {
        // Arrange
        const invalidPhones = [
          'abc123',
          '123',
          '+',
          '++1234567890',
        ];

        // Act & Assert
        for (final phone in invalidPhones) {
          expect(securityService.isValidPhoneNumber(phone), isFalse, reason: 'Phone: $phone');
        }
      });
    });

    group('Password Strength', () {
      test('should classify weak passwords', () {
        // Arrange
        const weakPasswords = [
          'weak',
          '123456',
          'password',
          'abc123',
        ];

        // Act & Assert
        for (final password in weakPasswords) {
          final strength = securityService.validatePasswordStrength(password);
          expect(strength, equals(PasswordStrength.weak), reason: 'Password: $password');
        }
      });

      test('should classify medium passwords', () {
        // Arrange
        const mediumPasswords = [
          'Password123',
          'MyPass2023',
          'Test@123',
        ];

        // Act & Assert
        for (final password in mediumPasswords) {
          final strength = securityService.validatePasswordStrength(password);
          expect(strength, equals(PasswordStrength.medium), reason: 'Password: $password');
        }
      });

      test('should classify strong passwords', () {
        // Arrange
        const strongPasswords = [
          'MyVeryStr0ng!Password2023',
          'C0mpl3x@P@ssw0rd!',
          'Sup3rS3cur3!P@ssw0rd123',
        ];

        // Act & Assert
        for (final password in strongPasswords) {
          final strength = securityService.validatePasswordStrength(password);
          expect(strength, equals(PasswordStrength.strong), reason: 'Password: $password');
        }
      });
    });

    group('Security Vulnerability Detection', () {
      test('should detect SQL injection attempts', () {
        // Arrange
        const sqlInjectionInputs = [
          "'; DROP TABLE users; --",
          "1' OR '1'='1",
          "admin'--",
        ];

        // Act & Assert
        for (final input in sqlInjectionInputs) {
          final vulnerability = securityService.checkForVulnerabilities(input);
          expect(vulnerability, equals(SecurityVulnerability.sqlInjection), reason: 'Input: $input');
        }
      });

      test('should detect XSS attempts', () {
        // Arrange
        const xssInputs = [
          '<script>alert("xss")</script>',
          'javascript:alert("xss")',
          '<img onerror="alert(1)" src="x">',
        ];

        // Act & Assert
        for (final input in xssInputs) {
          final vulnerability = securityService.checkForVulnerabilities(input);
          expect(vulnerability, equals(SecurityVulnerability.xss), reason: 'Input: $input');
        }
      });

      test('should detect path traversal attempts', () {
        // Arrange
        const pathTraversalInputs = [
          '../../../etc/passwd',
          '..\\..\\windows\\system32',
          'file/../../../secret.txt',
        ];

        // Act & Assert
        for (final input in pathTraversalInputs) {
          final vulnerability = securityService.checkForVulnerabilities(input);
          expect(vulnerability, equals(SecurityVulnerability.pathTraversal), reason: 'Input: $input');
        }
      });

      test('should detect command injection attempts', () {
        // Arrange
        const commandInjectionInputs = [
          'file.txt; rm -rf /',
          'data | cat /etc/passwd',
          'input && malicious_command',
        ];

        // Act & Assert
        for (final input in commandInjectionInputs) {
          final vulnerability = securityService.checkForVulnerabilities(input);
          expect(vulnerability, equals(SecurityVulnerability.commandInjection), reason: 'Input: $input');
        }
      });

      test('should return none for safe inputs', () {
        // Arrange
        const safeInputs = [
          'normal text',
          'user@example.com',
          'Safe file name.txt',
          'Regular content with spaces',
        ];

        // Act & Assert
        for (final input in safeInputs) {
          final vulnerability = securityService.checkForVulnerabilities(input);
          expect(vulnerability, equals(SecurityVulnerability.none), reason: 'Input: $input');
        }
      });
    });

    group('Token Generation', () {
      test('should generate secure tokens', () {
        // Act
        final token1 = securityService.generateSecureToken();
        final token2 = securityService.generateSecureToken();

        // Assert
        expect(token1, isNotEmpty);
        expect(token2, isNotEmpty);
        expect(token1, isNot(equals(token2)));
        expect(token1.length, equals(32));
      });

      test('should generate tokens with custom length', () {
        // Act
        final token = securityService.generateSecureToken(length: 16);

        // Assert
        expect(token.length, equals(16));
      });
    });

    group('Data Masking', () {
      test('should mask sensitive data correctly', () {
        // Arrange
        const sensitiveData = 'credit_card_1234567890123456';

        // Act
        final masked = securityService.maskSensitiveData(sensitiveData);

        // Assert
        expect(masked, startsWith('cred'));
        expect(masked, endsWith('3456'));
        expect(masked, contains('*'));
      });

      test('should mask short data completely', () {
        // Arrange
        const shortData = 'abc';

        // Act
        final masked = securityService.maskSensitiveData(shortData);

        // Assert
        expect(masked, equals('***'));
      });
    });

    group('File Upload Validation', () {
      test('should validate allowed file types', () {
        // Act
        final result = securityService.validateFileUpload(
          fileName: 'image.jpg',
          fileSize: 1024 * 1024, // 1MB
          mimeType: 'image/jpeg',
        );

        // Assert
        expect(result, equals(FileUploadValidation.valid));
      });

      test('should reject files that are too large', () {
        // Act
        final result = securityService.validateFileUpload(
          fileName: 'large_file.jpg',
          fileSize: 20 * 1024 * 1024, // 20MB
          mimeType: 'image/jpeg',
          maxSizeBytes: 10 * 1024 * 1024, // 10MB limit
        );

        // Assert
        expect(result, equals(FileUploadValidation.fileTooLarge));
      });

      test('should reject invalid MIME types', () {
        // Act
        final result = securityService.validateFileUpload(
          fileName: 'script.exe',
          fileSize: 1024,
          mimeType: 'application/x-executable',
        );

        // Assert
        expect(result, equals(FileUploadValidation.invalidFileType));
      });

      test('should reject invalid file extensions', () {
        // Act
        final result = securityService.validateFileUpload(
          fileName: 'malicious.exe',
          fileSize: 1024,
          mimeType: 'image/jpeg', // Spoofed MIME type
        );

        // Assert
        expect(result, equals(FileUploadValidation.invalidFileExtension));
      });

      test('should reject suspicious file names', () {
        // Act
        final result = securityService.validateFileUpload(
          fileName: 'file<script>.jpg',
          fileSize: 1024,
          mimeType: 'image/jpeg',
        );

        // Assert
        expect(result, equals(FileUploadValidation.suspiciousFileName));
      });
    });

    group('CSRF Protection', () {
      test('should generate CSRF tokens', () {
        // Act
        final token1 = securityService.generateCSRFToken();
        final token2 = securityService.generateCSRFToken();

        // Assert
        expect(token1, isNotEmpty);
        expect(token2, isNotEmpty);
        expect(token1, isNot(equals(token2)));
        expect(token1.length, equals(32));
      });

      test('should validate CSRF tokens correctly', () {
        // Arrange
        final token = securityService.generateCSRFToken();

        // Act
        final isValid = securityService.validateCSRFToken(token, token);

        // Assert
        expect(isValid, isTrue);
      });

      test('should reject invalid CSRF tokens', () {
        // Arrange
        final token1 = securityService.generateCSRFToken();
        final token2 = securityService.generateCSRFToken();

        // Act
        final isValid = securityService.validateCSRFToken(token1, token2);

        // Assert
        expect(isValid, isFalse);
      });

      test('should reject empty CSRF tokens', () {
        // Act
        final isValid = securityService.validateCSRFToken('', '');

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Session Management', () {
      test('should create secure sessions', () {
        // Act
        final session = securityService.createSecureSession(memberId: 'member_1');

        // Assert
        expect(session['sessionId'], isNotEmpty);
        expect(session['memberId'], equals('member_1'));
        expect(session['isActive'], isTrue);
        expect(session['createdAt'], isNotNull);
        expect(session['expiresAt'], isNotNull);
      });

      test('should validate active sessions', () {
        // Arrange
        final session = securityService.createSecureSession(memberId: 'member_1');

        // Act
        final isValid = securityService.isValidSession(session);

        // Assert
        expect(isValid, isTrue);
      });

      test('should reject expired sessions', () {
        // Arrange
        final expiredSession = {
          'sessionId': 'session_1',
          'memberId': 'member_1',
          'isActive': true,
          'expiresAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        };

        // Act
        final isValid = securityService.isValidSession(expiredSession);

        // Assert
        expect(isValid, isFalse);
      });

      test('should reject inactive sessions', () {
        // Arrange
        final inactiveSession = {
          'sessionId': 'session_1',
          'memberId': 'member_1',
          'isActive': false,
          'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        };

        // Act
        final isValid = securityService.isValidSession(inactiveSession);

        // Assert
        expect(isValid, isFalse);
      });

      test('should update session activity', () {
        // Arrange
        final session = securityService.createSecureSession(memberId: 'member_1');
        final originalActivity = session['lastActivity'];

        // Wait a bit to ensure different timestamp
        Future.delayed(const Duration(milliseconds: 1));

        // Act
        final updatedSession = securityService.updateSessionActivity(session);

        // Assert
        expect(updatedSession['lastActivity'], isNot(equals(originalActivity)));
      });

      test('should revoke sessions', () {
        // Arrange
        final session = securityService.createSecureSession(memberId: 'member_1');

        // Act
        final revokedSession = securityService.revokeSession(session);

        // Assert
        expect(revokedSession['isActive'], isFalse);
        expect(revokedSession['revokedAt'], isNotNull);
      });
    });

    group('Audit Logging', () {
      test('should create audit log entries', () {
        // Act
        final logEntry = securityService.createAuditLogEntry(
          action: 'login',
          memberId: 'member_1',
          resource: 'auth',
          details: 'Successful login',
          ipAddress: '192.168.1.1',
          userAgent: 'Mozilla/5.0...',
        );

        // Assert
        expect(logEntry['action'], equals('login'));
        expect(logEntry['memberId'], equals('member_1'));
        expect(logEntry['resource'], equals('auth'));
        expect(logEntry['details'], equals('Successful login'));
        expect(logEntry['success'], isTrue);
        expect(logEntry['ipAddress'], equals('192.168.1.1'));
        expect(logEntry['timestamp'], isNotNull);
        expect(logEntry['sessionId'], isNotNull);
      });

      test('should create audit log entries for failures', () {
        // Act
        final logEntry = securityService.createAuditLogEntry(
          action: 'login',
          memberId: 'member_1',
          isSuccess: false,
          details: 'Invalid credentials',
        );

        // Assert
        expect(logEntry['success'], isFalse);
        expect(logEntry['details'], equals('Invalid credentials'));
      });
    });
  });
}