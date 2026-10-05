import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/analysis/value_index.dart';
import 'package:diy_helper/models/build_plan.dart';
import 'package:diy_helper/models/hardware_spec.dart';

void main() {
  test('parseBench 解析跑分字符串', () {
    expect(parseBench('约 16900'), 16900);
    expect(parseBench('约 85000 MB/s'), 85000);
    expect(parseBench('约 910'), 910);
    expect(parseBench('无'), null);
  });

  test('valueOf 按品类+型号匹配拿跑分', () {
    final lib = [
      const HardwareSpec(
        id: 'cpu_x',
        category: 'CPU',
        brand: 'Intel',
        model: '酷睿 i5-13400F',
        specs: [],
        benchmarks: [SpecEntry('CPU-Z 多核', '约 6800')],
      ),
      const HardwareSpec(
        id: 'gpu_x',
        category: '显卡',
        brand: 'NVIDIA',
        model: 'GeForce RTX 4080',
        specs: [],
        benchmarks: [SpecEntry('3DMark Time Spy', '约 28200')],
      ),
    ];
    const cpu = PlanComponent(
      category: 'CPU',
      brand: 'Intel',
      model: '酷睿 i5-13400F',
      price: 1200,
      platform: '',
    );
    expect(valueOf(cpu, 'CPU-Z 多核', lib), 6800);
    expect(valueOf(cpu, '3DMark Time Spy', lib), null); // CPU 没有该跑分
  });

  test('rankPlans 按性价比指数降序，跳过无对应部件的方案', () {
    final lib = [
      const HardwareSpec(
        id: 'gpu_4080',
        category: '显卡',
        brand: 'N',
        model: 'GeForce RTX 4080',
        specs: [],
        benchmarks: [SpecEntry('3DMark Time Spy', '约 28200')],
      ),
      const HardwareSpec(
        id: 'gpu_4060',
        category: '显卡',
        brand: 'N',
        model: 'GeForce RTX 4060',
        specs: [],
        benchmarks: [SpecEntry('3DMark Time Spy', '约 10500')],
      ),
    ];
    final expensive = BuildPlan(name: '贵')
      ..set('gpu', const PlanComponent(
        category: '显卡', brand: 'N', model: 'GeForce RTX 4080',
        price: 10000, platform: '',
      ));
    final cheap = BuildPlan(name: '便宜')
      ..set('gpu', const PlanComponent(
        category: '显卡', brand: 'N', model: 'GeForce RTX 4060',
        price: 3000, platform: '',
      ));
    final noGpu = BuildPlan(name: '核显机')
      ..set('cpu', const PlanComponent(
        category: 'CPU', brand: 'I', model: 'i5', price: 1000, platform: '',
      ));

    final r = rankPlans([expensive, cheap, noGpu], kValueItems[3], lib);
    expect(r.length, 2); // noGpu 被跳过
    expect(r[0].planName, '便宜'); // 10500/3000=3.5 > 28200/10000=2.82
    expect(r[1].planName, '贵');
  });

  test('rankPlans 整机功耗：累加 CPU+显卡功耗并按升序排', () {
    final lib = [
      const HardwareSpec(
        id: 'cpu_65',
        category: 'CPU',
        brand: 'I',
        model: 'i5-65W',
        specs: [SpecEntry('默认TDP', '65W')],
        benchmarks: [],
      ),
      const HardwareSpec(
        id: 'gpu_450',
        category: '显卡',
        brand: 'N',
        model: 'RTX 450W',
        specs: [SpecEntry('功耗', '450W')],
        benchmarks: [],
      ),
      const HardwareSpec(
        id: 'gpu_115',
        category: '显卡',
        brand: 'N',
        model: 'RTX 115W',
        specs: [SpecEntry('功耗', '115W')],
        benchmarks: [],
      ),
    ];
    final hot = BuildPlan(name: '高功耗')
      ..set('cpu', const PlanComponent(
          category: 'CPU', brand: 'I', model: 'i5-65W',
          price: 1000, platform: ''))
      ..set('gpu', const PlanComponent(
          category: '显卡', brand: 'N', model: 'RTX 450W',
          price: 5000, platform: ''));
    final cool = BuildPlan(name: '低功耗')
      ..set('cpu', const PlanComponent(
          category: 'CPU', brand: 'I', model: 'i5-65W',
          price: 1000, platform: ''))
      ..set('gpu', const PlanComponent(
          category: '显卡', brand: 'N', model: 'RTX 115W',
          price: 3000, platform: ''));
    // 显卡型号匹配不到功耗数据，整机功耗不全，应被跳过。
    final missingPower = BuildPlan(name: '缺功耗')
      ..set('cpu', const PlanComponent(
          category: 'CPU', brand: 'I', model: 'i5-65W',
          price: 1000, platform: ''))
      ..set('gpu', const PlanComponent(
          category: '显卡', brand: 'N', model: '未知显卡',
          price: 3000, platform: ''));

    final r = rankPlans([hot, cool, missingPower], kValueItems.last, lib);
    expect(r.length, 2); // 缺功耗的方案被跳过
    expect(r[0].planName, '低功耗'); // 65+115=180W < 65+450=515W
    expect(r[0].bench, 180);
    expect(r[1].bench, 515);
  });

  test('rankPlans 整机功耗：自定义功耗优先，且不低于 CPU+显卡', () {
    final lib = [
      const HardwareSpec(
        id: 'cpu_65',
        category: 'CPU',
        brand: 'I',
        model: 'i5-65W',
        specs: [SpecEntry('默认TDP', '65W')],
        benchmarks: [],
      ),
    ];
    final custom = BuildPlan(name: '自定义', customPower: 200)
      ..set('cpu', const PlanComponent(
          category: 'CPU', brand: 'I', model: 'i5-65W',
          price: 1000, platform: ''));
    // 自定义 200 > 自动 65，用 200。
    expect(rankPlans([custom], kValueItems.last, lib)[0].bench, 200);

    final low = BuildPlan(name: '偏低', customPower: 50)
      ..set('cpu', const PlanComponent(
          category: 'CPU', brand: 'I', model: 'i5-65W',
          price: 1000, platform: ''));
    // 自定义 50 < 自动 65，被抬到 65。
    expect(rankPlans([low], kValueItems.last, lib)[0].bench, 65);
  });
}
