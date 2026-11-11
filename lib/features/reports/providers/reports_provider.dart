import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';

sealed class ReportsState {
  const ReportsState();
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  const ReportsLoaded(this.data, {this.reportType});
  final Map<String, dynamic> data;
  final String? reportType;
}

class ReportsError extends ReportsState {
  const ReportsError(this.message, {this.reportType});
  final String message;
  final String? reportType;
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier(this._apiClient) : super(const ReportsInitial());

  final dynamic _apiClient;

  Future<void> generateReport(String type, {Map<String, dynamic>? params}) async {
    state = const ReportsLoading();
    try {
      final endpoint = switch (type) {
        'inventory' => ApiEndpoints.reportsInventory,
        'procurement' => ApiEndpoints.reportsProcurement,
        'borrowing' => ApiEndpoints.reportsBorrowing,
        'maintenance' => ApiEndpoints.reportsMaintenance,
        'audit' => ApiEndpoints.reportsAudit,
        'stock_movement' => ApiEndpoints.reportsStockMovement,
        _ => ApiEndpoints.reports,
      };
      final response = await _apiClient.get(endpoint, queryParameters: params);
      state = ReportsLoaded(response.data as Map<String, dynamic>, reportType: type);
    } on Exception catch (e) {
      state = ReportsError(e.toString(), reportType: type);
    }
  }
}

final reportsNotifierProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref.watch(apiClientProvider));
});
