import 'package:flutter/material.dart';

import '../models/hardware_item.dart';
import '../storage/hardware_store.dart';
import '../utils/category_icons.dart';
import 'catalog_page.dart';
import 'hardware_form_page.dart';

/// 硬件清单主页：展示已录入的硬件，可新增、删除，也可进入硬件库选型号。
class HardwareListPage extends StatefulWidget {
  const HardwareListPage({super.key});

  @override
  State<HardwareListPage> createState() => _HardwareListPageState();
}

class _HardwareListPageState extends State<HardwareListPage> {
  final _store = HardwareStore();
  List<HardwareItem> _items = [];
  bool _loading = true;

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

  Future<void> _openCatalog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPage()),
    );
    // 从硬件库返回后刷新，把刚加入的型号显示出来。
    _load();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_items.isEmpty ? '我的硬件清单' : '我的硬件清单（${_items.length}）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: '硬件库',
            onPressed: _openCatalog,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: '自定义添加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.memory, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('还没有硬件记录'),
            const SizedBox(height: 4),
            const Text(
              '点右上角「硬件库」选型号，或点 + 自定义添加',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openCatalog,
              icon: const Icon(Icons.menu_book),
              label: const Text('去硬件库选型号'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _HardwareCard(
          item: item,
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }
}

class _HardwareCard extends StatelessWidget {
  const _HardwareCard({required this.item, required this.onDelete});

  final HardwareItem item;
  final VoidCallback onDelete;

  String _formatPrice(double p) {
    return p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (item.brand.isNotEmpty) item.brand,
      item.platform,
      if (item.spec.isNotEmpty) item.spec,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                    item.category,
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
          ],
        ),
      ),
    );
  }
}
