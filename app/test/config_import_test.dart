import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/models/build_plan.dart';
import 'package:diy_helper/pages/profile_page.dart';

void main() {
  test('导出文本能被解析回同等的整机方案', () {
    final plan = BuildPlan(name: '性价比主机')
      ..set('cpu', const PlanComponent(
        category: 'CPU',
        brand: 'Intel',
        model: 'i5-13600KF',
        price: 1799,
        platform: '京东',
      ))
      ..set('gpu', const PlanComponent(
        category: '显卡',
        brand: '',
        model: 'RTX 4070',
        price: 4399.5,
        platform: '',
      ))
      ..set('psu', const PlanComponent(
        category: '电源',
        brand: '海韵',
        model: 'FOCUS GX-850',
        price: 899,
        platform: '',
      ));

    final text = configText(plan);
    final parsed = parseConfig(text);

    expect(parsed, isNotNull);
    expect(parsed!.name, '性价比主机');
    expect(parsed.components.length, 3);

    final cpu = parsed['cpu']!;
    expect(cpu.model, 'i5-13600KF');
    expect(cpu.brand, 'Intel');
    expect(cpu.price, 1799);

    final gpu = parsed['gpu']!;
    expect(gpu.model, 'RTX 4070');
    expect(gpu.brand, '');
    expect(gpu.price, 4399.5);

    final psu = parsed['psu']!;
    expect(psu.model, 'FOCUS GX-850');
    expect(psu.brand, '海韵');
    expect(psu.price, 899);

    expect(parsed.total, closeTo(1799 + 4399.5 + 899, 0.001));
  });

  test('无有效配件行时返回 null', () {
    expect(parseConfig('随便一段文字'), isNull);
    expect(parseConfig(''), isNull);
  });

  test('未识别到方案名时用默认名', () {
    final plan = BuildPlan(name: 'X')
      ..set('cpu', const PlanComponent(
        category: 'CPU',
        brand: '',
        model: 'i5',
        price: 1000,
        platform: '',
      ));
    final text = configText(plan);
    // 去掉头部带方案名的那一行。
    final noHeader = text.substring(text.indexOf('\n') + 1);
    final parsed = parseConfig(noHeader);
    expect(parsed, isNotNull);
    expect(parsed!.name, '导入的方案');
    expect(parsed['cpu']!.model, 'i5');
  });
}
