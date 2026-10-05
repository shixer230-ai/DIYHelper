import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/data/hardware_catalog.dart';
import 'package:diy_helper/models/hardware_spec.dart';

void main() {
  test('brandGroupOf 主流品牌原样返回，其余归入「其它」', () {
    expect(brandGroupOf('CPU', 'Intel'), 'Intel');
    expect(brandGroupOf('CPU', 'AMD'), 'AMD');
    expect(brandGroupOf('CPU', 'intel'), 'Intel'); // 忽略大小写
    expect(brandGroupOf('CPU', '龙芯'), '其它');
    expect(brandGroupOf('显卡', 'NVIDIA'), 'NVIDIA');
    expect(brandGroupOf('显卡', '摩尔线程'), '其它');
    expect(brandGroupOf('主板', '华硕'), '华硕');
    expect(brandGroupOf('主板', '华擎'), '其它');
    expect(brandGroupOf('内存', '光威'), '其它');
    expect(brandGroupOf('硬盘', '金士顿'), '其它');
    expect(brandGroupOf('未知品类', '随便'), '其它');
  });

  test('hardwareMatches 按型号/品牌/品类/参数/跑分关键词命中', () {
    const spec = HardwareSpec(
      id: 'x',
      category: 'CPU',
      brand: 'Intel',
      model: '酷睿 i5-13600KF',
      specs: [SpecEntry('默认TDP', '125W')],
      benchmarks: [SpecEntry('CPU-Z 多核', '约 9800')],
    );
    expect(hardwareMatches(spec, 'i5'), true); // 型号
    expect(hardwareMatches(spec, 'intel'), true); // 品牌（忽略大小写）
    expect(hardwareMatches(spec, 'cpu'), true); // 品类
    expect(hardwareMatches(spec, '125w'), true); // 参数值（忽略大小写）
    expect(hardwareMatches(spec, 'CPU-Z'), true); // 跑分名
    expect(hardwareMatches(spec, 'Ryzen'), false); // 无匹配
    expect(hardwareMatches(spec, ''), false); // 空关键词不命中
    expect(hardwareMatches(spec, '  '), false);
  });
}
