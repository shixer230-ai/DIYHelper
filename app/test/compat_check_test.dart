import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/analysis/compat_check.dart';
import 'package:diy_helper/data/hardware_catalog.dart';
import 'package:diy_helper/models/build_plan.dart';

PlanComponent _comp(String category, String model) => PlanComponent(
      category: category,
      brand: '',
      model: model,
      price: 100,
      platform: '',
    );

void main() {
  test('CPU 与主板插槽不匹配会提醒', () {
    final plan = BuildPlan(components: {
      'cpu': _comp('CPU', '酷睿 i5-13400F'), // LGA1700
      'motherboard': _comp('主板', 'MAG B650M MORTAR WiFi'), // AM5
    });
    final issues = checkCompatibility(plan, kHardwareCatalog);
    expect(issues.any((e) => e.message.contains('插槽')), isTrue);
  });

  test('内存与主板内存支持不匹配会提醒', () {
    final plan = BuildPlan(components: {
      'cpu': _comp('CPU', '锐龙 5 7600X'), // AM5
      'motherboard': _comp('主板', 'MAG B650M MORTAR WiFi'), // AM5 DDR5
      'ram': _comp('内存', '银爵 DDR4-3600 32GB（16G×2）'), // DDR4
    });
    final issues = checkCompatibility(plan, kHardwareCatalog);
    expect(issues.any((e) => e.message.contains('内存')), isTrue);
  });

  test('完全兼容时不提醒', () {
    final plan = BuildPlan(components: {
      'cpu': _comp('CPU', '锐龙 5 7600X'), // AM5
      'motherboard': _comp('主板', 'MAG B650M MORTAR WiFi'), // AM5 DDR5
      'ram': _comp('内存', 'FURY Beast DDR5-6000 32GB（16G×2）'), // DDR5
    });
    expect(checkCompatibility(plan, kHardwareCatalog), isEmpty);
  });
}
