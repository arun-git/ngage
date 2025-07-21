import 'validation.dart';

/// Data class for member import from CSV/Excel
class MemberImportData {
  final String email;
  final String? phone;
  final String? externalId;
  final String firstName;
  final String lastName;
  final String? category;
  final String? title;

  const MemberImportData({
    required this.email,
    this.phone,
    this.externalId,
    required this.firstName,
    required this.lastName,
    this.category,
    this.title,
  });

  /// Create from CSV row data
  factory MemberImportData.fromCsvRow(Map<String, dynamic> row) {
    return MemberImportData(
      email: _getStringValue(row, 'email') ?? '',
      phone: _getStringValue(row, 'phone'),
      externalId: _getStringValue(row, 'external_id') ?? _getStringValue(row, 'externalId'),
      firstName: _getStringValue(row, 'first_name') ?? _getStringValue(row, 'firstName') ?? '',
      lastName: _getStringValue(row, 'last_name') ?? _getStringValue(row, 'lastName') ?? '',
      category: _getStringValue(row, 'category'),
      title: _getStringValue(row, 'title'),
    );
  }

  /// Helper to get string value from row with case-insensitive key matching
  static String? _getStringValue(Map<String, dynamic> row, String key) {
    // Try exact match first
    if (row.containsKey(key)) {
      final value = row[key];
      return value?.toString().trim().isEmpty == true ? null : value?.toString().trim();
    }
    
    // Try case-insensitive match
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        final value = entry.value;
        return value?.toString().trim().isEmpty == true ? null : value?.toString().trim();
      }
    }
    
    return null;
  }

  /// Validate import data
  ValidationResult validate() {
    final results = [
      Validators.validateEmail(email),
      Validators.validateOptionalPhone(phone),
      Validators.validateName(firstName, 'First name'),
      Validators.validateName(lastName, 'Last name'),
      Validators.validateDescription(category, maxLength: 100),
      Validators.validateDescription(title, maxLength: 100),
    ];

    return Validators.combine(results);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'externalId': externalId,
      'firstName': firstName,
      'lastName': lastName,
      'category': category,
      'title': title,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MemberImportData &&
        other.email == email &&
        other.phone == phone &&
        other.externalId == externalId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.category == category &&
        other.title == title;
  }

  @override
  int get hashCode {
    return Object.hash(
      email,
      phone,
      externalId,
      firstName,
      lastName,
      category,
      title,
    );
  }

  @override
  String toString() {
    return 'MemberImportData(email: $email, firstName: $firstName, lastName: $lastName)';
  }
}

/// Result of import validation
class ImportValidationResult {
  final List<MemberImportData> validMembers;
  final List<ImportError> errors;
  final List<ImportWarning> warnings;

  const ImportValidationResult({
    required this.validMembers,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isValid => !hasErrors;
  int get totalProcessed => validMembers.length + errors.length;
}

/// Import error with row information
class ImportError {
  final int rowNumber;
  final MemberImportData? memberData;
  final String error;
  final ImportErrorType type;

  const ImportError({
    required this.rowNumber,
    this.memberData,
    required this.error,
    required this.type,
  });

  @override
  String toString() {
    return 'Row $rowNumber: $error';
  }
}

/// Import warning with row information
class ImportWarning {
  final int rowNumber;
  final MemberImportData memberData;
  final String warning;
  final ImportWarningType type;

  const ImportWarning({
    required this.rowNumber,
    required this.memberData,
    required this.warning,
    required this.type,
  });

  @override
  String toString() {
    return 'Row $rowNumber: $warning';
  }
}

/// Types of import errors
enum ImportErrorType {
  invalidData,
  duplicateInFile,
  duplicateInDatabase,
  missingRequiredField,
  invalidFormat,
}

/// Types of import warnings
enum ImportWarningType {
  missingOptionalField,
  dataFormatting,
  potentialDuplicate,
}

/// Result of bulk import operation
class ImportResult {
  final int totalProcessed;
  final int successfulImports;
  final int failedImports;
  final List<ImportError> errors;
  final List<String> createdMemberIds;
  final Duration processingTime;

  const ImportResult({
    required this.totalProcessed,
    required this.successfulImports,
    required this.failedImports,
    required this.errors,
    required this.createdMemberIds,
    required this.processingTime,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => failedImports == 0;
  double get successRate => totalProcessed > 0 ? successfulImports / totalProcessed : 0.0;

  @override
  String toString() {
    return 'ImportResult(total: $totalProcessed, successful: $successfulImports, failed: $failedImports, time: ${processingTime.inMilliseconds}ms)';
  }
}

/// Progress callback for import operations
typedef ImportProgressCallback = void Function(int processed, int total, String currentOperation);