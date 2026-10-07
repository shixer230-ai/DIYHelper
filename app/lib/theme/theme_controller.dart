import 'package:flutter/material.dart';

import '../storage/avatar_image_store.dart';
import '../storage/background_image_store.dart';
import '../storage/settings_store.dart';
import 'app_theme.dart';

/// 全局外观状态：主题模式、主题色、自定义背景。单例，变更后通知监听者重建 MaterialApp。
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final _store = SettingsStore();
  ThemeMode _mode = ThemeMode.system;
  Color _seed = kDefaultSeed;
  String? _backgroundPath;
  String? _avatarPath;
  bool _backgroundBlur = false;
  String _nickname = SettingsStore.defaultNickname;

  ThemeMode get mode => _mode;
  Color get seed => _seed;
  String? get backgroundPath => _backgroundPath;
  bool get backgroundBlur => _backgroundBlur;
  bool get hasBackground => _backgroundPath != null;
  String? get avatarPath => _avatarPath;
  String get nickname => _nickname;

  /// 启动时从本地读取外观偏好。
  Future<void> init() async {
    _mode = await _store.loadThemeMode();
    _seed = await _store.loadSeed();
    _backgroundBlur = await _store.loadBackgroundBlur();
    _backgroundPath = await BackgroundImageStore.storedImagePath();
    _avatarPath = await AvatarImageStore.storedImagePath();
    _nickname = await _store.loadNickname();
  }

  /// 切换深浅色：更新内存 → 通知重建 → 落盘。
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode);
  }

  /// 切换主题色。
  Future<void> setSeed(Color seed) async {
    if (_seed.toARGB32() == seed.toARGB32()) return;
    _seed = seed;
    notifyListeners();
    await _store.saveSeed(seed);
  }

  /// 设置背景图（图片已由 BackgroundImageStore 存到本地，路径即持久化）。
  Future<void> setBackground(String path) async {
    _backgroundPath = path;
    notifyListeners();
  }

  /// 移除背景图。
  Future<void> clearBackground() async {
    await BackgroundImageStore.delete();
    _backgroundPath = null;
    notifyListeners();
  }

  /// 背景是否模糊。
  Future<void> setBackgroundBlur(bool blur) async {
    if (_backgroundBlur == blur) return;
    _backgroundBlur = blur;
    notifyListeners();
    await _store.saveBackgroundBlur(blur);
  }

  /// 修改昵称。
  Future<void> setNickname(String nickname) async {
    if (_nickname == nickname) return;
    _nickname = nickname;
    notifyListeners();
    await _store.saveNickname(nickname);
  }

  /// 登录/注册成功后：若本地昵称仍是默认值，则采用云端用户名。
  /// 用户手动改过昵称则不覆盖，保留用户自己的选择。
  Future<void> adoptNicknameIfDefault(String name) async {
    if (_nickname != SettingsStore.defaultNickname) return;
    await setNickname(name);
  }

  /// 设置头像（图片已由 AvatarImageStore 存到本地，路径即持久化）。
  Future<void> setAvatar(String path) async {
    _avatarPath = path;
    notifyListeners();
  }

  /// 移除头像，恢复默认人形图标。
  Future<void> clearAvatar() async {
    await AvatarImageStore.delete();
    _avatarPath = null;
    notifyListeners();
  }
}
