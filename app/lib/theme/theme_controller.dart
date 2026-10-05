import 'package:flutter/material.dart';

import '../storage/settings_store.dart';

/// 全局主题状态：单例，切换主题后通知监听者重建 MaterialApp。
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final _store = SettingsStore();
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// 启动时从本地读取一次主题偏好。
  Future<void> init() async {
    _mode = await _store.loadThemeMode();
  }

  /// 切换主题：更新内存 → 通知重建 → 落盘。
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode);
  }
}
