import 'package:shared_preferences/shared_preferences.dart';

/// Preferences service for non-sensitive app settings using [SharedPreferences].
class PreferencesService {
  PreferencesService._(this._prefs);

  final SharedPreferences _prefs;

  /// Initializes a [PreferencesService] instance.
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  // Theme
  static const String _keyThemeMode = 'theme_mode';

  Future<void> setThemeMode(String mode) =>
      _prefs.setString(_keyThemeMode, mode);

  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';

  // Locale
  static const String _keyLocale = 'locale';

  Future<void> setLocale(String locale) =>
      _prefs.setString(_keyLocale, locale);

  String? getLocale() => _prefs.getString(_keyLocale);

  // First launch
  static const String _keyFirstLaunch = 'first_launch';

  bool isFirstLaunch() => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> setFirstLaunchDone() =>
      _prefs.setBool(_keyFirstLaunch, false);

  // Sidebar collapsed (desktop)
  static const String _keySidebarCollapsed = 'sidebar_collapsed';

  bool isSidebarCollapsed() => _prefs.getBool(_keySidebarCollapsed) ?? false;

  Future<void> setSidebarCollapsed(bool collapsed) =>
      _prefs.setBool(_keySidebarCollapsed, collapsed);

  // Last selected nav index
  static const String _keyLastNavIndex = 'last_nav_index';

  int getLastNavIndex() => _prefs.getInt(_keyLastNavIndex) ?? 0;

  Future<void> setLastNavIndex(int index) =>
      _prefs.setInt(_keyLastNavIndex, index);
}
