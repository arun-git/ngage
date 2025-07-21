import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_handler.dart';
import 'error_types.dart';
import '../ui/widgets/error_widgets.dart';

/// Mixin to provide error handling capabilities to widgets and services
mixin ErrorHandlingMixin {
  /// Handle error with context and optional user notification
  Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
  }) async {
    await ErrorHandler().handleError(
      error,
      stackTrace,
      context: context,
      additionalData: additionalData,
      showUserMessage: showUserMessage,
    );
  }

  /// Handle async operation with error handling
  Future<T?> handleAsyncOperation<T>(
    Future<T> Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
    T? fallbackValue,
  }) async {
    return await ErrorHandler.handleAsync(
      operation,
      context: context,
      additionalData: additionalData,
      showUserMessage: showUserMessage,
      fallbackValue: fallbackValue,
    );
  }

  /// Handle sync operation with error handling
  T? handleSyncOperation<T>(
    T Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
    T? fallbackValue,
  }) {
    return ErrorHandler.handleSync(
      operation,
      context: context,
      additionalData: additionalData,
      showUserMessage: showUserMessage,
      fallbackValue: fallbackValue,
    );
  }
}

/// Mixin for widgets that need error handling capabilities
mixin WidgetErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Show error snackbar
  void showErrorSnackBar(
    Object error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    if (mounted) {
      ErrorSnackBar.show(
        context,
        error,
        duration: duration,
        onRetry: onRetry,
      );
    }
  }

  /// Show error dialog
  void showErrorDialog(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    VoidCallback? onRetry,
  }) {
    if (mounted) {
      showDialog(
        context: this.context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: ErrorDisplayWidget(
            error: error,
            stackTrace: stackTrace,
            context: context,
            onRetry: onRetry,
            showReportButton: true,
            showDetails: false,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  /// Handle error with UI feedback
  Future<void> handleErrorWithUI(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showSnackBar = true,
    VoidCallback? onRetry,
  }) async {
    // Handle the error
    await ErrorHandler().handleError(
      error,
      stackTrace,
      context: context,
      additionalData: additionalData,
      showUserMessage: false, // We'll show our own UI
    );

    // Show UI feedback
    if (showSnackBar && mounted) {
      showErrorSnackBar(error, onRetry: onRetry);
    }
  }
}

/// Mixin for ConsumerWidget error handling
mixin ConsumerWidgetErrorHandlingMixin {
  /// Show error snackbar in ConsumerWidget
  void showErrorSnackBar(
    BuildContext context,
    Object error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    ErrorSnackBar.show(
      context,
      error,
      duration: duration,
      onRetry: onRetry,
    );
  }

  /// Handle async operation with UI feedback in ConsumerWidget
  Future<T?> handleAsyncWithUI<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? operationContext,
    Map<String, dynamic>? additionalData,
    bool showSnackBar = true,
    T? fallbackValue,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      // Handle the error
      await ErrorHandler().handleError(
        error,
        stackTrace,
        context: operationContext,
        additionalData: additionalData,
        showUserMessage: false,
      );

      // Show UI feedback
      if (showSnackBar) {
        showErrorSnackBar(context, error, onRetry: onRetry);
      }

      return fallbackValue;
    }
  }
}

/// Extension on WidgetRef for error handling
extension WidgetRefErrorHandling on WidgetRef {
  /// Handle error with context
  Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    final errorHandler = read(errorHandlerProvider);
    await errorHandler.handleError(
      error,
      stackTrace,
      context: context,
      additionalData: additionalData,
    );
  }

  /// Handle async operation with error handling
  Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    T? fallbackValue,
  }) async {
    return await ErrorHandler.handleAsync(
      operation,
      context: context,
      additionalData: additionalData,
      fallbackValue: fallbackValue,
    );
  }
}

/// Utility class for common error handling patterns
class ErrorHandlingUtils {
  /// Wrap a Future with error handling
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
    T? fallbackValue,
  }) async {
    return await ErrorHandler.handleAsync(
      operation,
      context: context,
      additionalData: additionalData,
      showUserMessage: showUserMessage,
      fallbackValue: fallbackValue,
    );
  }

  /// Wrap a synchronous operation with error handling
  static T? wrapSync<T>(
    T Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
    T? fallbackValue,
  }) {
    return ErrorHandler.handleSync(
      operation,
      context: context,
      additionalData: additionalData,
      showUserMessage: showUserMessage,
      fallbackValue: fallbackValue,
    );
  }

  /// Create a safe callback that handles errors
  static VoidCallback safeCallback(
    VoidCallback callback, {
    String? context,
    VoidCallback? onError,
  }) {
    return () {
      try {
        callback();
      } catch (error, stackTrace) {
        ErrorHandler().handleError(
          error,
          stackTrace,
          context: context,
        );
        onError?.call();
      }
    };
  }

  /// Create a safe async callback that handles errors
  static Future<void> Function() safeAsyncCallback(
    Future<void> Function() callback, {
    String? context,
    VoidCallback? onError,
  }) {
    return () async {
      try {
        await callback();
      } catch (error, stackTrace) {
        await ErrorHandler().handleError(
          error,
          stackTrace,
          context: context,
        );
        onError?.call();
      }
    };
  }

  /// Validate and throw appropriate exceptions
  static void validateRequired(dynamic value, String fieldName) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      throw ValidationException(
        'Field $fieldName is required',
        field: fieldName,
        userMessage: 'Please provide a value for $fieldName',
      );
    }
  }

  /// Validate email format
  static void validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      throw ValidationException(
        'Email is required',
        field: 'email',
        userMessage: 'Please provide an email address',
      );
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw ValidationException(
        'Invalid email format',
        field: 'email',
        userMessage: 'Please provide a valid email address',
      );
    }
  }

  /// Validate phone number format
  static void validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return; // Phone is optional in most cases
    }

    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      throw ValidationException(
        'Invalid phone number format',
        field: 'phone',
        userMessage: 'Please provide a valid phone number',
      );
    }
  }

  /// Validate string length
  static void validateLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null) return;

    if (minLength != null && value.length < minLength) {
      throw ValidationException(
        '$fieldName must be at least $minLength characters',
        field: fieldName,
        userMessage: '$fieldName must be at least $minLength characters long',
      );
    }

    if (maxLength != null && value.length > maxLength) {
      throw ValidationException(
        '$fieldName must be no more than $maxLength characters',
        field: fieldName,
        userMessage: '$fieldName must be no more than $maxLength characters long',
      );
    }
  }
}