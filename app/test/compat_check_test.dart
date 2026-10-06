import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/analysis/compat_check.dart';
import 'package:diy_helper/data/hardware_catalog.dart';
import 'package:diy_helper/models/build_plan.dart';
import 'package:diy_helper/models/hardware_spec.dart';

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

  test('电源额定功率低于整机功耗会提醒', () {
    // 用自建数据，避免依赖硬件库具体型号：CPU 105W + 显卡 115W = 220W > 电源 200W。
    final lib = [
      const HardwareSpec(
        id: 'cpu',
        category: 'CPU',
        brand: '',
        model: 'U',
        specs: [SpecEntry('默认TDP', '105W')],
        benchmarks: [],
      ),
      const HardwareSpec(
        id: 'gpu',
        category: '显卡',
        brand: '',
        model: 'G',
        specs: [SpecEntry('功耗', '115W')],
        benchmarks: [],
      ),
      const HardwareSpec(
        id: 'psu',
        category: '电源',
        brand: '',
        model: 'P200',
        specs: [SpecEntry('额定功率', '200W')],
        benchmarks: [],
      ),
    ];
    final plan = BuildPlan(components: {
      'cpu': _comp('CPU', 'U'),
      'gpu': _comp('显卡', 'G'),
      'psu': _comp('电源', 'P200'),
    });
    final issues = checkCompatibility(plan, lib);
    expect(issues.any((e) => e.message.contains('电源')), isTrue);
  });

  test('电源额定功率充足时不提醒', () {
    final lib = [
      const HardwareSpec(
        id: 'cpu',
        category: 'CPU',
        brand: '',
        model: 'U',
        specs: [SpecEntry('默认TDP', '105W')],
        benchmarks: [],
      ),
      const HardwareSpec(
        id: 'gpu',
        category: '显卡',
        brand: '',
        model: 'G',
        specs: [SpecEntry('功耗', '115W')],
        benchmarks: [],
      ),
      const HardwareSpec(
        id: 'psu',
        category: '电源',
        brand: '',
        model: 'P500',
        specs: [SpecEntry('额定功率', '500W')],
        benchmarks: [],
      ),
    ];
    final plan = BuildPlan(components: {
      'cpu': _comp('CPU', 'U'),
      'gpu': _comp('显卡', 'G'),
      'psu': _comp('电源', 'P500'),
    });
    expect(checkCompatibility(plan, lib), isEmpty);
  });
}
