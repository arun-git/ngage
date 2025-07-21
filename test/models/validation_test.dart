import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/validation.dart';

void main() {
  group('ValidationResult', () {
    test('should create valid result', () {
      final result = ValidationResult.valid();
      
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('should create invalid result with errors', () {
      final errors = ['Error 1', 'Error 2'];
      final result = ValidationResult.invalid(errors);
      
      expect(result.isValid, isFalse);
      expect(result.errors, equals(errors));
    });

    test('should create single error result', () {
      const error = 'Single error';
      final result = ValidationResult.singleError(error);
      
      expect(result.isValid, isFalse);
      expect(result.errors, equals([error]));
    });
  });

  group('Validators.isValidEmail', () {
    test('should validate correct email addresses', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'firstname.lastname@company.com',
        //'email@123.123.123.123', // IP address
        'user@domain-name.com',
      ];

      for (final email in validEmails) {
        expect(Validators.isValidEmail(email), isTrue, reason: 'Email: $email');
      }
    });

    test('should reject invalid email addresses', () {
      final invalidEmails = [
        '',
        'plainaddress',
        '@missingdomain.com',
        'missing@.com',
        'missing.domain@.com',
        'two@@domain.com',
        'domain@.com',
        'user@',
       // '.user@domain.com',
       // 'user.@domain.com',
      ];

      for (final email in invalidEmails) {
        expect(Validators.isValidEmail(email), isFalse, reason: 'Email: $email');
      }
    });
  });

  group('Validators.isValidPhone', () {
    test('should validate correct phone numbers', () {
      final validPhones = [
        '+1234567890',
        '+12345678901',
        '1234567890',
        '+44 20 7946 0958',
        '+1 (555) 123-4567',
        '+86 138 0013 8000',
      ];

      for (final phone in validPhones) {
        expect(Validators.isValidPhone(phone), isTrue, reason: 'Phone: $phone');
      }
    });

    test('should reject invalid phone numbers', () {
      final invalidPhones = [
        '',
        '123',
        '+123',
        'abcdefghij',
        '+0123456789', // starts with 0 after country code
        '12345', // too short
        '+123456789012345678', // too long
      ];

      for (final phone in invalidPhones) {
        expect(Validators.isValidPhone(phone), isFalse, reason: 'Phone: $phone');
      }
    });
  });

  group('Validators.isNotEmpty', () {
    test('should return true for non-empty strings', () {
      expect(Validators.isNotEmpty('test'), isTrue);
      expect(Validators.isNotEmpty(' test '), isTrue);
      expect(Validators.isNotEmpty('a'), isTrue);
    });

    test('should return false for empty or null strings', () {
      expect(Validators.isNotEmpty(null), isFalse);
      expect(Validators.isNotEmpty(''), isFalse);
      expect(Validators.isNotEmpty('   '), isFalse);
    });
  });

  group('Validators.hasMinLength', () {
    test('should validate minimum length correctly', () {
      expect(Validators.hasMinLength('test', 3), isTrue);
      expect(Validators.hasMinLength('test', 4), isTrue);
      expect(Validators.hasMinLength('test', 5), isFalse);
      expect(Validators.hasMinLength(null, 1), isFalse);
      expect(Validators.hasMinLength('', 1), isFalse);
    });
  });

  group('Validators.hasMaxLength', () {
    test('should validate maximum length correctly', () {
      expect(Validators.hasMaxLength('test', 5), isTrue);
      expect(Validators.hasMaxLength('test', 4), isTrue);
      expect(Validators.hasMaxLength('test', 3), isFalse);
      expect(Validators.hasMaxLength(null, 1), isTrue);
      expect(Validators.hasMaxLength('', 1), isTrue);
    });
  });

  group('Validators.validateName', () {
    test('should validate correct names', () {
      final result = Validators.validateName('John', 'First name');
      expect(result.isValid, isTrue);
    });

    test('should reject empty names', () {
      final result = Validators.validateName('', 'First name');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('First name is required'));
    });

    test('should reject null names', () {
      final result = Validators.validateName(null, 'First name');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('First name is required'));
    });

    test('should reject names that are too long', () {
      final longName = 'a' * 51;
      final result = Validators.validateName(longName, 'First name');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('First name must not exceed 50 characters'));
    });
  });

  group('Validators.validateEmail', () {
    test('should validate correct email', () {
      final result = Validators.validateEmail('test@example.com');
      expect(result.isValid, isTrue);
    });

    test('should reject invalid email', () {
      final result = Validators.validateEmail('invalid-email');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Please enter a valid email address'));
    });

    test('should reject empty email', () {
      final result = Validators.validateEmail('');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Email is required'));
    });
  });

  group('Validators.validateOptionalEmail', () {
    test('should allow null or empty email', () {
      expect(Validators.validateOptionalEmail(null).isValid, isTrue);
      expect(Validators.validateOptionalEmail('').isValid, isTrue);
      expect(Validators.validateOptionalEmail('   ').isValid, isTrue);
    });

    test('should validate provided email', () {
      expect(Validators.validateOptionalEmail('test@example.com').isValid, isTrue);
      expect(Validators.validateOptionalEmail('invalid-email').isValid, isFalse);
    });
  });

  group('Validators.validatePhone', () {
    test('should validate correct phone', () {
      final result = Validators.validatePhone('+1234567890');
      expect(result.isValid, isTrue);
    });

    test('should reject invalid phone', () {
      final result = Validators.validatePhone('123');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Please enter a valid phone number'));
    });

    test('should reject empty phone', () {
      final result = Validators.validatePhone('');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Phone number is required'));
    });
  });

  group('Validators.validateOptionalPhone', () {
    test('should allow null or empty phone', () {
      expect(Validators.validateOptionalPhone(null).isValid, isTrue);
      expect(Validators.validateOptionalPhone('').isValid, isTrue);
      expect(Validators.validateOptionalPhone('   ').isValid, isTrue);
    });

    test('should validate provided phone', () {
      expect(Validators.validateOptionalPhone('+1234567890').isValid, isTrue);
      expect(Validators.validateOptionalPhone('123').isValid, isFalse);
    });
  });

  group('Validators.validateDescription', () {
    test('should allow null or empty description', () {
      expect(Validators.validateDescription(null).isValid, isTrue);
      expect(Validators.validateDescription('').isValid, isTrue);
    });

    test('should validate description within length limit', () {
      final description = 'a' * 500;
      expect(Validators.validateDescription(description).isValid, isTrue);
    });

    test('should reject description exceeding length limit', () {
      final description = 'a' * 501;
      final result = Validators.validateDescription(description);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Description must not exceed 500 characters'));
    });

    test('should respect custom max length', () {
      final description = 'a' * 101;
      final result = Validators.validateDescription(description, maxLength: 100);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Description must not exceed 100 characters'));
    });
  });

  group('Validators.validateId', () {
    test('should validate non-empty ID', () {
      final result = Validators.validateId('user123', 'User ID');
      expect(result.isValid, isTrue);
    });

    test('should reject empty ID', () {
      final result = Validators.validateId('', 'User ID');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('User ID is required'));
    });

    test('should reject null ID', () {
      final result = Validators.validateId(null, 'User ID');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('User ID is required'));
    });
  });

  group('Validators.validateDate', () {
    test('should validate non-null date', () {
      final result = Validators.validateDate(DateTime.now(), 'Created date');
      expect(result.isValid, isTrue);
    });

    test('should reject null date', () {
      final result = Validators.validateDate(null, 'Created date');
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Created date is required'));
    });
  });

  group('Validators.validateDateRange', () {
    test('should validate correct date range', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 2);
      final result = Validators.validateDateRange(start, end);
      expect(result.isValid, isTrue);
    });

    test('should reject invalid date range', () {
      final start = DateTime(2024, 1, 2);
      final end = DateTime(2024, 1, 1);
      final result = Validators.validateDateRange(start, end);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('End date must be after start date'));
    });

    test('should allow null dates', () {
      expect(Validators.validateDateRange(null, DateTime.now()).isValid, isTrue);
      expect(Validators.validateDateRange(DateTime.now(), null).isValid, isTrue);
      expect(Validators.validateDateRange(null, null).isValid, isTrue);
    });
  });

  group('Validators.combine', () {
    test('should combine valid results', () {
      final results = [
        ValidationResult.valid(),
        ValidationResult.valid(),
      ];
      final combined = Validators.combine(results);
      expect(combined.isValid, isTrue);
      expect(combined.errors, isEmpty);
    });

    test('should combine invalid results', () {
      final results = [
        ValidationResult.singleError('Error 1'),
        ValidationResult.invalid(['Error 2', 'Error 3']),
        ValidationResult.valid(),
      ];
      final combined = Validators.combine(results);
      expect(combined.isValid, isFalse);
      expect(combined.errors, equals(['Error 1', 'Error 2', 'Error 3']));
    });

    test('should handle empty list', () {
      final combined = Validators.combine([]);
      expect(combined.isValid, isTrue);
      expect(combined.errors, isEmpty);
    });
  });
}