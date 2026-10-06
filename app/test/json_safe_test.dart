import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/models/build_plan.dart';
import 'package:diy_helper/models/custom_item.dart';
import 'package:diy_helper/models/hardware_item.dart';
import 'package:diy_helper/models/hardware_spec.dart';
import 'package:diy_helper/utils/json_safe.dart';

void main() {
  group('decodeMapList', () {
    test('正常解析字符串键 Map 列表', () {
      final list = decodeMapList('[{"a":1},{"b":2}]');
      expect(list.length, 2);
      expect(list[0]['a'], 1);
    });

    test('非列表 / 非法 JSON / 列表里的非 Map 都被忽略', () {
      expect(decodeMapList('{"a":1}'), isEmpty);
      expect(decodeMapList('not json'), isEmpty);
      expect(decodeMapList('[1,"x",{"a":1}]').length, 1);
    });
  });

  test('decodeMap 非法 JSON 或非对象返回 null', () {
    expect(decodeMap('not json'), isNull);
    expect(decodeMap('{"a":1}')?['a'], 1);
    expect(decodeMap('[1,2]'), isNull);
  });

  test('HardwareItem.fromJson 缺字段/错类型不崩溃且兜底', () {
    final item = HardwareItem.fromJson({
      'price': '123.5', // 字符串数字也能解析
      'planId': 42, // 非字符串 → null
    });
    expect(item.id, '');
    expect(item.model, '');
    expect(item.price, 123.5);
    expect(item.planId, isNull);
  });

  test('BuildPlan.fromJson 忽略损坏的 components 条目', () {
    final plan = BuildPlan.fromJson({
      'name': '方案',
      'components': {
        'cpu': {
          'category': 'CPU',
          'brand': '',
          'model': 'i5',
          'price': 100,
          'platform': '',
        },
        'bad': 'not a map',
      },
      'customPower': '200',
    });
    expect(plan.components.length, 1);
    expect(plan.components['cpu']!.model, 'i5');
    expect(plan.components.containsKey('bad'), isFalse);
    expect(plan.customPower, 200);
  });

  test('CustomItem.fromJson 分数值可为字符串', () {
    final item = CustomItem.fromJson({
      'id': 'c1',
      'category': '游戏',
      'name': '黑神话',
      'scores': {'p1': '60.5'},
    });
    expect(item.scoreOf('p1'), 60.5);
  });

  test('HardwareSpec.fromJson specs/benchmarks 非列表时为空', () {
    final spec = HardwareSpec.fromJson({
      'id': 's',
      'category': 'CPU',
      'brand': '',
      'model': 'x',
      'specs': 'oops',
      'benchmarks': null,
    });
    expect(spec.specs, isEmpty);
    expect(spec.benchmarks, isEmpty);
  });
}
