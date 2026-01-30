import 'package:shared_preferences/shared_preferences.dart';

/// Repository for background scan settings
class BackgroundScanSettingsRepository {
  static const String _enabledKey = 'background_scan_enabled';
  static const String _lastScanTimeKey = 'background_scan_last_time';
  static const String _scanCountKey = 'background_scan_count';

  /// Get if background scan is enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Set background scan enabled state
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Get last scan time
  Future<DateTime?> getLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastScanTimeKey);
    if (timeString == null) return null;
    return DateTime.parse(timeString);
  }

  /// Set last scan time
  Future<void> setLastScanTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScanTimeKey, time.toIso8601String());
  }

  /// Get total scan count
  Future<int> getScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scanCountKey) ?? 0;
  }

  /// Increment scan count
  Future<void> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_scanCountKey) ?? 0;
    await prefs.setInt(_scanCountKey, current + 1);
  }
}
