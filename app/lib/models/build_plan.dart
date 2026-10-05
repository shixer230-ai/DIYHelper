/// 整机方案里的一个配件（含价格）。
class PlanComponent {
  final String category;
  final String brand;
  final String model;
  final double price;
  final String platform;

  const PlanComponent({
    required this.category,
    required this.brand,
    required this.model,
    required this.price,
    required this.platform,
  });

  factory PlanComponent.fromJson(Map<String, dynamic> json) {
    return PlanComponent(
      category: json['category'] as String,
      brand: (json['brand'] as String?) ?? '',
      model: json['model'] as String,
      price: (json['price'] as num).toDouble(),
      platform: (json['platform'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'brand': brand,
      'model': model,
      'price': price,
      'platform': platform,
    };
  }
}

/// 整机方案：按槽位（cpu/gpu/主板/内存/硬盘/电源/机箱）存放已选配件。
/// 每个方案有自己的 id 和名称，可保存多个。
class BuildPlan {
  final String id;
  final String name;
  final Map<String, PlanComponent> components;

  BuildPlan({
    String? id,
    this.name = '',
    Map<String, PlanComponent>? components,
  })  : id = id ?? newId(),
        components = components ?? {};

  /// 生成一个不重复的方案 id。
  static String newId() => 'plan_${DateTime.now().microsecondsSinceEpoch}';

  PlanComponent? operator [](String key) => components[key];

  void set(String key, PlanComponent? c) {
    if (c == null) {
      components.remove(key);
    } else {
      components[key] = c;
    }
  }

  /// 已选配件的总金额。
  double get total => components.values.fold(0, (s, c) => s + c.price);

  /// 已选配件数。
  int get filledCount => components.length;

  factory BuildPlan.fromJson(Map<String, dynamic> json) {
    final comps = (json['components'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, PlanComponent.fromJson(v as Map<String, dynamic>)),
    );
    return BuildPlan(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      components: comps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'components': components.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}
