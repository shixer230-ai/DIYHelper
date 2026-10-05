import 'package:flutter_test/flutter_test.dart';

import 'package:diy_helper/analysis/value_index.dart';
import 'package:diy_helper/models/build_plan.dart';
import 'package:diy_helper/models/custom_item.dart';

void main() {
  test('CustomItem 序列化往返', () {
    final item = CustomItem(
      id: 'custom_1',
      category: '游戏',
      name: '黑神话：悟空',
      description: '2K 高画质',
      scores: {'p1': 60.5, 'p2': 80},
    );
    final restored = CustomItem.fromJson(item.toJson());
    expect(restored.id, 'custom_1');
    expect(restored.category, '游戏');
    expect(restored.name, '黑神话：悟空');
    expect(restored.description, '2K 高画质');
    expect(restored.scoreOf('p1'), 60.5);
    expect(restored.scoreOf('p2'), 80);
    expect(restored.scoreOf('p3'), null);
    expect(restored.scoreLabel, '平均帧率 (FPS)');
    expect(restored.fullLabel, '游戏 · 黑神话：悟空（2K 高画质）');
  });

  test('setScore 可增删分数', () {
    final item = CustomItem(category: '其它', name: '综合分');
    expect(item.scoreOf('a'), null);
    item.setScore('a', 90);
    expect(item.scoreOf('a'), 90);
    item.setScore('a', null);
    expect(item.scoreOf('a'), null);
    expect(item.scoreLabel, '性能分');
  });

  test('rankCustomPlans 按分数降序，跳过没填分数的方案', () {
    final item = CustomItem(category: '游戏', name: '某游戏')
      ..setScore('p_hot', 120)
      ..setScore('p_mid', 60)
      ..setScore('p_cool', 45);
    final plans = [
      BuildPlan(id: 'p_cool', name: '低配'),
      BuildPlan(id: 'p_mid', name: '中配'),
      BuildPlan(id: 'p_hot', name: '高配'),
      BuildPlan(id: 'p_none', name: '没分'),
    ];
    final r = rankCustomPlans(plans, item);
    expect(r.length, 3);
    expect(r[0].planName, '高配');
    expect(r[0].bench, 120);
    expect(r[1].planName, '中配');
    expect(r[2].planName, '低配');
  });
}
