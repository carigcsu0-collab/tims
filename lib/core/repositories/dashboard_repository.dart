import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/models/dashboard_stats_model.dart';
import 'package:tims/core/repositories/base_repository.dart';

/// Repository for dashboard data.
class DashboardRepository with RepositoryErrorHandler {
  DashboardRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Fetches aggregate dashboard statistics.
  Future<Result<DashboardStatsModel>> getStats() =>
      guard(() async {
        final response = await _api.get(ApiEndpoints.dashboardStats);
        return DashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
      });

  /// Fetches chart data for the dashboard.
  Future<Result<Map<String, dynamic>>> getCharts() =>
      guard(() async {
        final response = await _api.get(ApiEndpoints.dashboardCharts);
        return response.data as Map<String, dynamic>;
      });

  /// Fetches recent activity for the dashboard.
  Future<Result<List<Map<String, dynamic>>>> getRecentActivity() =>
      guard(() async {
        final response = await _api.get(ApiEndpoints.dashboardRecentActivity);
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      });
}
