import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/bulk_import.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';

/// Service for bulk member import operations
abstract class BulkImportService {
  /// Parse CSV file and return member import data
  Future<List<MemberImportData>> parseCsvFile(Uint8List fileBytes, {String? fileName});
  
  /// Validate import data for format and duplicates
  Future<ImportValidationResult> validateImportData(List<MemberImportData> importData);
  
  /// Import members with batch processing and error handling
  Future<ImportResult> importMembers(
    List<MemberImportData> importData, {
    ImportProgressCallback? onProgress,
    int batchSize = 50,
  });
  
  /// Get expected CSV headers
  List<String> getExpectedHeaders();
  
  /// Get sample CSV data for template
  String getSampleCsvData();
}

/// Implementation of bulk import service
class BulkImportServiceImpl implements BulkImportService {
  final MemberRepository _memberRepository;
  
  BulkImportServiceImpl({
    required MemberRepository memberRepository,
  }) : _memberRepository = memberRepository;

  @override
  Future<List<MemberImportData>> parseCsvFile(Uint8List fileBytes, {String? fileName}) async {
    try {
      // Convert bytes to string
      final csvString = utf8.decode(fileBytes);
      
      // Parse CSV
      final csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }
      
      // Get headers from first row
      final headers = csvData.first.map((e) => e.toString().toLowerCase().trim()).toList();
      
      // Validate required headers
      _validateHeaders(headers);
      
      // Convert rows to MemberImportData
      final importData = <MemberImportData>[];
      
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        
        // Skip empty rows
        if (row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }
        
        // Create map from headers and row data
        final rowMap = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowMap[headers[j]] = row[j];
        }
        
        try {
          final memberData = MemberImportData.fromCsvRow(rowMap);
          importData.add(memberData);
        } catch (e) {
          throw Exception('Error parsing row ${i + 1}: $e');
        }
      }
      
      return importData;
    } catch (e) {
      throw Exception('Failed to parse CSV file: $e');
    }
  }

  @override
  Future<ImportValidationResult> validateImportData(List<MemberImportData> importData) async {
    final validMembers = <MemberImportData>[];
    final errors = <ImportError>[];
    final warnings = <ImportWarning>[];
    
    // Track emails and phones for duplicate detection within file
    final emailsInFile = <String, int>{};
    final phonesInFile = <String, int>{};
    
    // Get existing members from database for duplicate checking
    final existingMembers = await _memberRepository.getAllMembers();
    final existingEmails = existingMembers.map((m) => m.email.toLowerCase()).toSet();
    final existingPhones = existingMembers
        .where((m) => m.phone != null)
        .map((m) => m.phone!.toLowerCase())
        .toSet();
    
    for (int i = 0; i < importData.length; i++) {
      final rowNumber = i + 1;
      final memberData = importData[i];
      
      try {
        // Validate individual member data
        final validation = memberData.validate();
        if (!validation.isValid) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            memberData: memberData,
            error: validation.errors.join(', '),
            type: ImportErrorType.invalidData,
          ));
          continue;
        }
        
        // Check for duplicates within the file
        final emailLower = memberData.email.toLowerCase();
        if (emailsInFile.containsKey(emailLower)) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            memberData: memberData,
            error: 'Duplicate email in file (first seen at row ${emailsInFile[emailLower]})',
            type: ImportErrorType.duplicateInFile,
          ));
          continue;
        }
        emailsInFile[emailLower] = rowNumber;
        
        if (memberData.phone != null) {
          final phoneLower = memberData.phone!.toLowerCase();
          if (phonesInFile.containsKey(phoneLower)) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              memberData: memberData,
              error: 'Duplicate phone in file (first seen at row ${phonesInFile[phoneLower]})',
              type: ImportErrorType.duplicateInFile,
            ));
            continue;
          }
          phonesInFile[phoneLower] = rowNumber;
        }
        
        // Check for duplicates in database
        if (existingEmails.contains(emailLower)) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            memberData: memberData,
            error: 'Email already exists in database',
            type: ImportErrorType.duplicateInDatabase,
          ));
          continue;
        }
        
        if (memberData.phone != null && existingPhones.contains(memberData.phone!.toLowerCase())) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            memberData: memberData,
            error: 'Phone number already exists in database',
            type: ImportErrorType.duplicateInDatabase,
          ));
          continue;
        }
        
        // Add warnings for missing optional fields
        if (memberData.phone == null) {
          warnings.add(ImportWarning(
            rowNumber: rowNumber,
            memberData: memberData,
            warning: 'Phone number not provided',
            type: ImportWarningType.missingOptionalField,
          ));
        }
        
        if (memberData.category == null) {
          warnings.add(ImportWarning(
            rowNumber: rowNumber,
            memberData: memberData,
            warning: 'Category not provided',
            type: ImportWarningType.missingOptionalField,
          ));
        }
        
        if (memberData.title == null) {
          warnings.add(ImportWarning(
            rowNumber: rowNumber,
            memberData: memberData,
            warning: 'Title not provided',
            type: ImportWarningType.missingOptionalField,
          ));
        }
        
        // Member is valid
        validMembers.add(memberData);
        
      } catch (e) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          memberData: memberData,
          error: 'Validation error: $e',
          type: ImportErrorType.invalidData,
        ));
      }
    }
    
    return ImportValidationResult(
      validMembers: validMembers,
      errors: errors,
      warnings: warnings,
    );
  }

  @override
  Future<ImportResult> importMembers(
    List<MemberImportData> importData, {
    ImportProgressCallback? onProgress,
    int batchSize = 50,
  }) async {
    final stopwatch = Stopwatch()..start();
    final errors = <ImportError>[];
    final createdMemberIds = <String>[];
    int successfulImports = 0;
    int failedImports = 0;
    
    try {
      // Process in batches
      for (int i = 0; i < importData.length; i += batchSize) {
        final batch = importData.skip(i).take(batchSize).toList();
        
        onProgress?.call(i, importData.length, 'Processing batch ${(i ~/ batchSize) + 1}');
        
        // Process batch
        final batchResult = await _processBatch(batch, i);
        
        successfulImports += batchResult.successfulImports;
        failedImports += batchResult.failedImports;
        errors.addAll(batchResult.errors);
        createdMemberIds.addAll(batchResult.createdMemberIds);
      }
      
      onProgress?.call(importData.length, importData.length, 'Import completed');
      
    } catch (e) {
      // Handle batch processing errors
      for (int i = successfulImports + failedImports; i < importData.length; i++) {
        errors.add(ImportError(
          rowNumber: i + 1,
          memberData: importData[i],
          error: 'Batch processing failed: $e',
          type: ImportErrorType.invalidData,
        ));
        failedImports++;
      }
    }
    
    stopwatch.stop();
    
    return ImportResult(
      totalProcessed: importData.length,
      successfulImports: successfulImports,
      failedImports: failedImports,
      errors: errors,
      createdMemberIds: createdMemberIds,
      processingTime: stopwatch.elapsed,
    );
  }

  @override
  List<String> getExpectedHeaders() {
    return [
      'email',
      'first_name',
      'last_name',
      'phone',
      'external_id',
      'category',
      'title',
    ];
  }

  @override
  String getSampleCsvData() {
    final headers = getExpectedHeaders();
    final sampleRows = [
      ['john.doe@example.com', 'John', 'Doe', '+1234567890', 'EMP001', 'Engineering', 'Software Engineer'],
      ['jane.smith@example.com', 'Jane', 'Smith', '+1234567891', 'EMP002', 'Marketing', 'Marketing Manager'],
      ['bob.wilson@example.com', 'Bob', 'Wilson', '', 'EMP003', 'Sales', 'Sales Representative'],
    ];
    
    final csvData = [headers, ...sampleRows];
    return const ListToCsvConverter().convert(csvData);
  }

  /// Validate CSV headers
  void _validateHeaders(List<String> headers) {
    final requiredHeaders = ['email', 'first_name', 'last_name'];
    final missingHeaders = <String>[];
    
    for (final required in requiredHeaders) {
      if (!headers.any((h) => h.toLowerCase() == required.toLowerCase())) {
        missingHeaders.add(required);
      }
    }
    
    if (missingHeaders.isNotEmpty) {
      throw Exception('Missing required headers: ${missingHeaders.join(', ')}');
    }
  }

  /// Process a batch of import data
  Future<ImportResult> _processBatch(List<MemberImportData> batch, int startIndex) async {
    final errors = <ImportError>[];
    final createdMemberIds = <String>[];
    int successfulImports = 0;
    int failedImports = 0;
    
    for (int i = 0; i < batch.length; i++) {
      final rowNumber = startIndex + i + 1;
      final importData = batch[i];
      
      try {
        // Create member from import data
        final now = DateTime.now();
        final member = Member(
          id: '', // Will be generated by repository
          userId: null, // Unclaimed initially
          email: importData.email,
          phone: importData.phone,
          externalId: importData.externalId,
          firstName: importData.firstName,
          lastName: importData.lastName,
          category: importData.category,
          title: importData.title,
          isActive: true,
          importedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        
        // Create member in repository
        final createdMember = await _memberRepository.createMember(member);
        createdMemberIds.add(createdMember.id);
        successfulImports++;
        
      } catch (e) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          memberData: importData,
          error: 'Failed to create member: $e',
          type: ImportErrorType.invalidData,
        ));
        failedImports++;
      }
    }
    
    return ImportResult(
      totalProcessed: batch.length,
      successfulImports: successfulImports,
      failedImports: failedImports,
      errors: errors,
      createdMemberIds: createdMemberIds,
      processingTime: Duration.zero, // Not used for batch results
    );
  }
}

// Provider moved to bulk_import_providers.dart to avoid duplication