import 'package:flutter/material.dart';

import '../analysis/value_index.dart';
import '../data/hardware_catalog.dart';
import '../models/build_plan.dart';
import '../models/custom_item.dart';
import '../models/hardware_spec.dart';
import '../storage/build_plan_store.dart';
import '../storage/custom_item_store.dart';
import '../storage/user_spec_store.dart';
import '../theme/app_theme.dart';
import 'custom_item_form_page.dart';

/// 分析页：按所选「性价比项目」（内置跑分/功耗 + 自定义项目）给整机方案排行。
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key, this.isActive = true});

  /// 当前是否为底部导航选中的标签页；切回来时用于刷新方案数据。
  final bool isActive;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with AutomaticKeepAliveClientMixin {
  final _planStore = BuildPlanStore();
  final _userStore = UserSpecStore();
  final _customStore = CustomItemStore();

  List<BuildPlan> _plans = [];
  List<HardwareSpec> _library = [];
  List<CustomItem> _customItems = [];
  ValueItem _builtin = kValueItems.first; // 选中的内置项目
  String? _customId; // 选中的自定义项目 id（null = 没选自定义）
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnalysisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 从其他标签页切回来时刷新方案/配件数据，避免排行滞后。
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  Future<void> _load() async {
    final plans = await _planStore.loadAll();
    final userSpecs = await _userStore.loadAll();
    final customs = await _customStore.loadAll();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _library = [...kHardwareCatalog, ...userSpecs];
      _customItems = customs;
      _loading = false;
    });
  }

  Future<void> _reloadCustoms() async {
    final customs = await _customStore.loadAll();
    if (!mounted) return;
    setState(() => _customItems = customs);
  }

  CustomItem? get _custom {
    for (final c in _customItems) {
      if (c.id == _customId) return c;
    }
    return null;
  }

  bool get _isCustom => _custom != null;

  /// 是否为「整机功耗」这类数值越小越好的整机指标。
  bool get _isPower => _builtin.category == '整机';

  // ---- 选择器 ----

  List<_Choice> get _choices => [
        for (final item in kValueItems) _Choice.builtin(item),
        for (final c in _customItems) _Choice.custom(c),
      ];

  _Choice get _selectedChoice => _isCustom
      ? _Choice.custom(_custom!)
      : _Choice.builtin(_builtin);

  void _onChoiceChanged(_Choice? choice) {
    if (choice == null) return;
    setState(() {
      if (choice.isCustom) {
        _customId = choice.custom!.id;
      } else {
        _builtin = choice.builtin!;
        _customId = null;
      }
    });
  }

  Future<void> _addCustom() async {
    final result = await Navigator.push<CustomItem>(
      context,
      MaterialPageRoute(builder: (_) => const CustomItemFormPage()),
    );
    if (result == null) return;
    await _customStore.add(result);
    await _reloadCustoms();
    if (!mounted) return;
    setState(() => _customId = result.id);
  }

  Future<void> _editCustom() async {
    final item = _custom;
    if (item == null) return;
    final result = await Navigator.push<CustomItem>(
      context,
      MaterialPageRoute(builder: (_) => CustomItemFormPage(initial: item)),
    );
    if (result == null) return;
    await _customStore.update(result);
    await _reloadCustoms();
  }

  Future<void> _deleteCustom() async {
    final item = _custom;
    if (item == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除自定义项目'),
        content: Text('确定删除「${item.fullLabel}」吗？已填的分数会一并删除。'),
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
    await _customStore.remove(item.id);
    if (_customId == item.id) _customId = null;
    await _reloadCustoms();
  }

  // ---- 分数 ----

  Future<void> _saveScore(CustomItem item, String planId, double? value) async {
    item.setScore(planId, value);
    setState(() {});
    await _customStore.saveAll(_customItems);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

  Widget _selector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<_Choice>(
              initialValue: _selectedChoice,
              isExpanded: true,
              // 展开的选择菜单与输入框统一用胶囊圆角，和底部导航一致。
              borderRadius: BorderRadius.circular(kNavBarRadius),
              decoration: const InputDecoration(
                labelText: '分析项目',
                prefixIcon: Icon(Icons.tune),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kNavBarRadius)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kNavBarRadius)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(kNavBarRadius)),
                ),
                isDense: true,
              ),
              items: [
                for (final c in _choices)
                  DropdownMenuItem(
                    value: c,
                    child: Text(c.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _onChoiceChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建自定义项目',
            onPressed: _addCustom,
          ),
          if (_isCustom)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑此项目',
              onPressed: _editCustom,
            ),
          if (_isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除此项目',
              onPressed: _deleteCustom,
            ),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_isCustom) return _customBody(theme);

    final results = rankPlans(_plans, _builtin, _library);
    final skipped = _plans.length - results.length;
    final topIndex = results.isEmpty ? 0.0 : results.first.index;
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomNavClearance(context)),
      children: [
        if (results.isEmpty)
          _empty(theme)
        else
          for (var i = 0; i < results.length; i++)
            _card(theme, i, results[i], topIndex),
        if (results.isNotEmpty && skipped > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _isPower
                  ? '另有 $skipped 个方案未上榜（功耗数据未匹配）'
                  : '另有 $skipped 个方案未上榜（缺少「${_builtin.category}」或型号未匹配）',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _customBody(ThemeData theme) {
    final custom = _custom!;
    if (_plans.isEmpty) return _empty(theme);

    // 性价比指数 = 分数 ÷ 整机总价 × 1000，越大越好；总价为 0 的排在最后。
    double indexOf(BuildPlan p) {
      final s = custom.scoreOf(p.id);
      if (s == null || p.total <= 0) return double.negativeInfinity;
      return s / p.total * 1000;
    }

    final scored = _plans.where((p) => custom.scoreOf(p.id) != null).toList()
      ..sort((a, b) => indexOf(b).compareTo(indexOf(a)));
    final unscored = _plans.where((p) => custom.scoreOf(p.id) == null).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomNavClearance(context)),
      children: [
        Text(
          '填写各方案的「${custom.scoreLabel}」，点 ✓ 保存后按性价比指数从高到低排行。',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < scored.length; i++)
          _CustomScoreCard(
            key: ValueKey('${custom.id}-${scored[i].id}'),
            plan: scored[i],
            item: custom,
            rank: i + 1,
            onSave: (v) => _saveScore(custom, scored[i].id, v),
          ),
        for (final plan in unscored)
          _CustomScoreCard(
            key: ValueKey('${custom.id}-${plan.id}'),
            plan: plan,
            item: custom,
            onSave: (v) => _saveScore(custom, plan.id, v),
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
                    : '所选「${_builtin.label}」下，方案里缺少对应部件或型号未匹配到硬件库',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, int i, PlanValue v, double topIndex) {
    final isTop = i == 0;
    // 相对第一名的百分比（第一名为 100%）；整机功耗越小越好，故用倒数。
    final ratio = topIndex <= 0
        ? 1.0
        : (_isPower ? topIndex / v.index : v.index / topIndex);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPower
                            ? '整机功耗 ${_fmt(v.bench)}W'
                            : '${_builtin.label} ${_fmt(v.bench)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '整机 ¥${_fmt(v.price)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _isPower
                            ? '${_fmt(v.index)}W'
                            : v.index.toStringAsFixed(1),
                        key: ValueKey(v.index),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      _isPower ? '整机功耗' : '性价比指数',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _valueBar(theme, ratio),
          ],
        ),
      ),
    );
  }

  /// 性价比相对条形图：第一名满格 100%，其余按比例缩短；低于 20% 时不再缩短，标注 <=20%。
  Widget _valueBar(ThemeData theme, double ratio) {
    final clamped = ratio < 0.2 ? 0.2 : ratio;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 18,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9),
            ),
            child: FractionallySizedBox(
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            _pct(ratio),
            textAlign: TextAlign.right,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// 把相对比例转成展示文本：第一名 100%，低于 20% 标 <=20%，其余保留整数百分比（不整则 1 位小数）。
  String _pct(double ratio) {
    if (ratio >= 1.0) return '100%';
    final pct = ratio * 100;
    if (pct < 20) return '<=20%';
    final s = pct.toStringAsFixed(1);
    return s.endsWith('.0') ? '${pct.round()}%' : '$s%';
  }
}

/// 选择器里的一个选项：内置项目或自定义项目。
class _Choice {
  final ValueItem? builtin;
  final CustomItem? custom;

  const _Choice.builtin(ValueItem v)
      : builtin = v,
        custom = null;
  const _Choice.custom(CustomItem c)
      : builtin = null,
        custom = c;

  bool get isCustom => custom != null;
  String get label => isCustom ? custom!.fullLabel : builtin!.label;

  @override
  bool operator ==(Object other) =>
      other is _Choice &&
      identical(builtin, other.builtin) &&
      custom?.id == other.custom?.id;

  @override
  int get hashCode => isCustom ? custom!.id.hashCode : builtin.hashCode;
}

/// 自定义项目下：一个方案一行，附分数输入框；有分数的按排名显示序号。
class _CustomScoreCard extends StatefulWidget {
  const _CustomScoreCard({
    super.key,
    required this.plan,
    required this.item,
    this.rank,
    required this.onSave,
  });

  final BuildPlan plan;
  final CustomItem item;
  final int? rank;
  final ValueChanged<double?> onSave;

  @override
  State<_CustomScoreCard> createState() => _CustomScoreCardState();
}

class _CustomScoreCardState extends State<_CustomScoreCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final v = widget.item.scoreOf(widget.plan.id);
    _controller = TextEditingController(text: v == null ? '' : _fmt(v));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final t = _controller.text.trim();
    if (t.isEmpty) {
      widget.onSave(null);
      return;
    }
    final n = double.tryParse(t);
    if (n == null || n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入大于 0 的数字')),
      );
      return;
    }
    widget.onSave(n);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = widget.rank;
    final isTop = rank == 1;
    final score = widget.item.scoreOf(widget.plan.id);
    final index = (score != null && widget.plan.total > 0)
        ? score / widget.plan.total * 1000
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isTop
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                rank == null ? '—' : '$rank',
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
                    widget.plan.name.isEmpty ? '未命名方案' : widget.plan.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  if (score != null)
                    Text(
                      '${widget.item.scoreLabel} ${_fmt(score)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '整机 ¥${_fmt(widget.plan.total)}',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.item.scoreLabel,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    tooltip: '保存',
                    onPressed: _save,
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text(
                    index == null ? '—' : index.toStringAsFixed(1),
                    key: ValueKey(index),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '性价比指数',
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
