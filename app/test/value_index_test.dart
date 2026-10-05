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
}
