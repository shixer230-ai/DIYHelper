import 'package:flutter/material.dart';

import '../data/hardware_catalog.dart';
import '../models/build_plan.dart';
import '../models/hardware_item.dart';
import '../models/hardware_spec.dart';
import '../storage/hardware_store.dart';
import '../storage/user_spec_store.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';

/// 为整机方案某个槽位选择配件：可从硬件库选、从清单里选，或手动填价格。
/// 返回 `(是否清空, 配件)`；null 表示取消（不改动）。
class ComponentPickerPage extends StatefulWidget {
  const ComponentPickerPage({
    super.key,
    required this.slotLabel,
    required this.category,
    required this.current,
  });

  final String slotLabel;
  final String category;
  final PlanComponent? current;

  @override
  State<ComponentPickerPage> createState() => _ComponentPickerPageState();
}

class _ComponentPickerPageState extends State<ComponentPickerPage> {
  final _store = HardwareStore();
  final _userStore = UserSpecStore();
  final _searchController = TextEditingController();
  List<HardwareItem> _items = [];
  List<HardwareSpec> _library = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text);
  }

  bool get _searching => _query.trim().isNotEmpty;

  /// 清单条目（HardwareItem）的关键词匹配：型号 / 品牌 / 平台 / 备注。
  bool _itemMatches(HardwareItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (item.model.toLowerCase().contains(q)) return true;
    if (item.brand.toLowerCase().contains(q)) return true;
    if (item.platform.toLowerCase().contains(q)) return true;
    if (item.spec.toLowerCase().contains(q)) return true;
    return false;
  }

  List<HardwareSpec> get _visibleLibrary => _searching
      ? _library.where((s) => hardwareMatches(s, _query)).toList()
      : _library;

  List<HardwareItem> get _visibleItems => _searching
      ? _items.where((i) => _itemMatches(i, _query)).toList()
      : _items;

  Future<void> _load() async {
    final allItems = await _store.loadAll();
    final userSpecs = await _userStore.loadAll();
    if (!mounted) return;
    setState(() {
      _items = allItems.where((e) => e.category == widget.category).toList();
      // 硬件库：先放预置型号，再并入「我的添加」（按 id 去重）。
      _library = [];
      for (final s in kHardwareCatalog) {
        if (s.category == widget.category) _library.add(s);
      }
      for (final s in userSpecs) {
        if (s.category == widget.category &&
            !_library.any((e) => e.id == s.id)) {
          _library.add(s);
        }
      }
    });
  }

  void _pickItem(HardwareItem item) {
    Navigator.pop(
      context,
      (
        false,
        PlanComponent(
          category: item.category,
          brand: item.brand,
          model: item.model,
          price: item.price,
          platform: item.platform,
        ),
      ),
    );
  }

  Future<void> _pickSpec(HardwareSpec spec) async {
    final price = await showDialog<double>(
      context: context,
      builder: (context) => _SpecPriceDialog(spec: spec),
    );
    if (price == null) return;
    final comp = PlanComponent(
      category: spec.category,
      brand: spec.brand,
      model: spec.model,
      price: price,
      platform: '',
    );
    if (!mounted) return;
    Navigator.pop(context, (false, comp));
  }

  void _clear() {
    Navigator.pop(context, (true, null));
  }

  Future<void> _manual() async {
    final result = await showDialog<(double, String, String)>(
      context: context,
      builder: (context) => _ManualEntryDialog(slotLabel: widget.slotLabel),
    );
    if (result == null) return;
    final (price, model, brand) = result;
    if (!mounted) return;
    Navigator.pop(
      context,
      (
        false,
        PlanComponent(
          category: widget.category,
          brand: brand,
          model: model,
          price: price,
          platform: '',
        ),
      ),
    );
  }

  String _fmt(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('选择${widget.slotLabel}'),
        actions: [
          if (widget.current != null)
            TextButton(
              onPressed: _clear,
              child: const Text('清空此项'),
            ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(child: _searching ? _searchList(theme) : _allList(theme)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _manual,
            icon: const Icon(Icons.edit),
            label: const Text('手动填写型号和价格'),
            // 与全站主按钮统一：胶囊圆角 + 半透明玻璃底色。
            style: capsuleButtonStyle(theme),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      // 与硬件库搜索框统一：玻璃半透明底 + 胶囊圆角。
      child: GlassField(
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: '清空',
                    onPressed: _searchController.clear,
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _allList(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionTitle(theme, '从硬件库选'),
        if (_library.isEmpty)
          _emptyHint(theme, '硬件库里还没有「${widget.category}」')
        else
          for (final spec in _library) _specCard(theme, spec),
        const SizedBox(height: 8),
        _sectionTitle(theme, '从我的清单选'),
        if (_items.isEmpty)
          _emptyHint(theme, '清单里还没有「${widget.category}」')
        else
          for (final item in _items) _itemCard(theme, item),
      ],
    );
  }

  Widget _searchList(ThemeData theme) {
    final lib = _visibleLibrary;
    final items = _visibleItems;
    if (lib.isEmpty && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('没有找到「${_query.trim()}」相关的配件'),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (lib.isNotEmpty) ...[
          _sectionTitle(theme, '硬件库'),
          for (final spec in lib) _specCard(theme, spec),
        ],
        if (items.isNotEmpty) ...[
          _sectionTitle(theme, '我的清单'),
          for (final item in items) _itemCard(theme, item),
        ],
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emptyHint(ThemeData theme, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _specCard(ThemeData theme, HardwareSpec spec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CategoryBadge(category: spec.category),
        title: Text(spec.model),
        subtitle: Text(spec.brand),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pickSpec(spec),
      ),
    );
  }

  Widget _itemCard(ThemeData theme, HardwareItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CategoryBadge(category: item.category),
        title: Text(item.model),
        subtitle: Text(
          item.brand.isEmpty ? item.platform : '${item.brand} · ${item.platform}',
        ),
        trailing: Text(
          '¥${_fmt(item.price)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        onTap: () => _pickItem(item),
      ),
    );
  }
}

/// 手动填写 / 填价弹窗里的输入框：与全站统一为胶囊圆角 + 半透明底色。
InputDecoration _glassFieldDeco(BuildContext context, String label) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: scheme.surface.withValues(alpha: 0.4),
    border: border(scheme.outlineVariant.withValues(alpha: 0.5)),
    enabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5)),
    focusedBorder: border(scheme.primary),
  );
}

/// 从硬件库选型号时，填写价格（返回价格）。
class _SpecPriceDialog extends StatefulWidget {
  const _SpecPriceDialog({required this.spec});

  final HardwareSpec spec;

  @override
  State<_SpecPriceDialog> createState() => _SpecPriceDialogState();
}

class _SpecPriceDialogState extends State<_SpecPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, double.parse(_price.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('填写价格：${widget.spec.model}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _price,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _glassFieldDeco(context, '价格（元）*'),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return '请填写价格';
            final n = double.tryParse(t);
            if (n == null || n <= 0) return '价格格式不对';
            return null;
          },
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
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 手动填写型号 + 品牌 + 价格，返回 (价格, 型号, 品牌)。
class _ManualEntryDialog extends StatefulWidget {
  const _ManualEntryDialog({required this.slotLabel});

  final String slotLabel;

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _model = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _model.dispose();
    _brand.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_price.text.trim());
    Navigator.pop(context, (price, _model.text.trim(), _brand.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('手动填写${widget.slotLabel}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _model,
              autofocus: true,
              decoration: _glassFieldDeco(context, '型号 *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写型号' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              decoration: _glassFieldDeco(context, '品牌'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _glassFieldDeco(context, '价格（元）*'),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return '请填写价格';
                final n = double.tryParse(t);
                if (n == null || n <= 0) return '价格格式不对';
                return null;
              },
            ),
          ],
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
          child: const Text('确定'),
        ),
      ],
    );
  }
}
