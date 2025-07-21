import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/bulk_import.dart';

void main() {
  group('MemberImportData', () {
    group('fromCsvRow', () {
      test('should create instance from CSV row with all fields', () {
        // Arrange
        final csvRow = {
          'email': 'john.doe@example.com',
          'first_name': 'John',
          'last_name': 'Doe',
          'phone': '+1234567890',
          'external_id': 'EMP001',
          'category': 'Engineering',
          'title': 'Software Engineer',
        };

        // Act
        final result = MemberImportData.fromCsvRow(csvRow);

        // Assert
        expect(result.email, equals('john.doe@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.phone, equals('+1234567890'));
        expect(result.externalId, equals('EMP001'));
        expect(result.category, equals('Engineering'));
        expect(result.title, equals('Software Engineer'));
      });

      test('should handle missing optional fields', () {
        // Arrange
        final csvRow = {
          'email': 'john.doe@example.com',
          'first_name': 'John',
          'last_name': 'Doe',
        };

        // Act
        final result = MemberImportData.fromCsvRow(csvRow);

        // Assert
        expect(result.email, equals('john.doe@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.phone, isNull);
        expect(result.externalId, isNull);
        expect(result.category, isNull);
        expect(result.title, isNull);
      });

      test('should handle case-insensitive headers', () {
        // Arrange
        final csvRow = {
          'EMAIL': 'john.doe@example.com',
          'First_Name': 'John',
          'Last_Name': 'Doe',
          'PHONE': '+1234567890',
        };

        // Act
        final result = MemberImportData.fromCsvRow(csvRow);

        // Assert
        expect(result.email, equals('john.doe@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.phone, equals('+1234567890'));
      });

      test('should handle alternative header formats', () {
        // Arrange
        final csvRow = {
          'email': 'john.doe@example.com',
          'firstName': 'John', // camelCase instead of snake_case
          'lastName': 'Doe',
          'externalId': 'EMP001',
        };

        // Act
        final result = MemberImportData.fromCsvRow(csvRow);

        // Assert
        expect(result.email, equals('john.doe@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.externalId, equals('EMP001'));
      });

      test('should trim whitespace from values', () {
        // Arrange
        final csvRow = {
          'email': '  john.doe@example.com  ',
          'first_name': '  John  ',
          'last_name': '  Doe  ',
          'phone': '  +1234567890  ',
        };

        // Act
        final result = MemberImportData.fromCsvRow(csvRow);

        // Assert
        expect(result.email, equals('john.doe@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.phone, equals('+1234567890'));
      });

      test('should handle empty string values as null', () {
        // Arrange
        final csvRow = {
          'email': 'john.doe@example.com',
          'first_name': 'John',
          'last_name': 'Doe',
          'phone': '',
          'external_id': '   ',
          'category': null,
        };

        // Act
        final result = MemberImportData.fromCsvRow(csvRow);

        // Assert
        expect(result.email, equals('john.doe@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        expect(result.phone, isNull);
        expect(result.externalId, isNull);
        expect(result.category, isNull);
      });
    });

    group('validate', () {
      test('should validate successfully with all valid data', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+1234567890',
          externalId: 'EMP001',
          category: 'Engineering',
          title: 'Software Engineer',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should validate successfully with minimal required data', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation with invalid email', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'invalid-email',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('valid email address')));
      });

      test('should fail validation with empty email', () {
        // Arrange
        const memberData = MemberImportData(
          email: '',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('Email is required')));
      });

      test('should fail validation with empty first name', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: '',
          lastName: 'Doe',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('First name is required')));
      });

      test('should fail validation with empty last name', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: '',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('Last name is required')));
      });

      test('should fail validation with invalid phone', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: 'invalid-phone',
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('valid phone number')));
      });

      test('should pass validation with null optional phone', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: null,
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation with too long category', () {
        // Arrange
        final longCategory = 'A' * 101; // Exceeds 100 character limit
        final memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          category: longCategory,
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('must not exceed 100 characters')));
      });

      test('should fail validation with too long title', () {
        // Arrange
        final longTitle = 'A' * 101; // Exceeds 100 character limit
        final memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          title: longTitle,
        );

        // Act
        final result = memberData.validate();

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('must not exceed 100 characters')));
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+1234567890',
          externalId: 'EMP001',
          category: 'Engineering',
          title: 'Software Engineer',
        );

        // Act
        final json = memberData.toJson();

        // Assert
        expect(json['email'], equals('john.doe@example.com'));
        expect(json['firstName'], equals('John'));
        expect(json['lastName'], equals('Doe'));
        expect(json['phone'], equals('+1234567890'));
        expect(json['externalId'], equals('EMP001'));
        expect(json['category'], equals('Engineering'));
        expect(json['title'], equals('Software Engineer'));
      });

      test('should handle null values in JSON', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final json = memberData.toJson();

        // Assert
        expect(json['email'], equals('john.doe@example.com'));
        expect(json['firstName'], equals('John'));
        expect(json['lastName'], equals('Doe'));
        expect(json['phone'], isNull);
        expect(json['externalId'], isNull);
        expect(json['category'], isNull);
        expect(json['title'], isNull);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all fields match', () {
        // Arrange
        const memberData1 = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+1234567890',
        );

        const memberData2 = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+1234567890',
        );

        // Act & Assert
        expect(memberData1, equals(memberData2));
        expect(memberData1.hashCode, equals(memberData2.hashCode));
      });

      test('should not be equal when fields differ', () {
        // Arrange
        const memberData1 = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        const memberData2 = MemberImportData(
          email: 'jane.smith@example.com',
          firstName: 'Jane',
          lastName: 'Smith',
        );

        // Act & Assert
        expect(memberData1, isNot(equals(memberData2)));
        expect(memberData1.hashCode, isNot(equals(memberData2.hashCode)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        // Arrange
        const memberData = MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final result = memberData.toString();

        // Assert
        expect(result, contains('john.doe@example.com'));
        expect(result, contains('John'));
        expect(result, contains('Doe'));
      });
    });
  });

  group('ImportValidationResult', () {
    test('should correctly identify valid result', () {
      // Arrange
      const result = ImportValidationResult(
        validMembers: [
          MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ],
        errors: [],
        warnings: [],
      );

      // Act & Assert
      expect(result.isValid, isTrue);
      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isFalse);
      expect(result.totalProcessed, equals(1));
    });

    test('should correctly identify invalid result with errors', () {
      // Arrange
      const result = ImportValidationResult(
        validMembers: [],
        errors: [
          ImportError(
            rowNumber: 1,
            error: 'Invalid email',
            type: ImportErrorType.invalidData,
          ),
        ],
        warnings: [],
      );

      // Act & Assert
      expect(result.isValid, isFalse);
      expect(result.hasErrors, isTrue);
      expect(result.hasWarnings, isFalse);
      expect(result.totalProcessed, equals(1));
    });

    test('should correctly identify result with warnings', () {
      // Arrange
      const result = ImportValidationResult(
        validMembers: [
          MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ],
        errors: [],
        warnings: [
          ImportWarning(
            rowNumber: 1,
            memberData: MemberImportData(
              email: 'john.doe@example.com',
              firstName: 'John',
              lastName: 'Doe',
            ),
            warning: 'Missing phone',
            type: ImportWarningType.missingOptionalField,
          ),
        ],
      );

      // Act & Assert
      expect(result.isValid, isTrue);
      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isTrue);
      expect(result.totalProcessed, equals(1));
    });
  });

  group('ImportError', () {
    test('should format toString correctly', () {
      // Arrange
      const error = ImportError(
        rowNumber: 5,
        error: 'Invalid email format',
        type: ImportErrorType.invalidData,
      );

      // Act
      final result = error.toString();

      // Assert
      expect(result, equals('Row 5: Invalid email format'));
    });
  });

  group('ImportWarning', () {
    test('should format toString correctly', () {
      // Arrange
      const warning = ImportWarning(
        rowNumber: 3,
        memberData: MemberImportData(
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
        ),
        warning: 'Missing phone number',
        type: ImportWarningType.missingOptionalField,
      );

      // Act
      final result = warning.toString();

      // Assert
      expect(result, equals('Row 3: Missing phone number'));
    });
  });

  group('ImportResult', () {
    test('should correctly calculate success metrics', () {
      // Arrange
      const result = ImportResult(
        totalProcessed: 10,
        successfulImports: 8,
        failedImports: 2,
        errors: [],
        createdMemberIds: ['1', '2', '3', '4', '5', '6', '7', '8'],
        processingTime: Duration(milliseconds: 1500),
      );

      // Act & Assert
      expect(result.isSuccessful, isFalse); // Has failed imports
      expect(result.hasErrors, isFalse); // No errors in list
      expect(result.successRate, equals(0.8)); // 8/10 = 0.8
    });

    test('should identify completely successful import', () {
      // Arrange
      const result = ImportResult(
        totalProcessed: 5,
        successfulImports: 5,
        failedImports: 0,
        errors: [],
        createdMemberIds: ['1', '2', '3', '4', '5'],
        processingTime: Duration(milliseconds: 1000),
      );

      // Act & Assert
      expect(result.isSuccessful, isTrue);
      expect(result.hasErrors, isFalse);
      expect(result.successRate, equals(1.0));
    });

    test('should handle zero processed items', () {
      // Arrange
      const result = ImportResult(
        totalProcessed: 0,
        successfulImports: 0,
        failedImports: 0,
        errors: [],
        createdMemberIds: [],
        processingTime: Duration(milliseconds: 100),
      );

      // Act & Assert
      expect(result.successRate, equals(0.0));
    });

    test('should format toString correctly', () {
      // Arrange
      const result = ImportResult(
        totalProcessed: 10,
        successfulImports: 8,
        failedImports: 2,
        errors: [],
        createdMemberIds: ['1', '2', '3', '4', '5', '6', '7', '8'],
        processingTime: Duration(milliseconds: 1500),
      );

      // Act
      final resultString = result.toString();

      // Assert
      expect(resultString, contains('total: 10'));
      expect(resultString, contains('successful: 8'));
      expect(resultString, contains('failed: 2'));
      expect(resultString, contains('time: 1500ms'));
    });
  });
}