/// Authentication validation service for form validation
class AuthValidationService {
  /// Validate email address format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value, {bool isSignUp = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (isSignUp) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters long';
      }
      
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
        return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
      }
    } else {
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
    }
    
    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate phone number format
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters except +
    final cleanedValue = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!cleanedValue.startsWith('+')) {
      return 'Please include country code (e.g., +1 for US)';
    }
    
    // Check minimum length (country code + at least 7 digits)
    if (cleanedValue.length < 8) {
      return 'Please enter a valid phone number';
    }
    
    // Check maximum length (E.164 format allows up to 15 digits total)
    if (cleanedValue.length > 16) {
      return 'Phone number is too long';
    }
    
    // Validate common country codes
    if (cleanedValue.startsWith('+1') && cleanedValue.length != 12) {
      return 'US/Canada numbers should be 10 digits after +1';
    }
    
    return null;
  }

  /// Validate verification code
  static String? validateVerificationCode(String? value, {int expectedLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }
    
    if (value.length != expectedLength) {
      return 'Verification code must be $expectedLength digits';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Verification code must contain only numbers';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+1') && cleaned.length >= 11) {
      // US phone number formatting: +1 (XXX) XXX-XXXX
      final digits = cleaned.substring(2);
      if (digits.length >= 10) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
      } else if (digits.length >= 6) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
      } else if (digits.length >= 3) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3)}';
      } else {
        return '+1 ($digits';
      }
    } else if (cleaned.startsWith('+') && cleaned.length > 1) {
      // International number - add spaces for readability
      final countryAndNumber = cleaned.substring(1);
      if (countryAndNumber.length <= 3) {
        return '+$countryAndNumber';
      } else if (countryAndNumber.length <= 6) {
        return '+${countryAndNumber.substring(0, 2)} ${countryAndNumber.substring(2)}';
      } else {
        return '+${countryAndNumber.substring(0, 2)} ${countryAndNumber.substring(2, 5)} ${countryAndNumber.substring(5)}';
      }
    }
    
    return cleaned.isEmpty ? phoneNumber : cleaned;
  }

  /// Check password strength level
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    // Common patterns penalty
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score--; // Repeated characters
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) score--; // Sequential numbers
    if (RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false).hasMatch(password)) score--; // Sequential letters
    
    // Ensure score is within bounds
    score = score.clamp(0, 6);
    
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
      case 3:
        return PasswordStrength.medium;
      case 4:
      case 5:
        return PasswordStrength.strong;
      case 6:
        return PasswordStrength.veryStrong;
      default:
        return PasswordStrength.weak;
    }
  }

  /// Get password strength description
  static String getPasswordStrengthDescription(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak password';
      case PasswordStrength.medium:
        return 'Medium strength';
      case PasswordStrength.strong:
        return 'Strong password';
      case PasswordStrength.veryStrong:
        return 'Very strong password';
    }
  }

  /// Get password improvement suggestions
  static List<String> getPasswordSuggestions(String password) {
    final suggestions = <String>[];
    
    if (password.length < 8) {
      suggestions.add('Use at least 8 characters');
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      suggestions.add('Include lowercase letters');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      suggestions.add('Include uppercase letters');
    }
    
    if (!RegExp(r'\d').hasMatch(password)) {
      suggestions.add('Include numbers');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      suggestions.add('Include special characters');
    }
    
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      suggestions.add('Avoid repeating characters');
    }
    
    return suggestions;
  }

  /// Validate email domain (optional - for corporate use)
  static String? validateEmailDomain(String? email, List<String>? allowedDomains) {
    if (email == null || allowedDomains == null || allowedDomains.isEmpty) {
      return null;
    }
    
    final emailValidation = validateEmail(email);
    if (emailValidation != null) return emailValidation;
    
    final domain = email.split('@').last.toLowerCase();
    
    if (!allowedDomains.any((allowedDomain) => domain == allowedDomain.toLowerCase())) {
      return 'Email domain not allowed. Please use: ${allowedDomains.join(', ')}';
    }
    
    return null;
  }

  /// Check if email is disposable/temporary
  static bool isDisposableEmail(String email) {
    final domain = email.split('@').last.toLowerCase();
    
    // Common disposable email domains
    const disposableDomains = {
      '10minutemail.com',
      'guerrillamail.com',
      'mailinator.com',
      'tempmail.org',
      'throwaway.email',
      'temp-mail.org',
      'yopmail.com',
      'maildrop.cc',
      'sharklasers.com',
      'grr.la',
    };
    
    return disposableDomains.contains(domain);
  }
}

/// Password strength levels
enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
  veryStrong,
}