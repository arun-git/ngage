/// Error types for categorizing different kinds of errors in the Ngage platform
enum ErrorType {
  authentication,
  authorization,
  validation,
  network,
  storage,
  database,
  file,
  integration,
  rateLimit,
  unknown,
}

/// Base exception class for Ngage platform
abstract class NgageException implements Exception {
  final String message;
  final String? userMessage;
  final String? code;
  final Map<String, dynamic>? context;

  const NgageException(
    this.message, {
    this.userMessage,
    this.code,
    this.context,
  });

  @override
  String toString() => 'NgageException: $message';
}

/// Authentication related exceptions
class AuthenticationException extends NgageException {
  const AuthenticationException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
  });
}

/// Authorization related exceptions
class AuthorizationException extends NgageException {
  const AuthorizationException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
  });
}

/// Validation related exceptions
class ValidationException extends NgageException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
    this.fieldErrors,
  });
}

/// Network related exceptions
class NetworkException extends NgageException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
    this.statusCode,
  });
}

/// Storage related exceptions
class StorageException extends NgageException {
  const StorageException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
  });
}

/// Database related exceptions
class DatabaseException extends NgageException {
  const DatabaseException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
  });
}

/// File operation related exceptions
class FileException extends NgageException {
  const FileException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
  });
}

/// External integration related exceptions
class IntegrationException extends NgageException {
  final String? service;

  const IntegrationException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
    this.service,
  });
}

/// Rate limiting related exceptions
class RateLimitException extends NgageException {
  final Duration? retryAfter;

  const RateLimitException(
    super.message, {
    super.userMessage,
    super.code,
    super.context,
    this.retryAfter,
  });
}