import 'dart:async';
import 'error_types.dart';
import 'logger.dart';

/// Error recovery strategies for different types of errors
class ErrorRecovery {
  final Logger _logger = Logger();
  final Map<ErrorType, int> _retryAttempts = {};
  final Map<ErrorType, DateTime> _lastRetryTime = {};
  
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Attempt to recover from an error
  Future<bool> attemptRecovery(Object error, ErrorType errorType) async {
    try {
      switch (errorType) {
        case ErrorType.network:
          return await _recoverFromNetworkError(error);
        case ErrorType.authentication:
          return await _recoverFromAuthError(error);
        case ErrorType.database:
          return await _recoverFromDatabaseError(error);
        case ErrorType.storage:
          return await _recoverFromStorageError(error);
        case ErrorType.rateLimit:
          return await _recoverFromRateLimitError(error);
        default:
          return false;
      }
    } catch (e) {
      _logger.warning('Error recovery failed', error: e);
      return false;
    }
  }

  /// Recover from network errors with retry logic
  Future<bool> _recoverFromNetworkError(Object error) async {
    final attempts = _retryAttempts[ErrorType.network] ?? 0;
    
    if (attempts >= maxRetryAttempts) {
      _logger.info('Max retry attempts reached for network error');
      return false;
    }

    final lastRetry = _lastRetryTime[ErrorType.network];
    if (lastRetry != null && 
        DateTime.now().difference(lastRetry) < retryDelay) {
      return false;
    }

    _retryAttempts[ErrorType.network] = attempts + 1;
    _lastRetryTime[ErrorType.network] = DateTime.now();

    // Wait before retry
    await Future.delayed(retryDelay);
    
    _logger.info('Attempting network error recovery, attempt ${attempts + 1}');
    
    // Network recovery would involve checking connectivity
    // and potentially refreshing tokens or connections
    return true;
  }

  /// Recover from authentication errors
  Future<bool> _recoverFromAuthError(Object error) async {
    _logger.info('Attempting authentication error recovery');
    
    // Authentication recovery might involve:
    // - Refreshing tokens
    // - Re-authenticating silently
    // - Redirecting to login
    
    return false; // Usually requires user intervention
  }

  /// Recover from database errors
  Future<bool> _recoverFromDatabaseError(Object error) async {
    final attempts = _retryAttempts[ErrorType.database] ?? 0;
    
    if (attempts >= maxRetryAttempts) {
      return false;
    }

    _retryAttempts[ErrorType.database] = attempts + 1;
    _lastRetryTime[ErrorType.database] = DateTime.now();

    await Future.delayed(retryDelay);
    
    _logger.info('Attempting database error recovery, attempt ${attempts + 1}');
    
    // Database recovery might involve:
    // - Retrying the operation
    // - Using cached data
    // - Switching to offline mode
    
    return true;
  }

  /// Recover from storage errors
  Future<bool> _recoverFromStorageError(Object error) async {
    _logger.info('Attempting storage error recovery');
    
    // Storage recovery might involve:
    // - Clearing cache
    // - Retrying upload/download
    // - Using alternative storage
    
    return false;
  }

  /// Recover from rate limit errors
  Future<bool> _recoverFromRateLimitError(Object error) async {
    _logger.info('Attempting rate limit error recovery');
    
    Duration waitTime = const Duration(minutes: 1);
    
    if (error is RateLimitException && error.retryAfter != null) {
      waitTime = error.retryAfter!;
    }

    _logger.info('Waiting ${waitTime.inSeconds} seconds before retry');
    await Future.delayed(waitTime);
    
    return true;
  }

  /// Reset retry attempts for a specific error type
  void resetRetryAttempts(ErrorType errorType) {
    _retryAttempts.remove(errorType);
    _lastRetryTime.remove(errorType);
  }

  /// Reset all retry attempts
  void resetAllRetryAttempts() {
    _retryAttempts.clear();
    _lastRetryTime.clear();
  }

  /// Get current retry attempt count for an error type
  int getRetryAttempts(ErrorType errorType) {
    return _retryAttempts[errorType] ?? 0;
  }

  /// Check if recovery is available for an error type
  bool canRecover(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.database:
      case ErrorType.rateLimit:
        return true;
      default:
        return false;
    }
  }
}