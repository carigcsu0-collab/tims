import 'package:tims/core/exceptions/app_exceptions.dart';
import 'package:tims/core/exceptions/failure.dart';

/// Abstract base class for all repositories, providing common CRUD operations.
///
/// [T] is the model type, [E] is the ID type (typically int or String).
abstract class BaseRepository<T> {
  /// Fetches a paginated list of resources.
  Future<Result<List<T>>> getList({
    int page = 1,
    int perPage = 15,
    String? search,
    Map<String, dynamic>? filters,
  });

  /// Fetches a single resource by its [id].
  Future<Result<T>> getById(int id);

  /// Creates a new resource.
  Future<Result<T>> create(Map<String, dynamic> data);

  /// Updates an existing resource by its [id].
  Future<Result<T>> update(int id, Map<String, dynamic> data);

  /// Deletes a resource by its [id].
  Future<Result<bool>> delete(int id);
}

/// Mixin providing safe execution of API calls, converting exceptions to [Failure]s.
mixin RepositoryErrorHandler {
  /// Wraps an async operation, catching [AppException]s and returning [Result].
  Future<Result<T>> guard<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return ResultUtils.success(result);
    } on AppException catch (e) {
      return ResultUtils.fromException(e);
    } catch (e, stackTrace) {
      return ResultUtils.fromException(
        UnknownException(
          message: e.toString(),
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
