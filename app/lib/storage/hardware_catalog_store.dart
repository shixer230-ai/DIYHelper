import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hardware_spec.dart';
import '../utils/json_safe.dart';

/// 缓存从云端同步下来的硬件库（下载一次后离线也能用）
class HardwareCatalogStore {
  static const _key = 'hardware_catalog_cloud';

  Future<List<HardwareSpec>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return decodeMapList(raw).map((e) => HardwareSpec.fromJson(e)).toList();
  }

  Future<void> save(List<HardwareSpec> specs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(specs.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
