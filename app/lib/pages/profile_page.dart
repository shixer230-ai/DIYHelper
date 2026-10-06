import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../app_info.dart';
import '../models/build_plan.dart';
import '../storage/avatar_image_store.dart';
import '../storage/background_image_store.dart';
import '../storage/build_plan_store.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../utils/category_icons.dart';
import 'build_plan_page.dart' show kBuildSlots;

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

  Future<void> _pickAvatar(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) return;
    final path = await AvatarImageStore.saveImage(file);
    if (!context.mounted) return;
    await ThemeController.instance.setAvatar(path);
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
              _sectionTitle(theme, '工具'),
              _toolsCard(theme, context),
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
    final avatarPath = ThemeController.instance.avatarPath;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _avatar(theme, context, avatarPath),
            const SizedBox(width: 14),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _editNickname(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
              ),
            ),
            const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 头像：有自定义图片则显示图片，否则显示默认人形图标；点击更换，右下角相机小标提示。
  Widget _avatar(ThemeData theme, BuildContext context, String? path) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _pickAvatar(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: path == null ? null : FileImage(File(path)),
            child: path == null
                ? Icon(
                    LucideIcons.user_round,
                    size: 30,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
            ),
          ),
        ],
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
      customBorder: const CircleBorder(),
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
              shape: BoxShape.circle,
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

  Widget _toolsCard(ThemeData theme, BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('导出配置单'),
            subtitle: const Text('把整机方案生成文本，分享到微信 / 备忘录等'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportConfig(context),
          ),
        ],
      ),
    );
  }

  /// 一键导出配置单：列出所有整机方案，选一个后用系统分享面板分享。
  Future<void> _exportConfig(BuildContext context) async {
    final plans = await BuildPlanStore().loadAll();
    if (!context.mounted) return;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有整机方案，先去「整机方案」页创建一个')),
      );
      return;
    }
    final plan = await showModalBottomSheet<BuildPlan>(
      context: context,
      builder: (_) => _ExportSheet(plans: plans),
    );
    if (plan == null || !context.mounted) return;
    final name = _planName(plan);
    await SharePlus.instance.share(
      ShareParams(text: _configText(plan), subject: '$name 配置单'),
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

/// 选择要导出的方案。
class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.plans});

  final List<BuildPlan> plans;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择要导出的方案',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final plan in plans)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CategoryBadge(category: '整机方案'),
                      title: Text(_planName(plan)),
                      subtitle: Text(
                        '${plan.filledCount} 件 · ¥${_fmt(plan.total)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, plan),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _planName(BuildPlan plan) =>
    plan.name.isEmpty ? '未命名方案' : plan.name;

String _fmt(double p) =>
    p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

/// 把单个整机方案排版成纯文本配置单。
String _configText(BuildPlan plan) {
  final buf = StringBuffer();
  buf.writeln('【DIYHelper 配置单】${_planName(plan)}');
  buf.writeln('──────────────');
  for (final slot in kBuildSlots) {
    final c = plan[slot.key];
    if (c == null) continue;
    final brand = c.brand.isEmpty ? '' : ' · ${c.brand}';
    buf.writeln('${slot.label}  ${c.model}$brand  ¥${_fmt(c.price)}');
  }
  buf.writeln('──────────────');
  buf.writeln('总价：¥${_fmt(plan.total)}');
  buf.writeln('—— 来自 DIYHelper ——');
  return buf.toString();
}
