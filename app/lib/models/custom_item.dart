import '../utils/json_safe.dart';

/// 分析模块里的「自定义项目」：给整机方案手工打分后按分数排行。
///
/// 分三类：
/// - 游戏：填游戏名 + 预设画质描述，每个方案填平均帧率（avg FPS）。
/// - 工程项目：填项目名（如 视频剪辑 / CAD），每个方案填性能分。
/// - 其它：填名称，每个方案填性能分。
class CustomItem {
  final String id;
  final String category; // 游戏 / 工程项目 / 其它
  final String name;
  final String description; // 画质描述（游戏用），其余可为空
  final Map<String, double> scores; // 方案 id -> 分数

  CustomItem({
    String? id,
    required this.category,
    required this.name,
    this.description = '',
    Map<String, double>? scores,
  })  : id = id ?? newId(),
        scores = scores ?? {};

  static String newId() => 'custom_${DateTime.now().microsecondsSinceEpoch}';

  double? scoreOf(String planId) => scores[planId];

  void setScore(String planId, double? value) {
    if (value == null) {
      scores.remove(planId);
    } else {
      scores[planId] = value;
    }
  }

  /// 每个方案要填的分数名称。
  String get scoreLabel => category == '游戏' ? '平均帧率 (FPS)' : '性能分';

  /// 下拉框里显示的完整名称（含类别前缀，游戏带画质描述）。
  String get fullLabel {
    if (category == '游戏' && description.isNotEmpty) {
      return '$category · $name（$description）';
    }
    return '$category · $name';
  }

  factory CustomItem.fromJson(Map<String, dynamic> json) {
    final scores = <String, double>{};
    asStringMap(json['scores']).forEach((k, v) {
      scores[k] = asDouble(v);
    });
    return CustomItem(
      id: asNullableString(json['id']),
      category: asString(json['category']),
      name: asString(json['name']),
      description: asString(json['description']),
      scores: scores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'description': description,
      'scores': scores,
    };
  }
}
