import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../app_info.dart';
import '../cloud/auth_service.dart';
import '../cloud/cloud_sync.dart';
import '../models/build_plan.dart';
import '../storage/avatar_image_store.dart';
import '../storage/background_image_store.dart';
import '../storage/build_plan_store.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../utils/category_icons.dart';
import 'account_page.dart';
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
    // 已登录则自动把新头像上传到云（尽力而为，不打断本地流程）。
    if (!context.mounted) return;
    if (AuthService.instance.isLoggedIn) _uploadAvatar(context);
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
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) {
            final theme = Theme.of(context);
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: false,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  title: const Text('我的'),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    12 + bottomNavClearance(context),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _accountCard(context, theme),
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
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 顶部卡片：头像 + 昵称 + 账号与云同步（登录/注册、上传头像、退出登录）合并为一块。
  Widget _accountCard(BuildContext context, ThemeData theme) {
    final nickname = ThemeController.instance.nickname;
    final avatarPath = ThemeController.instance.avatarPath;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 头像 + 昵称
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _avatar(theme, context, avatarPath),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _editNickname(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '点击修改昵称',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
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
          const Divider(height: 1),
          // 账号与云同步区域
          ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) {
              final auth = AuthService.instance;
              if (!auth.isLoggedIn) {
                return ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('登录 / 注册'),
                  subtitle: const Text('登录后把整机方案同步到云端'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountPage()),
                  ),
                );
              }
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('账号已登录'),
                    subtitle: Text(auth.username ?? ''),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('退出登录'),
                    onTap: () => AuthService.instance.signOut(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 把本地头像图片上传到云存储并存入账号资料。
  Future<void> _uploadAvatar(BuildContext context) async {
    final path = ThemeController.instance.avatarPath;
    if (path == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('还没有头像，先点头像从相册选一张')));
      return;
    }
    try {
      final bytes = await File(path).readAsBytes();
      final ext = path.contains('.') ? path.split('.').last : 'jpg';
      await CloudSync.uploadAvatar(bytes, ext);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('头像已上传到云')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
              child: const Icon(
                Icons.camera_alt,
                size: 12,
                color: Colors.white,
              ),
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
          _modeTile(
            theme,
            mode,
            ThemeMode.system,
            Icons.brightness_auto_outlined,
            '跟随系统',
            '跟随手机系统的深浅色设置',
          ),
          _modeTile(
            theme,
            mode,
            ThemeMode.light,
            Icons.light_mode_outlined,
            '浅色',
            '一直使用浅色外观',
          ),
          _modeTile(
            theme,
            mode,
            ThemeMode.dark,
            Icons.dark_mode_outlined,
            '深色',
            '一直使用深色外观',
          ),
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
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入配置单'),
            subtitle: const Text('粘贴「导出配置单」生成的文本，一键还原成方案'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _importConfig(context),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('还没有整机方案，先去「整机方案」页创建一个')));
      return;
    }
    final plan = await showModalBottomSheet<BuildPlan>(
      context: context,
      builder: (_) => _ExportSheet(plans: plans),
    );
    if (plan == null || !context.mounted) return;
    final name = _planName(plan);
    await SharePlus.instance.share(
      ShareParams(text: configText(plan), subject: '$name 配置单'),
    );
  }

  /// 一键导入配置单：读取剪贴板里的配置单文本（可手动粘贴修改），
  /// 解析后还原成一个新的整机方案，与「导出配置单」的格式保持一致。
  Future<void> _importConfig(BuildContext context) async {
    String initial = '';
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      initial = data?.text ?? '';
    } catch (_) {
      // 剪贴板读取失败就留空，让用户手动粘贴。
    }
    if (!context.mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _ImportDialog(initialText: initial),
    );
    if (text == null || !context.mounted) return;
    final parsed = parseConfig(text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没识别到配置单内容，请粘贴「导出配置单」生成的文本')),
      );
      return;
    }
    final store = BuildPlanStore();
    final plans = await store.loadAll();
    // 与已有方案重名时追加序号，避免列表里混淆。
    var name = parsed.name;
    var n = 2;
    while (plans.any((p) => p.name == name)) {
      name = '${parsed.name} $n';
      n++;
    }
    final plan = BuildPlan(name: name, components: parsed.components);
    plans.add(plan);
    await store.saveAll(plans);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已导入「$name」')));
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
            subtitle: Text('帮你从 CPU / 显卡到整机方案，挑出最划算的配置'),
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
    // 不再用弹窗，直接进入一个整页展示，阅读更舒服。
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _VersionLogPage()),
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

/// 版本更新日志整页：按版本分组展示，最新在前。
class _VersionLogPage extends StatelessWidget {
  const _VersionLogPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('版本更新日志')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in kVersionLog) ...[
            Text(
              entry.version,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in entry.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
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
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

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
        FilledButton(
          onPressed: _submit,
          style: capsuleButtonStyle(Theme.of(context), fullWidth: false),
          child: const Text('确定'),
        ),
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

String _planName(BuildPlan plan) => plan.name.isEmpty ? '未命名方案' : plan.name;

String _fmt(double p) =>
    p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

/// 把单个整机方案排版成纯文本配置单。
String configText(BuildPlan plan) {
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

/// 解析「导出配置单」生成的文本，还原成整机方案；识别不到任何配件时返回 null。
/// 格式与 [configText] 保持一致：方案名从头部读取，配件行按槽位标签 + 型号 + 品牌 + 价格解析。
BuildPlan? parseConfig(String text) {
  final lines = text.split('\n').map((e) => e.trim()).toList();

  String name = '';
  const marker = '【DIYHelper 配置单】';
  for (final l in lines) {
    final i = l.indexOf(marker);
    if (i >= 0) {
      name = l.substring(i + marker.length).trim();
      break;
    }
  }
  if (name.isEmpty) name = '导入的方案';

  final components = <String, PlanComponent>{};
  for (final slot in kBuildSlots) {
    for (final l in lines) {
      final prefix = '${slot.label} ';
      if (!l.startsWith(prefix)) continue;
      final rest = l.substring(prefix.length).trim();
      if (rest.isEmpty) break;

      final yen = rest.lastIndexOf('¥');
      var modelBrand = rest;
      var price = 0.0;
      if (yen >= 0) {
        price = double.tryParse(rest.substring(yen + 1).trim()) ?? 0;
        modelBrand = rest.substring(0, yen).trim();
      }
      final parts = modelBrand.split('·');
      final model = parts.first.trim();
      final brand = parts.length > 1 ? parts[1].trim() : '';
      if (model.isEmpty) break;

      components[slot.key] = PlanComponent(
        category: slot.category,
        brand: brand,
        model: model,
        price: price,
        platform: '',
      );
      break;
    }
  }

  if (components.isEmpty) return null;
  return BuildPlan(name: name, components: components);
}

/// 粘贴配置单文本的对话框；打开时自动填充剪贴板内容。
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.initialText});

  final String initialText;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initialText,
  );

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
      title: const Text('导入配置单'),
      content: TextField(
        controller: _c,
        minLines: 6,
        maxLines: 10,
        decoration: const InputDecoration(
          labelText: '配置单文本',
          hintText: '自动读取剪贴板，也可长按粘贴',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          style: capsuleButtonStyle(Theme.of(context), fullWidth: false),
          child: const Text('导入'),
        ),
      ],
    );
  }
}
