import 'dart:convert';

/// JSON 反序列化的安全读取工具。
///
/// 本地存储里的数据来自用户长期累积，可能出现字段缺失、类型不符（如手改、
/// 旧版本结构不一致）等脏数据。原来用 `as String` / `as num` 强转，遇到脏数据会
/// 直接抛异常导致整个列表加载失败。这里统一用「取不到就兜底」的方式读取，
/// 保证 App 不会因为一条坏记录崩溃。

/// 读字符串；非字符串（或缺失）返回兜底值。
String asString(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;

/// 读可空字符串；非字符串返回 null。
String? asNullableString(dynamic value) => value is String ? value : null;

/// 读 double；支持 num 与数字字符串（如 "123.4"），其余返回兜底值。
double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// 读可空 double；null 或非数字返回 null。
double? asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// 读 int；支持 num 与整数字符串，其余返回兜底值。
int asInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 读时间戳（毫秒）转 DateTime；缺失或非法用当前时间兜底。
DateTime asDate(dynamic value) {
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return DateTime.now();
}

/// 读字符串键的 Map；非 Map 返回空 Map。
Map<String, dynamic> asStringMap(dynamic value) {
  if (value is! Map) return <String, dynamic>{};
  final out = <String, dynamic>{};
  value.forEach((k, v) {
    if (k is String) out[k] = v;
  });
  return out;
}

/// 读列表；非 List 返回空列表。
List<dynamic> asList(dynamic value) => value is List ? value : const [];

/// 把一段 JSON 字符串安全解析成「字符串键的 Map」；解析失败或非对象返回 null。
Map<String, dynamic>? decodeMap(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  } catch (_) {
    return null;
  }
}

/// 把一段 JSON 字符串安全解析成「字符串键的 Map 列表」。
/// 解析失败、不是列表、或列表里的非 Map 元素都会被忽略，避免坏数据拖垮整个加载。
List<Map<String, dynamic>> decodeMapList(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in decoded) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  } catch (_) {
    return [];
  }
}
