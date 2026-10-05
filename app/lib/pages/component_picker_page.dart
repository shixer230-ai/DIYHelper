import 'package:flutter/material.dart';

import '../data/hardware_catalog.dart';
import '../models/build_plan.dart';
import '../models/hardware_item.dart';
import '../models/hardware_spec.dart';
import '../storage/hardware_store.dart';
import '../storage/user_spec_store.dart';
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
  List<HardwareItem> _items = [];
  List<HardwareSpec> _library = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      body: ListView(
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _manual,
            icon: const Icon(Icons.edit),
            label: const Text('手动填写型号和价格'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
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
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            categoryIcon(spec.category),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
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
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            categoryIcon(item.category),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
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
          decoration: const InputDecoration(labelText: '价格（元）*'),
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
        FilledButton(onPressed: _submit, child: const Text('确定')),
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
              decoration: const InputDecoration(labelText: '型号 *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写型号' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(labelText: '品牌'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '价格（元）*'),
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
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
}
