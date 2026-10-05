import 'package:flutter/material.dart';

import '../data/hardware_catalog.dart';
import '../models/hardware_spec.dart';
import '../storage/user_spec_store.dart';
import '../utils/category_icons.dart';
import 'catalog_detail_page.dart';
import 'user_spec_form_page.dart';

/// 硬件库：按品类分 Tab，左右滑动切换；首个 Tab 是「我的添加」。
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _userStore = UserSpecStore();
  List<HardwareSpec> _userSpecs = [];

  // 预置库的品类顺序（即各 Tab 的顺序）。
  static const _categories = ['CPU', '显卡', '主板', '内存', '硬盘'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final specs = await _userStore.loadAll();
    if (!mounted) return;
    setState(() => _userSpecs = specs);
  }

  Future<void> _openDetail(HardwareSpec spec) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatalogDetailPage(spec: spec)),
    );
    // 返回后刷新，可能增删了「我的添加」。
    _load();
  }

  Future<void> _openCustomForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UserSpecFormPage()),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length + 1, // +1 是「我的添加」
      child: Scaffold(
        appBar: AppBar(
          title: const Text('硬件库'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: '我的添加'),
              for (final c in _categories) Tab(text: c),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMineTab(),
            for (final c in _categories) _buildCategoryTab(c),
          ],
        ),
      ),
    );
  }

  Widget _buildMineTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '我的添加',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: _openCustomForm,
              icon: const Icon(Icons.add),
              label: const Text('自定义添加'),
            ),
          ],
        ),
        if (_userSpecs.isEmpty)
          _emptyMine(context)
        else
          for (final s in _userSpecs) _specCard(context, s),
      ],
    );
  }

  Widget _buildCategoryTab(String category) {
    final specs = kHardwareCatalog.where((s) => s.category == category).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '预置参考型号，跑分为约值，点击查看详情。',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        for (final s in specs) _specCard(context, s),
      ],
    );
  }

  Widget _emptyMine(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.bookmark_add_outlined,
                size: 36, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('还没有自定义添加的型号'),
            const SizedBox(height: 4),
            Text(
              '点「自定义添加」录入新硬件，或在预置型号详情里点「加入我的添加」收藏。',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specCard(BuildContext context, HardwareSpec spec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            categoryIcon(spec.category),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(spec.model),
        subtitle: Text(spec.brand),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDetail(spec),
      ),
    );
  }
}
