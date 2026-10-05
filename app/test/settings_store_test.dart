import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diy_helper/storage/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('无记录时默认跟随系统', () async {
    final store = SettingsStore();
    expect(await store.loadThemeMode(), ThemeMode.system);
  });

  test('保存并读取主题模式', () async {
    final store = SettingsStore();
    await store.saveThemeMode(ThemeMode.dark);
    expect(await store.loadThemeMode(), ThemeMode.dark);
    await store.saveThemeMode(ThemeMode.light);
    expect(await store.loadThemeMode(), ThemeMode.light);
  });

  test('主题模式与字符串映射', () {
    expect(SettingsStore.themeModeToName(ThemeMode.system), 'system');
    expect(SettingsStore.themeModeToName(ThemeMode.light), 'light');
    expect(SettingsStore.themeModeToName(ThemeMode.dark), 'dark');
    expect(SettingsStore.themeModeFromName(null), ThemeMode.system);
    expect(SettingsStore.themeModeFromName('dark'), ThemeMode.dark);
    expect(SettingsStore.themeModeFromName('bad'), ThemeMode.system);
  });
}
