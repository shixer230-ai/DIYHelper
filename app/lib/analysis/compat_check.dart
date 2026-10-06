import '../models/build_plan.dart';
import '../models/hardware_spec.dart';
import 'value_index.dart';

/// 一条兼容性问题（只提醒，不强制）。
class CompatIssue {
  const CompatIssue(this.message);

  final String message;
}

/// 检查整机方案的兼容性问题：CPU↔主板插槽、内存类型↔主板内存支持。
/// 只做「能确定」的判断；匹配不到硬件库型号的配件跳过（不误报）。
List<CompatIssue> checkCompatibility(BuildPlan plan, List<HardwareSpec> lib) {
  final issues = <CompatIssue>[];

  final cpuSpec = _lookup(plan['cpu'], 'CPU', lib);
  final mbSpec = _lookup(plan['motherboard'], '主板', lib);
  final ramSpec = _lookup(plan['ram'], '内存', lib);

  // 1) CPU 插槽 vs 主板插槽。
  final cpuSocket = _specValue(cpuSpec, '插槽');
  final mbSocket = _specValue(mbSpec, '插槽');
  if (cpuSocket != null && mbSocket != null && cpuSocket != mbSocket) {
    issues.add(CompatIssue('CPU 是 $cpuSocket，主板是 $mbSocket，插槽不兼容'));
  }

  // 2) 内存类型 vs 主板内存支持。
  final ramType = _memType(_specValue(ramSpec, '类型'));
  final mbMem = _memType(_specValue(mbSpec, '内存支持'));
  if (ramType != null && mbMem != null && ramType != mbMem) {
    issues.add(CompatIssue('内存是 $ramType，但主板支持 $mbMem，不兼容'));
  }

  return issues;
}

HardwareSpec? _lookup(PlanComponent? comp, String category, List<HardwareSpec> lib) {
  if (comp == null) return null;
  return findSpec(category, comp.model, lib);
}

/// 取某规格条目（如「插槽」「内存支持」「类型」）的值；找不到返回 null。
String? _specValue(HardwareSpec? spec, String label) {
  if (spec == null) return null;
  for (final s in spec.specs) {
    if (s.label == label) return s.value;
  }
  return null;
}

/// 从「DDR5-5600」「DDR4-5333（4槽）」这类字符串里提取内存代别（DDR4 / DDR5）。
String? _memType(String? value) {
  if (value == null) return null;
  return RegExp(r'DDR\d').firstMatch(value)?.group(0);
}
