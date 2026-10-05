import 'package:flutter/material.dart';

import '../analysis/value_index.dart';
import '../data/hardware_catalog.dart';
import '../models/build_plan.dart';
import '../models/hardware_item.dart';
import '../models/hardware_spec.dart';
import '../storage/build_plan_store.dart';
import '../storage/hardware_store.dart';
import '../storage/user_spec_store.dart';
import '../utils/category_icons.dart';
import 'component_picker_page.dart';

/// 整机方案的一个槽位。
class BuildSlot {
  final String key;
  final String label;
  final String category;
  final bool required;

  const BuildSlot(this.key, this.label, this.category, {this.required = true});
}

const kBuildSlots = [
  BuildSlot('cpu', 'CPU', 'CPU'),
  BuildSlot('gpu', '显卡', '显卡', required: false),
  BuildSlot('motherboard', '主板', '主板'),
  BuildSlot('ram', '内存', '内存'),
  BuildSlot('storage', '硬盘', '硬盘'),
  BuildSlot('psu', '电源', '电源'),
  BuildSlot('case', '机箱', '机箱', required: false),
];

/// 整机方案：支持多个方案（新建/切换/重命名/删除），按槽位选配件自动汇总总金额。
class BuildPlanPage extends StatefulWidget {
  const BuildPlanPage({super.key});

  @override
  State<BuildPlanPage> createState() => _BuildPlanPageState();
}

class _BuildPlanPageState extends State<BuildPlanPage> {
  final _store = BuildPlanStore();
  List<BuildPlan> _plans = [];
  String? _currentId;
  bool _loading = true;

  // 硬件库（预置 + 我的添加），用于计算默认的 CPU+显卡 功耗。
  List<HardwareSpec> _library = [];

  BuildPlan? get _current {
    for (final p in _plans) {
      if (p.id == _currentId) return p;
    }
    return _plans.isEmpty ? null : _plans.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _store.loadAll();
    final currentId = await _store.loadCurrentId();
    final userSpecs = await UserSpecStore().loadAll();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _currentId = currentId;
      _library = [...kHardwareCatalog, ...userSpecs];
      _loading = false;
    });
  }

  Future<void> _createPlan() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: '新建方案', initial: _nextName(_plans)),
    );
    if (name == null) return;
    final plan = BuildPlan(name: name);
    setState(() {
      _plans.add(plan);
      _currentId = plan.id;
    });
    await _store.saveAll(_plans);
    await _store.saveCurrentId(plan.id);
  }

  Future<void> _openPlans() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _PlansSheet(),
    );
    await _load();
  }

  Future<void> _clearAll() async {
    final plan = _current;
    if (plan == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空方案'),
        content: const Text('确定清空这个方案里的所有配件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _replace(plan.id, BuildPlan(id: plan.id, name: plan.name));
    });
    await _store.saveAll(_plans);
  }

  Future<void> _pick(BuildSlot slot) async {
    final plan = _current;
    if (plan == null) return;
    final result = await Navigator.push<(bool, PlanComponent?)>(
      context,
      MaterialPageRoute(
        builder: (_) => ComponentPickerPage(
          slotLabel: slot.label,
          category: slot.category,
          current: plan[slot.key],
        ),
      ),
    );
    if (result == null) return; // 取消，不改动
    final updated = BuildPlan(
      id: plan.id,
      name: plan.name,
      components: Map.of(plan.components),
      customPower: plan.customPower,
    );
    updated.set(slot.key, result.$1 ? null : result.$2);
    setState(() => _replace(plan.id, updated));
    await _store.saveAll(_plans);
  }

  Future<void> _saveToItems() async {
    final plan = _current;
    if (plan == null || plan.components.isEmpty) return;

    final store = HardwareStore();
    final items = await store.loadAll();
    if (!mounted) return;
    final existingIndex = items.indexWhere((e) => e.planId == plan.id);

    // 首次保存：确认后直接新增。
    if (existingIndex < 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('保存到清单'),
          content: Text(
            '把整机方案「${_planName(plan)}」作为一个整体加入「我的硬件清单」吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await store.add(_newItem(plan, _planName(plan)));
      _snack('已把「${_planName(plan)}」加入清单');
      return;
    }

    // 已经保存过这个方案：让用户选「覆盖原来的 / 另存为新名称 / 取消」。
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清单里已有这个方案'),
        content: Text(
          '清单里已经保存过「${_planName(plan)}」，要覆盖原来的条目，还是另存一份新名称的？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'overwrite'),
            child: const Text('覆盖原来的'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'new'),
            child: const Text('另存为新名称'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    if (!mounted) return;

    if (choice == 'overwrite') {
      // 覆盖：保留原条目的 id 和录入时间，刷新价格/摘要/名称。
      final old = items[existingIndex];
      items[existingIndex] = HardwareItem(
        id: old.id,
        category: '整机方案',
        brand: '',
        model: _planName(plan),
        price: plan.total,
        platform: '',
        spec: _summary(plan),
        planId: plan.id,
        createdAt: old.createdAt,
      );
      await store.saveAll(items);
      _snack('已更新清单里的「${_planName(plan)}」');
    } else {
      // 另存为新名称：新建一条快照条目，仍关联同一个方案。
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _NameDialog(title: '新名称', initial: _planName(plan)),
      );
      if (name == null || name.isEmpty) return;
      await store.add(_newItem(plan, name));
      _snack('已把「$name」加入清单');
    }
  }

  /// 按槽位顺序列出配件摘要「品类 型号」。
  String _summary(BuildPlan plan) => kBuildSlots
      .map((s) => plan[s.key])
      .whereType<PlanComponent>()
      .map((c) => '${c.category} ${c.model}')
      .join(' · ');

  HardwareItem _newItem(BuildPlan plan, String model) {
    return HardwareItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      category: '整机方案',
      brand: '',
      model: model,
      price: plan.total,
      platform: '',
      spec: _summary(plan),
      planId: plan.id,
      createdAt: DateTime.now(),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 自动的 CPU+显卡 功耗（匹配不到返回 null）。
  double? _autoPower(BuildPlan plan) => totalPower(plan, _library);

  Widget _powerCard(BuildPlan plan) {
    return _PowerEditor(
      plan: plan,
      autoPower: _autoPower(plan),
      onSave: (v) => _savePower(plan, v),
    );
  }

  Future<void> _savePower(BuildPlan plan, double? value) async {
    final updated = BuildPlan(
      id: plan.id,
      name: plan.name,
      components: plan.components,
      customPower: value,
    );
    setState(() => _replace(plan.id, updated));
    await _store.saveAll(_plans);
    _snack(value == null ? '已清空自定义功耗' : '已设置整机功耗 ${_fmt(value)} W');
  }

  void _replace(String id, BuildPlan updated) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i >= 0) _plans[i] = updated;
  }

  String _fmt(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final plan = _current;
    return Scaffold(
      appBar: AppBar(
        title: Text(plan == null ? '整机方案' : _planName(plan)),
        actions: [
          IconButton(
            onPressed: _createPlan,
            tooltip: '新建方案',
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _openPlans,
            tooltip: '我的方案',
            icon: const Icon(Icons.folder_copy_outlined),
          ),
          if (plan != null && plan.components.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              tooltip: '清空方案',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : plan == null
              ? _emptyState()
              : _planBody(plan),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.computer, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('还没有整机方案'),
          const SizedBox(height: 4),
          const Text(
            '新建一个方案，选好配件后自动算总价',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _createPlan,
            icon: const Icon(Icons.add),
            label: const Text('新建方案'),
          ),
        ],
      ),
    );
  }

  Widget _planBody(BuildPlan plan) {
    final theme = Theme.of(context);
    final filled = kBuildSlots.where((s) => plan[s.key] != null).length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _totalCard(theme, filled, plan.total),
        const SizedBox(height: 4),
        for (final slot in kBuildSlots) _slotCard(theme, slot, plan),
        const SizedBox(height: 8),
        Text(
          '显卡、机箱为可选（用核显可不加显卡）；其余为必选。',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _powerCard(plan),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: plan.components.isEmpty ? null : _saveToItems,
          icon: const Icon(Icons.save_alt),
          label: const Text('保存到我的清单'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _totalCard(ThemeData theme, int filled, double total) {
    final onColor = theme.colorScheme.onPrimaryContainer;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('总金额', style: theme.textTheme.bodyMedium?.copyWith(color: onColor)),
            const SizedBox(height: 4),
            Text(
              '¥${_fmt(total)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '已选 $filled / ${kBuildSlots.length} 项',
              style: theme.textTheme.bodySmall?.copyWith(color: onColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotCard(ThemeData theme, BuildSlot slot, BuildPlan plan) {
    final comp = plan[slot.key];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            categoryIcon(slot.category),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(slot.required ? slot.label : '${slot.label}（可选）'),
        subtitle: Text(
          comp == null
              ? '未选择'
              : comp.brand.isEmpty
                  ? comp.model
                  : '${comp.model} · ${comp.brand}',
        ),
        trailing: comp == null
            ? const Icon(Icons.chevron_right)
            : Text(
                '¥${_fmt(comp.price)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
        onTap: () => _pick(slot),
      ),
    );
  }
}

String _planName(BuildPlan plan) => plan.name.isEmpty ? '未命名方案' : plan.name;

String _nextName(List<BuildPlan> plans) {
  var n = 1;
  while (plans.any((p) => p.name == '方案 $n')) {
    n++;
  }
  return '方案 $n';
}

String _fmt(double p) =>
    p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

/// 整机功耗编辑器：显示自动计算的 CPU+显卡 功耗，允许用户自定义（不低于自动值）。
class _PowerEditor extends StatefulWidget {
  const _PowerEditor({
    required this.plan,
    required this.autoPower,
    required this.onSave,
  });

  final BuildPlan plan;
  final double? autoPower;
  final Future<void> Function(double? value) onSave;

  @override
  State<_PowerEditor> createState() => _PowerEditorState();
}

class _PowerEditorState extends State<_PowerEditor> {
  late final TextEditingController _c = TextEditingController(
    text: widget.plan.customPower == null ? '' : _fmt(widget.plan.customPower!),
  );

  @override
  void didUpdateWidget(covariant _PowerEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.id != widget.plan.id) {
      _c.text = widget.plan.customPower == null
          ? ''
          : _fmt(widget.plan.customPower!);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final t = raw.trim();
    double? value;
    if (t.isEmpty) {
      value = null;
    } else {
      value = double.tryParse(t);
      if (value == null || value <= 0) {
        _toast('功耗格式不对，请输入数字（W）');
        return;
      }
      final auto = widget.autoPower;
      if (auto != null && value < auto) {
        _toast('自定义功耗不能低于 CPU+显卡功耗 ${_fmt(auto)} W');
        return;
      }
    }
    await widget.onSave(value);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auto = widget.autoPower;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '整机功耗',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              auto == null
                  ? '自动计算：CPU+显卡 功耗未匹配到硬件库'
                  : '自动计算：CPU+显卡 约 ${_fmt(auto)} W',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: _submit,
              decoration: InputDecoration(
                labelText: '自定义整机功耗（可选）',
                hintText: auto == null ? '如：550' : '不低于 ${_fmt(auto)} W',
                helperText: '仅计算cpu+显卡功耗（用户自定义除外）',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  onPressed: () => _submit(_c.text),
                  tooltip: '保存功耗',
                  icon: const Icon(Icons.check),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 输入方案名称的对话框，返回名称（非空）。
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial = ''});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
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
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: const InputDecoration(labelText: '名称'),
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

/// 方案列表：切换 / 重命名 / 删除 / 新建。
class _PlansSheet extends StatefulWidget {
  const _PlansSheet();

  @override
  State<_PlansSheet> createState() => _PlansSheetState();
}

class _PlansSheetState extends State<_PlansSheet> {
  final _store = BuildPlanStore();
  List<BuildPlan> _plans = [];
  String? _currentId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _store.loadAll();
    final currentId = await _store.loadCurrentId();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _currentId = currentId;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: '新建方案', initial: _nextName(_plans)),
    );
    if (name == null) return;
    final plan = BuildPlan(name: name);
    setState(() {
      _plans.add(plan);
      _currentId = plan.id;
    });
    await _store.saveAll(_plans);
    await _store.saveCurrentId(plan.id);
  }

  Future<void> _rename(BuildPlan plan) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: '重命名', initial: plan.name),
    );
    if (name == null) return;
    setState(() {
      final i = _plans.indexWhere((p) => p.id == plan.id);
      _plans[i] = BuildPlan(
        id: plan.id,
        name: name,
        components: plan.components,
        customPower: plan.customPower,
      );
    });
    await _store.saveAll(_plans);
  }

  Future<void> _delete(BuildPlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除方案'),
        content: Text('确定删除「${_planName(plan)}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _plans.removeWhere((p) => p.id == plan.id);
      if (_currentId == plan.id) {
        _currentId = _plans.isEmpty ? null : _plans.first.id;
      }
    });
    await _store.saveAll(_plans);
    await _store.saveCurrentId(_currentId);
  }

  Future<void> _select(BuildPlan plan) async {
    await _store.saveCurrentId(plan.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '我的方案',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add),
                  label: const Text('新建'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(child: _body(theme)),
          ],
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '还没有方案，点右上角「新建」创建一个',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final plan in _plans) _row(theme, plan),
      ],
    );
  }

  Widget _row(ThemeData theme, BuildPlan plan) {
    final selected = plan.id == _currentId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.computer,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(_planName(plan)),
      subtitle: Text('${plan.filledCount} 件 · ¥${_fmt(plan.total)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
          IconButton(
            onPressed: () => _rename(plan),
            tooltip: '重命名',
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            onPressed: () => _delete(plan),
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
      onTap: () => _select(plan),
    );
  }
}
