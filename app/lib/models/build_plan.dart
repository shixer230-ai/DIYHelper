import '../utils/json_safe.dart';

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
      category: asString(json['category']),
      brand: asString(json['brand']),
      model: asString(json['model']),
      price: asDouble(json['price']),
      platform: asString(json['platform']),
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

  /// 用户自定义的整机功耗（W）。为空时分析页自动按 CPU+显卡 计算。
  final double? customPower;

  BuildPlan({
    String? id,
    this.name = '',
    Map<String, PlanComponent>? components,
    this.customPower,
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
    final comps = <String, PlanComponent>{};
    asStringMap(json['components']).forEach((k, v) {
      if (v is Map) {
        comps[k] = PlanComponent.fromJson(Map<String, dynamic>.from(v));
      }
    });
    return BuildPlan(
      id: asNullableString(json['id']),
      name: asString(json['name']),
      components: comps,
      customPower: asNullableDouble(json['customPower']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'components': components.map((k, v) => MapEntry(k, v.toJson())),
      'customPower': customPower,
    };
  }
}
