import '../models/build_plan.dart';
import '../models/hardware_spec.dart';

/// 一个「性价比项目」：某个品类下的某个跑分项。
class ValueItem {
  final String label; // 显示名，如「CPU-Z 单核」
  final String category; // 所属品类：CPU / 显卡
  final String benchLabel; // 硬件库 benchmarks 里的条目名

  const ValueItem(this.label, this.category, this.benchLabel);
}

/// 可选的性价比项目（本版只覆盖 CPU + 显卡）。
const kValueItems = [
  ValueItem('CPU-Z 单核', 'CPU', 'CPU-Z 单核'),
  ValueItem('CPU-Z 多核', 'CPU', 'CPU-Z 多核'),
  ValueItem('Cinebench R23 多核', 'CPU', 'Cinebench R23 多核'),
  ValueItem('3DMark Time Spy', '显卡', '3DMark Time Spy'),
  ValueItem('3DMark Fire Strike', '显卡', '3DMark Fire Strike'),
  ValueItem('3DMark Port Royal', '显卡', '3DMark Port Royal'),
];

/// 一个方案在某性价比项目下的结果。
class PlanValue {
  final String planName;
  final String partModel; // 参与评分的部件型号
  final double bench; // 该跑分项的数值
  final double price; // 方案总价
  final double index; // 性价比指数 = bench / price * 1000

  const PlanValue({
    required this.planName,
    required this.partModel,
    required this.bench,
    required this.price,
    required this.index,
  });
}

/// 把「约 16900」「约 85000 MB/s」这类字符串解析成数字；解析失败返回 null。
double? parseBench(String value) {
  final m = RegExp(r'\d[\d,]*\.?\d*').firstMatch(value);
  if (m == null) return null;
  return double.tryParse(m.group(0)!.replaceAll(',', ''));
}

/// 在硬件库中按「品类 + 型号」匹配一款型号；找不到返回 null。
/// 先精确匹配（去空格/大小写归一化），再用互相包含做兜底。
HardwareSpec? findSpec(String category, String model, List<HardwareSpec> lib) {
  final normModel = _norm(model);
  if (normModel.isEmpty) return null;
  HardwareSpec? fallback;
  for (final s in lib) {
    if (s.category != category) continue;
    final normSpec = _norm(s.model);
    if (normSpec == normModel) return s;
    if (fallback == null &&
        (normSpec.contains(normModel) || normModel.contains(normSpec))) {
      fallback = s;
    }
  }
  return fallback;
}

/// 取某部件在指定跑分项下的数值；部件或跑分项找不到返回 null。
double? valueOf(PlanComponent comp, String benchLabel, List<HardwareSpec> lib) {
  final spec = findSpec(comp.category, comp.model, lib);
  if (spec == null) return null;
  for (final b in spec.benchmarks) {
    if (b.label == benchLabel) return parseBench(b.value);
  }
  return null;
}

/// 对一批方案按给定项目计算性价比指数，返回排序后的结果（降序）。
/// 缺对应部件、或型号匹配不到跑分的方案会被跳过。
List<PlanValue> rankPlans(
  List<BuildPlan> plans,
  ValueItem item,
  List<HardwareSpec> lib,
) {
  final slotKey = item.category == 'CPU' ? 'cpu' : 'gpu';
  final results = <PlanValue>[];
  for (final plan in plans) {
    final comp = plan[slotKey];
    if (comp == null) continue;
    final bench = valueOf(comp, item.benchLabel, lib);
    if (bench == null || plan.total <= 0) continue;
    results.add(PlanValue(
      planName: plan.name.isEmpty ? '未命名方案' : plan.name,
      partModel: comp.model,
      bench: bench,
      price: plan.total,
      index: bench / plan.total * 1000,
    ));
  }
  results.sort((a, b) => b.index.compareTo(a.index));
  return results;
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
