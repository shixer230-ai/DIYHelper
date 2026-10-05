import 'package:flutter/material.dart';

import '../data/hardware_catalog.dart';
import '../models/hardware_spec.dart';
import '../utils/category_icons.dart';
import 'catalog_detail_page.dart';

/// 硬件库：按品类浏览预置型号。
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<HardwareSpec>>{};
    for (final s in kHardwareCatalog) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }
    final categories = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('硬件库')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            '预置参考型号，跑分为约值。点击型号查看详情，可加入你的清单。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                category,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final spec in grouped[category]!)
              Card(
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CatalogDetailPage(spec: spec),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
