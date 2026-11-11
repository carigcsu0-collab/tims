import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:tims/core/exceptions/app_exceptions.dart';

/// Interceptor that attaches the Bearer token to every authenticated request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider});

  /// Returns the current access token, or null if not authenticated.
  final String? Function() tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}

/// Interceptor that maps [DioException]s to application-specific [AppException]s.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        type: err.type,
        response: err.response,
        error: exception,
        stackTrace: err.stackTrace,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(stackTrace: err.stackTrace);
      case DioExceptionType.connectionError:
        return NetworkException(stackTrace: err.stackTrace);
      case DioExceptionType.badResponse:
        return _mapStatusCode(err);
      case DioExceptionType.cancel:
        return UnknownException(
          message: 'Request was cancelled.',
          stackTrace: err.stackTrace,
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'SSL certificate verification failed.',
          stackTrace: err.stackTrace,
        );
      case DioExceptionType.unknown:
        return UnknownException(stackTrace: err.stackTrace);
      case DioExceptionType.transformTimeout:
        return TimeoutException(stackTrace: err.stackTrace);
    }
  }

  AppException _mapStatusCode(DioException err) {
    final statusCode = err.response?.statusCode ?? 0;
    final data = err.response?.data;
    final message = _extractErrorMessage(data);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
      case 401:
        return UnauthorizedException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
      case 403:
        return ForbiddenException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
      case 404:
        return NotFoundException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
      case 422:
        return ValidationException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
      case >= 500:
        return ServerException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
      default:
        return UnknownException(
          message: message,
          details: data is Map<String, dynamic> ? data : null,
        );
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
          return firstError.toString();
        }
      }
    }
    return 'An error occurred. Please try again.';
  }
}

/// Centralized Dio HTTP client configured for the TIMS Laravel REST API.
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  /// Factory that creates an [ApiClient] with all interceptors configured.
  factory ApiClient.create({required String? Function() tokenProvider}) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8001/api/v1';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider),
      ErrorInterceptor(),
    ]);

    return ApiClient._(dio);
  }

  /// Exposes the underlying [Dio] instance for advanced use cases.
  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) =>
      _dio.post<T>(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
}
