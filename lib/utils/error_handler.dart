import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';
import 'error_types.dart';
import 'error_recovery.dart';

/// Centralized error handler for the Ngage platform
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Logger _logger = Logger();
  final ErrorRecovery _recovery = ErrorRecovery();
  
  /// Global error handler for uncaught exceptions
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorHandler()._handleFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorHandler()._handlePlatformError(error, stack);
      return true;
    };
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final error = details.exception;
    final stack = details.stack;
    
    _logger.error(
      'Flutter Error',
      error: error,
      stackTrace: stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handle platform-level errors
  void _handlePlatformError(Object error, StackTrace stack) {
    _logger.error(
      'Platform Error',
      error: error,
      stackTrace: stack,
    );
  }

  /// Handle application errors with context
  Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
  }) async {
    final errorType = _categorizeError(error);
    final userMessage = _getUserFriendlyMessage(error, errorType);
    
    // Log the error
    _logger.error(
      context ?? 'Application Error',
      error: error,
      stackTrace: stackTrace,
      context: {
        'errorType': errorType.toString(),
        'userMessage': userMessage,
        ...?additionalData,
      },
    );

    // Attempt recovery if possible
    final recovered = await _recovery.attemptRecovery(error, errorType);
    
    if (!recovered && showUserMessage) {
      _showUserError(userMessage, errorType);
    }
  }

  /// Categorize error types for appropriate handling
  ErrorType _categorizeError(Object error) {
    if (error is AuthenticationException) {
      return ErrorType.authentication;
    } else if (error is AuthorizationException) {
      return ErrorType.authorization;
    } else if (error is ValidationException) {
      return ErrorType.validation;
    } else if (error is NetworkException) {
      return ErrorType.network;
    } else if (error is StorageException) {
      return ErrorType.storage;
    } else if (error is DatabaseException) {
      return ErrorType.database;
    } else if (error is FileException) {
      return ErrorType.file;
    } else if (error is IntegrationException) {
      return ErrorType.integration;
    } else if (error is RateLimitException) {
      return ErrorType.rateLimit;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Generate user-friendly error messages
  String _getUserFriendlyMessage(Object error, ErrorType errorType) {
    if (error is NgageException) {
      return error.userMessage ?? _getDefaultMessage(errorType);
    }
    
    return _getDefaultMessage(errorType);
  }

  /// Get default user-friendly messages for error types
  String _getDefaultMessage(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.authentication:
        return 'Authentication failed. Please check your credentials and try again.';
      case ErrorType.authorization:
        return 'You don\'t have permission to perform this action.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.network:
        return 'Network connection failed. Please check your internet connection.';
      case ErrorType.storage:
        return 'File storage error. Please try again later.';
      case ErrorType.database:
        return 'Database error. Please try again later.';
      case ErrorType.file:
        return 'File operation failed. Please check the file and try again.';
      case ErrorType.integration:
        return 'External service integration failed. Please try again later.';
      case ErrorType.rateLimit:
        return 'Too many requests. Please wait a moment and try again.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again later.';
    }
  }

  /// Show error message to user
  void _showUserError(String message, ErrorType errorType) {
    // This will be implemented by the UI layer
    // For now, we'll use a simple notification mechanism
    _notifyError(message, errorType);
  }

  /// Notify error through the application's notification system
  void _notifyError(String message, ErrorType errorType) {
    // This would integrate with the notification service
    // For now, we'll log it as a user-facing error
    _logger.info('User Error Notification: $message');
  }

  /// Handle async operations with error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await ErrorHandler().handleError(
        error,
        stackTrace,
        context: context,
        additionalData: additionalData,
        showUserMessage: showUserMessage,
      );
      return fallbackValue;
    }
  }

  /// Handle sync operations with error handling
  static T? handleSync<T>(
    T Function() operation, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      ErrorHandler().handleError(
        error,
        stackTrace,
        context: context,
        additionalData: additionalData,
        showUserMessage: showUserMessage,
      );
      return fallbackValue;
    }
  }
}

/// Provider for error handler
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});