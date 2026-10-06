import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../app_info.dart';
import '../storage/background_image_store.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// 「我的」页：个人信息 + 自定义背景 + 主题色 + 外观（深浅色）+ 关于。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pickBackground(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2160,
      maxHeight: 2160,
    );
    if (file == null) return;
    final path = await BackgroundImageStore.saveImage(file);
    if (!context.mounted) return;
    await ThemeController.instance.setBackground(path);
  }

  Future<void> _editNickname(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) =>
          _NicknameDialog(initial: ThemeController.instance.nickname),
    );
    if (result == null) return;
    await ThemeController.instance.setNickname(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) {
          final theme = Theme.of(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomNavClearance(context)),
            children: [
              _header(theme, context),
              const SizedBox(height: 16),
              _sectionTitle(theme, '背景'),
              _backgroundCard(theme, context),
              const SizedBox(height: 16),
              _sectionTitle(theme, '主题色'),
              _seedCard(theme),
              const SizedBox(height: 16),
              _sectionTitle(theme, '外观'),
              _appearanceCard(theme),
              const SizedBox(height: 16),
              _sectionTitle(theme, '关于'),
              _aboutCard(context, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _header(ThemeData theme, BuildContext context) {
    final nickname = ThemeController.instance.nickname;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editNickname(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  LucideIcons.user_round,
                  size: 30,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '点击修改昵称',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backgroundCard(ThemeData theme, BuildContext context) {
    final c = ThemeController.instance;
    final path = c.backgroundPath;
    final hasBg = path != null;
    return Card(
      child: Column(
        children: [
          if (hasBg)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: Text(hasBg ? '更换背景图片' : '上传背景图片'),
            subtitle: Text(hasBg ? '已设置背景，点此更换' : '从手机相册选一张图片'),
            onTap: () => _pickBackground(context),
          ),
          if (hasBg)
            ListTile(
              leading: const Icon(LucideIcons.image_off),
              title: const Text('移除背景'),
              onTap: () => ThemeController.instance.clearBackground(),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.blur_on),
            title: const Text('背景模糊'),
            subtitle: const Text('让背景变柔、文字更清晰'),
            value: c.backgroundBlur,
            onChanged: hasBg
                ? (v) => ThemeController.instance.setBackgroundBlur(v)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _seedCard(ThemeData theme) {
    final current = ThemeController.instance.seed.toARGB32();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                for (final option in kSeedOptions)
                  _swatch(theme, option, current == option.color.toARGB32()),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ThemeController.instance.setSeed(kDefaultSeed),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('恢复默认主题色'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(ThemeData theme, SeedOption option, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ThemeController.instance.setSeed(option.color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: option.color,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(height: 4),
          Text(option.name, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _appearanceCard(ThemeData theme) {
    final mode = ThemeController.instance.mode;
    return Card(
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
    );
  }

  Widget _aboutCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: Text(kAppVersion),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('版本更新日志'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVersionLog(context),
          ),
          const ListTile(
            leading: Icon(Icons.widgets_outlined),
            title: Text('DIY 硬件性价比助手'),
            subtitle: Text('帮你从 CPU / 显卡到整机方案，挑出最划算的配置。'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '© $kCredit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVersionLog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版本更新日志'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in kVersionLog) ...[
                Text(
                  entry.version,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                for (final item in entry.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 4),
                    child: Text('· $item'),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
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

/// 修改昵称的对话框，返回非空昵称。
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.initial});

  final String initial;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改昵称'),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(labelText: '昵称'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
}
