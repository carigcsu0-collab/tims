import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/models/paginated_response.dart';
import 'package:tims/core/repositories/base_repository.dart';

/// Generic CRUD repository implementation for any model [T].
class CrudRepository<T> with RepositoryErrorHandler {
  CrudRepository({
    required ApiClient apiClient,
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
  })  : _api = apiClient,
        _endpoint = endpoint,
        _fromJson = fromJson;

  final ApiClient _api;
  final String _endpoint;
  final T Function(Map<String, dynamic>) _fromJson;

  /// Fetches a paginated list with optional search and filters.
  Future<Result<PaginatedResponse<T>>> getPaginated({
    int page = 1,
    int perPage = 15,
    String? search,
    Map<String, dynamic>? filters,
  }) =>
      guard(() async {
        final queryParams = <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (filters != null) ...filters,
        };
        final response = await _api.get(_endpoint, queryParameters: queryParams);
        return PaginatedResponse<T>.fromJson(
          response.data as Map<String, dynamic>,
          _fromJson,
        );
      });

  /// Fetches all resources (non-paginated, use with caution for large datasets).
  Future<Result<List<T>>> getAll({
    String? search,
    Map<String, dynamic>? filters,
  }) =>
      guard(() async {
        final queryParams = <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          if (filters != null) ...filters,
        };
        final response = await _api.get(_endpoint, queryParameters: queryParams);
        final data = response.data;
        if (data is List) {
          return data
              .map((e) => _fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Handle paginated response format
        final paginated = PaginatedResponse<T>.fromJson(
          data as Map<String, dynamic>,
          _fromJson,
        );
        return paginated.data;
      });

  /// Fetches a single resource by [id].
  Future<Result<T>> getById(int id) =>
      guard(() async {
        final response = await _api.get('$_endpoint/$id');
        final data = response.data as Map<String, dynamic>;
        // Handle wrapped response: { "data": { ... } }
        final modelData = data.containsKey('data') && data['data'] is Map
            ? data['data'] as Map<String, dynamic>
            : data;
        return _fromJson(modelData);
      });

  /// Creates a new resource.
  Future<Result<T>> create(Map<String, dynamic> data) =>
      guard(() async {
        final response = await _api.post(_endpoint, data: data);
        final responseData = response.data as Map<String, dynamic>;
        final modelData = responseData.containsKey('data') &&
                responseData['data'] is Map
            ? responseData['data'] as Map<String, dynamic>
            : responseData;
        return _fromJson(modelData);
      });

  /// Updates an existing resource by [id].
  Future<Result<T>> update(int id, Map<String, dynamic> data) =>
      guard(() async {
        final response = await _api.put('$_endpoint/$id', data: data);
        final responseData = response.data as Map<String, dynamic>;
        final modelData = responseData.containsKey('data') &&
                responseData['data'] is Map
            ? responseData['data'] as Map<String, dynamic>
            : responseData;
        return _fromJson(modelData);
      });

  /// Deletes a resource by [id].
  Future<Result<bool>> delete(int id) =>
      guard(() async {
        await _api.delete('$_endpoint/$id');
        return true;
      });
}
