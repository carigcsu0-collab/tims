import 'package:dartz/dartz.dart';

import 'package:tims/core/exceptions/app_exceptions.dart';

/// Type alias for a function that converts a value of type [T] into a [Failure].
typedef FailureMapper<T> = Failure Function(T error);

/// Represents a failure in the application, wrapping an [AppException].
class Failure {
  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  factory Failure.fromException(AppException e) => Failure(
        message: e.message,
        code: e.code,
        details: e.details,
      );

  @override
  String toString() => 'Failure($code): $message';
}

/// Generic result type for operations that can fail.
/// Wraps [Either<Failure, T>] for ergonomic error handling.
typedef Result<T> = Either<Failure, T>;

/// Utility for constructing [Result] values.
class ResultUtils {
  ResultUtils._();

  static Result<T> success<T>(T value) => Right<Failure, T>(value);

  static Result<T> failure<T>(Failure failure) => Left<Failure, T>(failure);

  static Result<T> fromException<T>(AppException e) =>
      Left<Failure, T>(Failure.fromException(e));
}
