import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import 'analysis_page.dart';
import 'build_plan_page.dart';
import 'catalog_page.dart';
import 'hardware_list_page.dart';
import 'profile_page.dart';

/// 底部导航壳：清单 / 整机方案 / 硬件库 / 分析 / 设置。
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
      const ProfilePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          // 半透明，和卡片透明度一致，让背景透出。
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          // 外层导航条圆角与整机方案等卡片一致（kCardRadius）。
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.clipboard_list),
              label: '清单',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.computer),
              label: '整机方案',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.library),
              label: '硬件库',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.chart_bar),
              label: '分析',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
