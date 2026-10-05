import 'package:flutter/material.dart';

import '../models/hardware_spec.dart';
import '../storage/user_spec_store.dart';

const _categories = ['CPU', '主板', '显卡', '内存', '硬盘', '电源', '机箱', '其他'];

/// 自定义添加硬件型号到「我的添加」：填品类、型号、品牌、参数规格和跑分。
class UserSpecFormPage extends StatefulWidget {
  const UserSpecFormPage({super.key});

  @override
  State<UserSpecFormPage> createState() => _UserSpecFormPageState();
}

class _UserSpecFormPageState extends State<UserSpecFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _store = UserSpecStore();

  String _category = _categories.first;
  bool _saving = false;

  final List<_EntryPair> _specPairs = [];
  final List<_EntryPair> _benchPairs = [];

  @override
  void initState() {
    super.initState();
    // 各给一行空输入，方便直接填写。
    _specPairs.add(_EntryPair());
    _benchPairs.add(_EntryPair());
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    for (final p in _specPairs) {
      p.dispose();
    }
    for (final p in _benchPairs) {
      p.dispose();
    }
    super.dispose();
  }

  List<SpecEntry> _collect(List<_EntryPair> pairs) {
    return pairs
        .map((p) => SpecEntry(p.label.text.trim(), p.value.text.trim()))
        .where((e) => e.label.isNotEmpty || e.value.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final spec = HardwareSpec(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      category: _category,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      specs: _collect(_specPairs),
      benchmarks: _collect(_benchPairs),
    );
    setState(() => _saving = true);
    await _store.add(spec);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自定义添加硬件')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: '品类',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '型号 *',
                hintText: '例如：i5-13600KF / RTX 3060',
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _entryEditor(
              title: '参数规格',
              hint: '例如：核心/线程 → 8核16线程',
              pairs: _specPairs,
            ),
            const SizedBox(height: 24),
            _entryEditor(
              title: '跑分',
              hint: '例如：3DMark Time Spy → 约 10500',
              pairs: _benchPairs,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('保存到「我的添加」'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryEditor({
    required String title,
    required String hint,
    required List<_EntryPair> pairs,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => pairs.add(_EntryPair())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加一项'),
            ),
          ],
        ),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        for (final p in pairs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: p.label,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      hintText: '如：核心/线程',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: p.value,
                    decoration: const InputDecoration(
                      labelText: '数值',
                      hintText: '如：8核16线程',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    pairs.remove(p);
                    p.dispose();
                    setState(() {});
                  },
                  tooltip: '删除这项',
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 一组「名称 + 数值」输入框，持有各自的控制器。
class _EntryPair {
  final TextEditingController label = TextEditingController();
  final TextEditingController value = TextEditingController();

  void dispose() {
    label.dispose();
    value.dispose();
  }
}
