import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diy_helper/models/build_plan.dart';
import 'package:diy_helper/storage/build_plan_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保存并读取多个方案', () async {
    final store = BuildPlanStore();
    final a = BuildPlan(name: '方案 A');
    a.set('cpu', const PlanComponent(
      category: 'CPU',
      brand: 'Intel',
      model: 'i5',
      price: 1000,
      platform: '京东',
    ));
    final b = BuildPlan(name: '方案 B');

    await store.saveAll([a, b]);
    await store.saveCurrentId(b.id);

    final plans = await store.loadAll();
    expect(plans.length, 2);
    expect(plans[0].name, '方案 A');
    expect(plans[0].total, 1000);
    expect(plans[1].name, '方案 B');
    expect(await store.loadCurrentId(), b.id);
  });

  test('迁移旧版单个方案（无 id/name）到多方案列表', () async {
    // 旧版 BuildPlanStore 只存一个方案，key = build_plan，只有 components。
    SharedPreferences.setMockInitialValues({
      'build_plan':
          '{"components":{"cpu":{"category":"CPU","brand":"Intel","model":"i5","price":1000,"platform":"京东"}}}',
    });
    final store = BuildPlanStore();
    final plans = await store.loadAll();
    expect(plans.length, 1);
    expect(plans[0].name, '方案 1');
    expect(plans[0].total, 1000);
    expect(plans[0]['cpu']!.model, 'i5');
  });
}
