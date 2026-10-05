import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

/// 设置页：外观（深浅色）+ 关于。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) {
          final mode = ThemeController.instance.mode;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _sectionTitle(theme, '外观'),
              Card(
                child: Column(
                  children: [
                    _modeTile(theme, mode, ThemeMode.system, Icons.brightness_auto_outlined,
                        '跟随系统', '跟随手机系统的深浅色设置'),
                    _modeTile(theme, mode, ThemeMode.light, Icons.light_mode_outlined,
                        '浅色', '一直使用浅色外观'),
                    _modeTile(theme, mode, ThemeMode.dark, Icons.dark_mode_outlined,
                        '深色', '一直使用深色外观'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(theme, '关于'),
              const Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('版本'),
                      trailing: Text('v1.6.0'),
                    ),
                    ListTile(
                      leading: Icon(Icons.widgets_outlined),
                      title: Text('DIY 硬件性价比助手'),
                      subtitle: Text('帮你从 CPU / 显卡到整机方案，挑出最划算的配置。'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _modeTile(
    ThemeData theme,
    ThemeMode current,
    ThemeMode value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = current == value;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      selected: selected,
      onTap: () => ThemeController.instance.setMode(value),
    );
  }
}
