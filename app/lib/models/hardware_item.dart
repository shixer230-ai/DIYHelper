/// 一件硬件的记录：品类、型号、品牌、价格、购买平台、参数备注。
class HardwareItem {
  final String id;
  final String category; // 品类：CPU / 主板 / 显卡 ...
  final String brand; // 品牌，可留空
  final String model; // 型号
  final double price; // 价格（元）
  final String platform; // 购买平台：京东 / 淘宝 ...
  final String spec; // 参数备注，可留空
  final DateTime createdAt;

  const HardwareItem({
    required this.id,
    required this.category,
    required this.brand,
    required this.model,
    required this.price,
    required this.platform,
    required this.spec,
    required this.createdAt,
  });

  factory HardwareItem.fromJson(Map<String, dynamic> json) {
    return HardwareItem(
      id: json['id'] as String,
      category: json['category'] as String,
      brand: (json['brand'] as String?) ?? '',
      model: json['model'] as String,
      price: (json['price'] as num).toDouble(),
      platform: json['platform'] as String,
      spec: (json['spec'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
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
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
