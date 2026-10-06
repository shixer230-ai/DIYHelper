import 'package:flutter/material.dart';

import '../analysis/value_index.dart';
import '../models/hardware_item.dart';
import '../models/hardware_spec.dart';
import '../storage/hardware_store.dart';
import '../storage/user_spec_store.dart';

const _categories = ['CPU', '主板', '显卡', '内存', '硬盘', '电源', '机箱', '其他'];
const _platforms = ['京东', '淘宝', '拼多多', '天猫', '其他'];

/// 录入 / 编辑一件硬件的表单页（从清单页某个品类进入）。
/// 保存时会把型号同步到硬件库「我的添加」，并支持填写「性能分」参与分析排行。
class HardwareFormPage extends StatefulWidget {
  const HardwareFormPage({super.key, this.category});

  /// 从清单页某个品类 Tab 进入时传入，锁定品类不可改；为空则允许自由选择。
  final String? category;

  @override
  State<HardwareFormPage> createState() => _HardwareFormPageState();
}

class _HardwareFormPageState extends State<HardwareFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _specController = TextEditingController();
  final _store = HardwareStore();
  final _userStore = UserSpecStore();

  String _category = _categories.first;
  String _platform = _platforms.first;
  bool _saving = false;

  /// 是否同步到硬件库「我的添加」。
  bool _syncToMine = true;

  /// 性能分（性价比跑分）输入，按品类对应「分析」里的跑分项。
  final Map<String, TextEditingController> _valueControllers = {};

  /// 品类是否锁定（从清单页某个品类进入时锁定，避免把 CPU 误记成显卡）。
  bool get _categoryLocked => widget.category != null;

  /// 当前品类参与「分析」排行的性价比项目。
  List<ValueItem> get _valueItems =>
      kValueItems.where((e) => e.category == _category).toList();

  @override
  void initState() {
    super.initState();
    _category = widget.category ?? _categories.first;
    for (final item in kValueItems) {
      _valueControllers[item.label] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _specController.dispose();
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 收集填了数值的「性能分」条目，label 用分析约定的精确名。
  List<SpecEntry> _collectValueBenches() {
    final result = <SpecEntry>[];
    for (final item in _valueItems) {
      final text = _valueControllers[item.label]?.text.trim() ?? '';
      if (text.isNotEmpty) result.add(SpecEntry(item.benchLabel, text));
    }
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final model = _modelController.text.trim();
    final brand = _brandController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final specText = _specController.text.trim();

    final item = HardwareItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: _category,
      brand: brand,
      model: model,
      price: price,
      platform: _platform,
      spec: specText,
      createdAt: DateTime.now(),
    );
    setState(() => _saving = true);
    await _store.add(item);

    // 同步到硬件库「我的添加」，方便之后在硬件库 / 整机方案里再选到这个型号。
    if (_syncToMine) {
      await _userStore.add(HardwareSpec(
        id: 'user_${DateTime.now().microsecondsSinceEpoch}',
        category: _category,
        brand: brand,
        model: model,
        specs: [if (specText.isNotEmpty) SpecEntry('参数', specText)],
        benchmarks: _collectValueBenches(),
      ));
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryLocked ? '录入 $_category' : '录入硬件'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                labelText: '品类',
                helperText: _categoryLocked ? '已锁定为当前分类' : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _categoryLocked
                  ? null
                  : (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '型号 *',
                hintText: '例如：i5-13600KF',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写型号' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: '品牌',
                hintText: '例如：Intel / 华硕',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '价格（元）*',
                hintText: '例如：1399',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return '请填写价格';
                final n = double.tryParse(t);
                if (n == null || n <= 0) return '价格格式不对';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _platform,
              borderRadius: BorderRadius.circular(12),
              decoration: const InputDecoration(
                labelText: '购买平台',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
              items: _platforms
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _platform = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specController,
              decoration: const InputDecoration(
                labelText: '参数备注',
                hintText: '例如：LGA1700 / DDR5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
            ),
            if (_valueItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              _valueBenchEditor(),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _syncToMine,
              onChanged: (v) => setState(() => _syncToMine = v),
              title: const Text('同时添加到硬件库「我的添加」'),
              subtitle: const Text('开启后，这个型号也能在硬件库和整机方案里选到'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                // 半透明胶囊保存按钮，和全站玻璃/胶囊风格保持一致。
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: const StadiumBorder(),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 性能分：按当前品类列出「分析」用的跑分项，label 固定，只填数值（可跳过）。
  Widget _valueBenchEditor() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性能分（用于「分析」排行）',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          '填了性能分，这个型号就能参与「分析」页的性价比排行；不填可跳过。',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        for (final item in _valueItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _valueControllers[item.label],
              decoration: InputDecoration(
                labelText: item.label,
                hintText: '如：约 10500',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                isDense: true,
              ),
            ),
          ),
      ],
    );
  }
}
