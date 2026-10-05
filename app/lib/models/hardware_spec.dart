/// 一条参数 / 跑分条目：名称 + 值。
class SpecEntry {
  final String label;
  final String value;
  const SpecEntry(this.label, this.value);
}

/// 硬件库中的一款型号（预置参考数据）。
class HardwareSpec {
  final String id;
  final String category;
  final String brand;
  final String model;
  final List<SpecEntry> specs; // 参数规格
  final List<SpecEntry> benchmarks; // 跑分（最重要的排前面）

  const HardwareSpec({
    required this.id,
    required this.category,
    required this.brand,
    required this.model,
    required this.specs,
    required this.benchmarks,
  });

  /// 紧凑规格摘要，用于「加入清单」时的参数备注。
  String summary() => specs.map((e) => e.value).take(4).join(' · ');
}
