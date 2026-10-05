import 'package:flutter/material.dart';

import '../analysis/value_index.dart';
import '../data/hardware_catalog.dart';
import '../models/build_plan.dart';
import '../models/hardware_spec.dart';
import '../storage/build_plan_store.dart';
import '../storage/user_spec_store.dart';

/// 分析页：按所选「性价比项目」给整机方案排行。
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _planStore = BuildPlanStore();
  final _userStore = UserSpecStore();

  List<BuildPlan> _plans = [];
  List<HardwareSpec> _library = [];
  ValueItem _item = kValueItems.first;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _planStore.loadAll();
    final userSpecs = await _userStore.loadAll();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _library = [...kHardwareCatalog, ...userSpecs];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('性价比分析')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _selector(theme),
                Expanded(child: _body(theme)),
              ],
            ),
    );
  }

  /// 是否为「整机功耗」这类数值越小越好的整机指标。
  bool get _isPower => _item.category == '整机';

  Widget _selector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: DropdownButtonFormField<ValueItem>(
        initialValue: _item,
        decoration: const InputDecoration(
          labelText: '分析项目',
          prefixIcon: Icon(Icons.tune),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final item in kValueItems)
            DropdownMenuItem(value: item, child: Text(item.label)),
        ],
        onChanged: (v) => setState(() => _item = v!),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    final results = rankPlans(_plans, _item, _library);
    final skipped = _plans.length - results.length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (results.isEmpty)
          _empty(theme)
        else
          for (var i = 0; i < results.length; i++) _card(theme, i, results[i]),
        if (results.isNotEmpty && skipped > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _isPower
                  ? '另有 $skipped 个方案未上榜（功耗数据未匹配）'
                  : '另有 $skipped 个方案未上榜（缺少「${_item.category}」或型号未匹配）',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _empty(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.insights, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _plans.isEmpty ? '还没有整机方案' : '没有可评分的方案',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _plans.isEmpty
                ? '先去「整机方案」建一个方案，并选好 CPU / 显卡'
                : _isPower
                    ? '所选「整机功耗」下，方案里配件的功耗数据未匹配到硬件库'
                    : '所选「${_item.label}」下，方案里缺少对应部件或型号未匹配到硬件库',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, int i, PlanValue v) {
    final isTop = i == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  isTop ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isTop
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.planName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPower
                        ? '整机功耗 ${_fmt(v.bench)}W'
                        : '${v.partModel} · ${_item.label} ${_fmt(v.bench)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '整机 ¥${_fmt(v.price)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _isPower ? '${_fmt(v.index)}W' : v.index.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  _isPower ? '整机功耗' : '性价比指数',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(double p) =>
    p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
