import 'package:flutter/material.dart';

import '../models/custom_item.dart';
import '../theme/app_theme.dart';

const _categories = ['游戏', '工程项目', '其它'];

/// 新建 / 编辑「自定义项目」：选类别、填名称（游戏额外填画质描述）。
class CustomItemFormPage extends StatefulWidget {
  const CustomItemFormPage({super.key, this.initial});

  final CustomItem? initial;

  @override
  State<CustomItemFormPage> createState() => _CustomItemFormPageState();
}

class _CustomItemFormPageState extends State<CustomItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late String _category;

  bool get _isEditing => widget.initial != null;
  bool get _isGame => _category == '游戏';

  String get _nameLabel => _category == '游戏'
      ? '游戏名'
      : (_category == '工程项目' ? '项目名' : '名称');

  String get _nameHint => _category == '游戏'
      ? '如：黑神话：悟空 / 原神'
      : (_category == '工程项目' ? '如：视频剪辑 / CAD建模' : '如：综合性能分');

  @override
  void initState() {
    super.initState();
    _category = widget.initial?.category ?? _categories.first;
    _nameController.text = widget.initial?.name ?? '';
    _descController.text = widget.initial?.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CustomItem(
        id: widget.initial?.id, // 编辑时保留原 id
        category: _category,
        name: _nameController.text.trim(),
        description: _isGame ? _descController.text.trim() : '',
        scores: widget.initial?.scores, // 编辑时保留已填的分数
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑自定义项目' : '新建自定义项目')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              borderRadius: BorderRadius.circular(12),
              decoration: const InputDecoration(
                labelText: '类别',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '$_nameLabel *',
                hintText: _nameHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写名称' : null,
            ),
            if (_isGame) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '预设画质描述',
                  hintText: '如：1080P 高画质 / 2K 高画质',
                  helperText: '用于区分同一游戏的不同画质档位',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              // 与「保存到我的添加」等主按钮统一：胶囊圆角 + 半透明材质。
              style: capsuleButtonStyle(Theme.of(context)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
