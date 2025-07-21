import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/bulk_import.dart';
import 'package:ngage/models/member.dart';
import 'package:ngage/repositories/member_repository.dart';
import 'package:ngage/services/bulk_import_service.dart';

// Generate mocks
@GenerateMocks([MemberRepository])
import 'bulk_import_service_test.mocks.dart';

void main() {
  group('BulkImportService', () {
    late BulkImportService bulkImportService;
    late MockMemberRepository mockMemberRepository;

    setUp(() {
      mockMemberRepository = MockMemberRepository();
      bulkImportService = BulkImportServiceImpl(
        memberRepository: mockMemberRepository,
      );
    });

    group('parseCsvFile', () {
      test('should parse valid CSV file successfully', () async {
        // Arrange
        const csvContent = '''email,first_name,last_name,phone,external_id,category,title
john.doe@example.com,John,Doe,+1234567890,EMP001,Engineering,Software Engineer
jane.smith@example.com,Jane,Smith,+1234567891,EMP002,Marketing,Marketing Manager''';
        
        final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

        // Act
        final result = await bulkImportService.parseCsvFile(csvBytes);

        // Assert
        expect(result, hasLength(2));
        
        expect(result[0].email, equals('john.doe@example.com'));
        expect(result[0].firstName, equals('John'));
        expect(result[0].lastName, equals('Doe'));
        expect(result[0].phone, equals('+1234567890'));
        expect(result[0].externalId, equals('EMP001'));
        expect(result[0].category, equals('Engineering'));
        expect(result[0].title, equals('Software Engineer'));
        
        expect(result[1].email, equals('jane.smith@example.com'));
        expect(result[1].firstName, equals('Jane'));
        expect(result[1].lastName, equals('Smith'));
      });

      test('should handle CSV with missing optional fields', () async {
        // Arrange
        const csvContent = '''email,first_name,last_name
john.doe@example.com,John,Doe
jane.smith@example.com,Jane,Smith''';
        
        final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

        // Act
        final result = await bulkImportService.parseCsvFile(csvBytes);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].phone, isNull);
        expect(result[0].externalId, isNull);
        expect(result[0].category, isNull);
        expect(result[0].title, isNull);
      });

      test('should handle case-insensitive headers', () async {
        // Arrange
        const csvContent = '''EMAIL,First_Name,Last_Name,PHONE
john.doe@example.com,John,Doe,+1234567890''';
        
        final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

        // Act
        final result = await bulkImportService.parseCsvFile(csvBytes);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].email, equals('john.doe@example.com'));
        expect(result[0].firstName, equals('John'));
        expect(result[0].lastName, equals('Doe'));
        expect(result[0].phone, equals('+1234567890'));
      });

      test('should skip empty rows', () async {
        // Arrange
        const csvContent = '''email,first_name,last_name
john.doe@example.com,John,Doe
,,
jane.smith@example.com,Jane,Smith''';
        
        final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

        // Act
        final result = await bulkImportService.parseCsvFile(csvBytes);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].email, equals('john.doe@example.com'));
        expect(result[1].email, equals('jane.smith@example.com'));
      });

      test('should throw exception for empty CSV file', () async {
        // Arrange
        final csvBytes = Uint8List.fromList(utf8.encode(''));

        // Act & Assert
        expect(
          () => bulkImportService.parseCsvFile(csvBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('CSV file is empty'),
          )),
        );
      });

      test('should throw exception for missing required headers', () async {
        // Arrange
        const csvContent = '''name,phone
John Doe,+1234567890''';
        
        final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

        // Act & Assert
        expect(
          () => bulkImportService.parseCsvFile(csvBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Missing required headers'),
          )),
        );
      });
    });

    group('validateImportData', () {
      test('should validate data successfully with no errors', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
            phone: '+1234567890',
          ),
          const MemberImportData(
            email: 'jane.smith@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
            phone: '+1234567891',
          ),
        ];

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => []);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.validMembers, hasLength(2));
        expect(result.errors, isEmpty);
        expect(result.warnings, hasLength(4)); // Missing category and title for both
      });

      test('should detect duplicate emails within file', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ];

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => []);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.validMembers, hasLength(1));
        expect(result.errors, hasLength(1));
        expect(result.errors[0].type, equals(ImportErrorType.duplicateInFile));
        expect(result.errors[0].error, contains('Duplicate email in file'));
      });

      test('should detect duplicate phones within file', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
            phone: '+1234567890',
          ),
          const MemberImportData(
            email: 'jane.smith@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
            phone: '+1234567890',
          ),
        ];

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => []);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.validMembers, hasLength(1));
        expect(result.errors, hasLength(1));
        expect(result.errors[0].type, equals(ImportErrorType.duplicateInFile));
        expect(result.errors[0].error, contains('Duplicate phone in file'));
      });

      test('should detect duplicate emails in database', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ];

        final existingMember = Member(
          id: '1',
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => [existingMember]);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.validMembers, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors[0].type, equals(ImportErrorType.duplicateInDatabase));
        expect(result.errors[0].error, contains('Email already exists in database'));
      });

      test('should detect invalid email format', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'invalid-email',
            firstName: 'John',
            lastName: 'Doe',
          ),
        ];

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => []);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.validMembers, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors[0].type, equals(ImportErrorType.invalidData));
        expect(result.errors[0].error, contains('valid email address'));
      });

      test('should detect invalid phone format', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
            phone: 'invalid-phone',
          ),
        ];

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => []);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.validMembers, isEmpty);
        expect(result.errors, hasLength(1));
        expect(result.errors[0].type, equals(ImportErrorType.invalidData));
        expect(result.errors[0].error, contains('valid phone number'));
      });

      test('should generate warnings for missing optional fields', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
            // Missing phone, category, title
          ),
        ];

        when(mockMemberRepository.getAllMembers())
            .thenAnswer((_) async => []);

        // Act
        final result = await bulkImportService.validateImportData(importData);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.validMembers, hasLength(1));
        expect(result.warnings, hasLength(3)); // phone, category, title
        expect(result.warnings.any((w) => w.warning.contains('Phone number not provided')), isTrue);
        expect(result.warnings.any((w) => w.warning.contains('Category not provided')), isTrue);
        expect(result.warnings.any((w) => w.warning.contains('Title not provided')), isTrue);
      });
    });

    group('importMembers', () {
      test('should import members successfully', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
          const MemberImportData(
            email: 'jane.smith@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
          ),
        ];

        final createdMember1 = Member(
          id: '1',
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdMember2 = Member(
          id: '2',
          email: 'jane.smith@example.com',
          firstName: 'Jane',
          lastName: 'Smith',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

//TODO
       // when(mockMemberRepository.createMember(any))
       //     .thenAnswer((_) async => createdMember1)
       //     .thenAnswer((_) async => createdMember2);

        // Act
        final result = await bulkImportService.importMembers(importData);

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.totalProcessed, equals(2));
        expect(result.successfulImports, equals(2));
        expect(result.failedImports, equals(0));
        expect(result.errors, isEmpty);
        expect(result.createdMemberIds, hasLength(2));
        verify(mockMemberRepository.createMember(any)).called(2);
      });

      test('should handle import failures gracefully', () async {
        // Arrange
        final importData = [
          const MemberImportData(
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          ),
          const MemberImportData(
            email: 'jane.smith@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
          ),
        ];

        final createdMember = Member(
          id: '1',
          email: 'john.doe@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        //TODO
       // when(mockMemberRepository.createMember(any))
      //      .thenAnswer((_) async => createdMember)
       //     .thenThrow(Exception('Database error'));

        // Act
        final result = await bulkImportService.importMembers(importData);

        // Assert
        expect(result.isSuccessful, isFalse);
        expect(result.totalProcessed, equals(2));
        expect(result.successfulImports, equals(1));
        expect(result.failedImports, equals(1));
        expect(result.errors, hasLength(1));
        expect(result.errors[0].error, contains('Failed to create member'));
        expect(result.createdMemberIds, hasLength(1));
      });

      test('should process in batches', () async {
        // Arrange
        final importData = List.generate(5, (i) => MemberImportData(
          email: 'user$i@example.com',
          firstName: 'User',
          lastName: '$i',
        ));

        when(mockMemberRepository.createMember(any))
            .thenAnswer((_) async => Member(
              id: 'id',
              email: 'email',
              firstName: 'firstName',
              lastName: 'lastName',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));

        var progressCallCount = 0;
        void onProgress(int processed, int total, String operation) {
          progressCallCount++;
        }

        // Act
        final result = await bulkImportService.importMembers(
          importData,
          onProgress: onProgress,
          batchSize: 2,
        );

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.totalProcessed, equals(5));
        expect(result.successfulImports, equals(5));
        expect(progressCallCount, greaterThan(0)); // Progress callback was called
        verify(mockMemberRepository.createMember(any)).called(5);
      });
    });

    group('getExpectedHeaders', () {
      test('should return correct headers', () {
        // Act
        final headers = bulkImportService.getExpectedHeaders();

        // Assert
        expect(headers, contains('email'));
        expect(headers, contains('first_name'));
        expect(headers, contains('last_name'));
        expect(headers, contains('phone'));
        expect(headers, contains('external_id'));
        expect(headers, contains('category'));
        expect(headers, contains('title'));
      });
    });

    group('getSampleCsvData', () {
      test('should return valid CSV sample data', () {
        // Act
        final csvData = bulkImportService.getSampleCsvData();

        // Assert
        expect(csvData, isNotEmpty);
        expect(csvData, contains('email'));
        expect(csvData, contains('first_name'));
        expect(csvData, contains('last_name'));
        expect(csvData, contains('john.doe@example.com'));
        expect(csvData, contains('jane.smith@example.com'));
      });
    });
  });
}