import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';

sealed class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.settings);
  final Map<String, dynamic> settings;
}

class SettingsError extends SettingsState {
  const SettingsError(this.message);
  final String message;
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._apiClient) : super(const SettingsInitial());

  final dynamic _apiClient;

  Future<void> load() async {
    state = const SettingsLoading();
    try {
      final response = await _apiClient.get(ApiEndpoints.settings);
      state = SettingsLoaded(response.data as Map<String, dynamic>);
    } on Exception catch (e) {
      state = SettingsError(e.toString());
    }
  }

  Future<void> update(Map<String, dynamic> data) async {
    try {
      await _apiClient.put(ApiEndpoints.settings, data: data);
      await load();
    } on Exception catch (e) {
      state = SettingsError(e.toString());
    }
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(apiClientProvider));
});
