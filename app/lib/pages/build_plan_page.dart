import 'package:flutter/material.dart';

import '../models/build_plan.dart';
import '../models/hardware_item.dart';
import '../storage/build_plan_store.dart';
import '../storage/hardware_store.dart';
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

/// 整机方案：按槽位选配件，自动汇总总金额。
class BuildPlanPage extends StatefulWidget {
  const BuildPlanPage({super.key});

  @override
  State<BuildPlanPage> createState() => _BuildPlanPageState();
}

class _BuildPlanPageState extends State<BuildPlanPage> {
  final _store = BuildPlanStore();
  BuildPlan _plan = BuildPlan();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await _store.load();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  Future<void> _pick(BuildSlot slot) async {
    final result = await Navigator.push<(bool, PlanComponent?)>(
      context,
      MaterialPageRoute(
        builder: (_) => ComponentPickerPage(
          slotLabel: slot.label,
          category: slot.category,
          current: _plan[slot.key],
        ),
      ),
    );
    if (result == null) return; // 取消，不改动
    setState(() {
      if (result.$1) {
        _plan.set(slot.key, null); // 清空
      } else {
        _plan.set(slot.key, result.$2);
      }
    });
    await _store.save(_plan);
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空方案'),
        content: const Text('确定清空整机方案里的所有配件吗？'),
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
    if (ok == true) {
      setState(() => _plan = BuildPlan());
      await _store.save(_plan);
    }
  }

  Future<void> _saveToItems() async {
    final comps = _plan.components.values.toList();
    if (comps.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存到清单'),
        content: Text('把方案里的 ${comps.length} 件配件加入「我的硬件清单」吗？'),
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
    final now = DateTime.now();
    final items = <HardwareItem>[];
    for (var i = 0; i < comps.length; i++) {
      final c = comps[i];
      items.add(HardwareItem(
        id: '${now.microsecondsSinceEpoch}_$i',
        category: c.category,
        brand: c.brand,
        model: c.model,
        price: c.price,
        platform: c.platform,
        spec: '整机方案',
        createdAt: now,
      ));
    }
    await HardwareStore().addAll(items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已把 ${items.length} 件配件加入清单')),
    );
  }

  String _fmt(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = kBuildSlots.where((s) => _plan[s.key] != null).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('整机方案'),
        actions: [
          if (_plan.components.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              tooltip: '清空方案',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _totalCard(theme, filled),
                const SizedBox(height: 4),
                for (final slot in kBuildSlots) _slotCard(theme, slot),
                const SizedBox(height: 8),
                Text(
                  '显卡、机箱为可选（用核显可不加显卡）；其余为必选。',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _plan.components.isEmpty ? null : _saveToItems,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('保存到我的清单'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _totalCard(ThemeData theme, int filled) {
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
              '¥${_fmt(_plan.total)}',
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

  Widget _slotCard(ThemeData theme, BuildSlot slot) {
    final comp = _plan[slot.key];
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
