import 'package:flutter/material.dart';

import '../models/hardware_item.dart';
import '../storage/hardware_store.dart';

const _categories = ['CPU', '主板', '显卡', '内存', '硬盘', '电源', '机箱', '其他'];
const _platforms = ['京东', '淘宝', '拼多多', '天猫', '其他'];

/// 录入 / 编辑一件硬件的表单页。
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

  String _category = _categories.first;
  String _platform = _platforms.first;
  bool _saving = false;

  /// 品类是否锁定（从清单页某个品类进入时锁定，避免把 CPU 误记成显卡）。
  bool get _categoryLocked => widget.category != null;

  @override
  void initState() {
    super.initState();
    _category = widget.category ?? _categories.first;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _specController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = HardwareItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: _category,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      platform: _platform,
      spec: _specController.text.trim(),
      createdAt: DateTime.now(),
    );
    setState(() => _saving = true);
    await _store.add(item);
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
              decoration: InputDecoration(
                labelText: '品类',
                helperText: _categoryLocked ? '已锁定为当前分类' : null,
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
              decoration: const InputDecoration(
                labelText: '购买平台',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
