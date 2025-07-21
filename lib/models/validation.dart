/// Validation utilities for data models
/// 
/// This file contains common validation functions used across all models
/// to ensure data integrity and consistency.

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  ValidationResult.valid() : this(isValid: true);
  
  ValidationResult.invalid(List<String> errors) 
      : this(isValid: false, errors: errors);

  ValidationResult.singleError(String error) 
      : this(isValid: false, errors: [error]);
}

class Validators {
  /// Email validation using a simple but effective regex
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    return emailRegex.hasMatch(email);
  }

  /// Phone number validation (international format)
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    
    // Remove all non-digit characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check for international format (+1234567890) or domestic (1234567890)
    final phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
    
    return phoneRegex.hasMatch(cleanPhone);
  }

  /// Check if string is not null and not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Check if string meets minimum length requirement
  static bool hasMinLength(String? value, int minLength) {
    return value != null && value.length >= minLength;
  }

  /// Check if string doesn't exceed maximum length
  static bool hasMaxLength(String? value, int maxLength) {
    return value == null || value.length <= maxLength;
  }

  /// Validate name fields (first name, last name, etc.)
  static ValidationResult validateName(String? name, String fieldName) {
    final errors = <String>[];
    
    if (!isNotEmpty(name)) {
      errors.add('$fieldName is required');
    } else if (!hasMinLength(name, 1)) {
      errors.add('$fieldName must be at least 1 character long');
    } else if (!hasMaxLength(name, 50)) {
      errors.add('$fieldName must not exceed 50 characters');
    }
    
    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors);
  }

  /// Validate email field
  static ValidationResult validateEmail(String? email) {
    final errors = <String>[];
    
    if (!isNotEmpty(email)) {
      errors.add('Email is required');
    } else if (!isValidEmail(email!)) {
      errors.add('Please enter a valid email address');
    }
    
    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors);
  }

  /// Validate optional email field
  static ValidationResult validateOptionalEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.valid();
    }
    
    return isValidEmail(email) 
        ? ValidationResult.valid()
        : ValidationResult.singleError('Please enter a valid email address');
  }

  /// Validate phone field
  static ValidationResult validatePhone(String? phone) {
    final errors = <String>[];
    
    if (!isNotEmpty(phone)) {
      errors.add('Phone number is required');
    } else if (!isValidPhone(phone!)) {
      errors.add('Please enter a valid phone number');
    }
    
    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors);
  }

  /// Validate optional phone field
  static ValidationResult validateOptionalPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.valid();
    }
    
    return isValidPhone(phone) 
        ? ValidationResult.valid()
        : ValidationResult.singleError('Please enter a valid phone number');
  }

  /// Validate description fields
  static ValidationResult validateDescription(String? description, {int maxLength = 500}) {
    if (description == null || description.trim().isEmpty) {
      return ValidationResult.valid(); // Optional field
    }
    
    return hasMaxLength(description, maxLength)
        ? ValidationResult.valid()
        : ValidationResult.singleError('Description must not exceed $maxLength characters');
  }

  /// Validate required ID fields
  static ValidationResult validateId(String? id, String fieldName) {
    return isNotEmpty(id)
        ? ValidationResult.valid()
        : ValidationResult.singleError('$fieldName is required');
  }

  /// Validate required fields (generic)
  static ValidationResult validateRequired(String? value, String fieldName) {
    return isNotEmpty(value)
        ? ValidationResult.valid()
        : ValidationResult.singleError('$fieldName is required');
  }

  /// Validate non-empty fields
  static ValidationResult validateNonEmpty(String? value, String fieldName) {
    return isNotEmpty(value)
        ? ValidationResult.valid()
        : ValidationResult.singleError('$fieldName cannot be empty');
  }

  /// Validate date fields
  static ValidationResult validateDate(DateTime? date, String fieldName) {
    return date != null
        ? ValidationResult.valid()
        : ValidationResult.singleError('$fieldName is required');
  }

  /// Validate that end date is after start date
  static ValidationResult validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return ValidationResult.valid(); // Individual validation will catch null dates
    }
    
    return endDate.isAfter(startDate)
        ? ValidationResult.valid()
        : ValidationResult.singleError('End date must be after start date');
  }

  /// Combine multiple validation results
  static ValidationResult combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    
    for (final result in results) {
      if (!result.isValid) {
        allErrors.addAll(result.errors);
      }
    }
    
    return allErrors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(allErrors);
  }
}