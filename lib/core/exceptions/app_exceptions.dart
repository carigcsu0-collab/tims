/// Base exception class for all application-specific exceptions.
sealed class AppException implements Exception {
  AppException({
    required this.message,
    this.code,
    this.details,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a network request fails due to connectivity issues.
class NetworkException extends AppException {
  NetworkException({
    super.message = 'Network connection failed. Please check your internet connection.',
    super.code = 'NETWORK_ERROR',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when the server returns an error response (4xx, 5xx).
class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code = 'SERVER_ERROR',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when authentication fails (401).
class UnauthorizedException extends AppException {
  UnauthorizedException({
    super.message = 'Authentication required. Please log in.',
    super.code = 'UNAUTHORIZED',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when the user lacks permissions for an action (403).
class ForbiddenException extends AppException {
  ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'FORBIDDEN',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when a requested resource is not found (404).
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when a request times out.
class TimeoutException extends AppException {
  TimeoutException({
    super.message = 'The request timed out. Please try again.',
    super.code = 'TIMEOUT',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when form validation fails.
class ValidationException extends AppException {
  ValidationException({
    super.message = 'Validation failed.',
    super.code = 'VALIDATION_ERROR',
    super.details,
    super.stackTrace,
  });
}

/// Thrown when a cache read/write operation fails.
class CacheException extends AppException {
  CacheException({
    super.message = 'Cache operation failed.',
    super.code = 'CACHE_ERROR',
    super.details,
    super.stackTrace,
  });
}

/// Thrown for any unexpected errors not covered by the above.
class UnknownException extends AppException {
  UnknownException({
    super.message = 'An unexpected error occurred.',
    super.code = 'UNKNOWN_ERROR',
    super.details,
    super.stackTrace,
  });
}
