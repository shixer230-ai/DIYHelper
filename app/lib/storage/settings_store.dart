import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// 保存「我的」页的个性化偏好：主题模式、主题色、背景模糊
class SettingsStore {
  static const _themeModeKey = 'theme_mode';
  static const _themeSeedKey = 'theme_seed';
  static const _backgroundBlurKey = 'background_blur';
  static const _nicknameKey = 'nickname';

  /// 默认昵称（用户未自定义时显示）
  static const String defaultNickname = 'DIY 硬件性价比助手';

  /// 主题模式 → 存储字符串
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

  /// 存储字符串 → 主题模式（无记录或非法值回落「跟随系统」）
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

  /// 读取主题色（无记录默认玫瑰粉）
  Future<Color> loadSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_themeSeedKey);
    return v == null ? kDefaultSeed : Color(v);
  }

  Future<void> saveSeed(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeSeedKey, color.toARGB32());
  }

  /// 背景是否模糊（无记录默认不模糊）
  Future<bool> loadBackgroundBlur() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundBlurKey) ?? false;
  }

  Future<void> saveBackgroundBlur(bool blur) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundBlurKey, blur);
  }

  /// 读取昵称（无记录用默认）
  Future<String> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey) ?? defaultNickname;
  }

  Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname);
  }
}
