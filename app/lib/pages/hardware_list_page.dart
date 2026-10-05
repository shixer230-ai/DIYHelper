import 'package:flutter/material.dart';

import '../models/hardware_item.dart';
import '../storage/build_plan_store.dart';
import '../storage/hardware_store.dart';
import '../utils/category_icons.dart';
import 'hardware_form_page.dart';

/// 硬件清单主页：展示已录入的硬件，可新增、删除，也可进入硬件库选型号。
class HardwareListPage extends StatefulWidget {
  const HardwareListPage({super.key, this.onOpenPlan});

  /// 点击整机方案条目时回调，用于切换到「整机方案」标签页。
  final VoidCallback? onOpenPlan;

  @override
  State<HardwareListPage> createState() => _HardwareListPageState();
}

class _HardwareListPageState extends State<HardwareListPage> {
  final _store = HardwareStore();
  List<HardwareItem> _items = [];
  bool _loading = true;

  // 清单分类 Tab 的顺序（可左右滑动切换）。
  static const _categories = [
    '整机方案', 'CPU', '显卡', '主板', '内存', '硬盘', '电源', '机箱', '其他',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HardwareFormPage()),
    );
    if (saved == true) _load();
  }

  Future<void> _openPlan(HardwareItem item) async {
    final id = item.planId;
    if (id == null) return;
    await BuildPlanStore().saveCurrentId(id);
    widget.onOpenPlan?.call();
  }

  Future<void> _confirmDelete(HardwareItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除'),
        content: Text('确定删除「${item.model}」吗？'),
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
    if (ok == true) {
      await _store.delete(item.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _items.isEmpty ? '我的硬件清单' : '我的硬件清单（${_items.length}）',
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final c in _categories) Tab(text: c)],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [for (final c in _categories) _categoryTab(c)],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openForm,
          tooltip: '自定义添加',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _categoryTab(String category) {
    final items = _items.where((e) => e.category == category).toList();
    if (items.isEmpty) return _emptyCategory(category);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _HardwareCard(
          item: item,
          onDelete: () => _confirmDelete(item),
          onTap: item.planId != null ? () => _openPlan(item) : null,
        );
      },
    );
  }

  Widget _emptyCategory(String category) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category), size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text('还没有「$category」的记录'),
          const SizedBox(height: 4),
          const Text(
            '可去「硬件库」选型号，或点右下角 + 添加',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HardwareCard extends StatelessWidget {
  const _HardwareCard({
    required this.item,
    required this.onDelete,
    this.onTap,
  });

  final HardwareItem item;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  String _formatPrice(double p) {
    return p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (item.brand.isNotEmpty) item.brand,
      if (item.platform.isNotEmpty) item.platform,
      if (item.spec.isNotEmpty) item.spec,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  categoryIcon(item.category),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.model,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.planId != null ? '${item.category} · 点击查看方案' : item.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${_formatPrice(item.price)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: '删除',
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
