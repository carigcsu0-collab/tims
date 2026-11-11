import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/models/dashboard_stats_model.dart';

/// State for dashboard data loading.
sealed class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.stats);
  final DashboardStatsModel stats;
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
}

/// Notifier that fetches dashboard statistics.
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._repository) : super(const DashboardInitial());

  final dynamic _repository;

  Future<void> loadStats() async {
    state = const DashboardLoading();
    final result = await _repository.getStats();
    state = result.fold(
      (failure) => DashboardError(failure.message),
      (stats) => DashboardLoaded(stats),
    );
  }
}

/// Provider for [DashboardNotifier].
final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(dashboardRepositoryProvider));
});
