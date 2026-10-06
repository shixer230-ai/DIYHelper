import '../utils/json_safe.dart';

/// 一件硬件的记录：品类、型号、品牌、价格、购买平台、参数备注。
class HardwareItem {
  final String id;
  final String category; // 品类：CPU / 主板 / 显卡 ...
  final String brand; // 品牌，可留空
  final String model; // 型号
  final double price; // 价格（元）
  final String platform; // 购买平台：京东 / 淘宝 ...
  final String spec; // 参数备注，可留空
  final String? planId; // 关联的整机方案 id（仅「整机方案」品类有值）
  final DateTime createdAt;

  const HardwareItem({
    required this.id,
    required this.category,
    required this.brand,
    required this.model,
    required this.price,
    required this.platform,
    required this.spec,
    this.planId,
    required this.createdAt,
  });

  factory HardwareItem.fromJson(Map<String, dynamic> json) {
    return HardwareItem(
      id: asString(json['id']),
      category: asString(json['category']),
      brand: asString(json['brand']),
      model: asString(json['model']),
      price: asDouble(json['price']),
      platform: asString(json['platform']),
      spec: asString(json['spec']),
      planId: asNullableString(json['planId']),
      createdAt: asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'brand': brand,
      'model': model,
      'price': price,
      'platform': platform,
      'spec': spec,
      if (planId != null) 'planId': planId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
