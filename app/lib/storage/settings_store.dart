import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 保存「设置」里的外观偏好（目前只有主题模式）。
class SettingsStore {
  static const _themeModeKey = 'theme_mode';

  /// 主题模式 → 存储字符串。
  static String themeModeToName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// 存储字符串 → 主题模式（无记录或非法值都回落到「跟随系统」）。
  static ThemeMode themeModeFromName(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return themeModeFromName(prefs.getString(_themeModeKey));
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeModeToName(mode));
  }
}
