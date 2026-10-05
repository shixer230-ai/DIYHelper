import 'package:flutter/material.dart';

import 'build_plan_page.dart';
import 'catalog_page.dart';
import 'hardware_list_page.dart';

/// 底部导航壳：清单 / 整机方案 / 硬件库。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    HardwareListPage(),
    BuildPlanPage(),
    CatalogPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
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
        ],
      ),
    );
  }
}
