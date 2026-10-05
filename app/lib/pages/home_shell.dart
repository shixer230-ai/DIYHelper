import 'package:flutter/material.dart';

import 'analysis_page.dart';
import 'build_plan_page.dart';
import 'catalog_page.dart';
import 'hardware_list_page.dart';

/// 底部导航壳：清单 / 整机方案 / 硬件库 / 分析。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openPlanTab() {
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HardwareListPage(onOpenPlan: _openPlanTab),
      const BuildPlanPage(),
      const CatalogPage(),
      const AnalysisPage(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: '清单',
          ),
          NavigationDestination(
            icon: Icon(Icons.computer),
            label: '整机方案',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '硬件库',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '分析',
          ),
        ],
      ),
    );
  }
}
