import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hardware_spec.dart';
import '../utils/json_safe.dart';

/// 保存硬件库中「我的添加」专栏里的型号（自定义 + 从预置库收藏）。
class UserSpecStore {
  static const _key = 'user_specs';

  Future<List<HardwareSpec>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return decodeMapList(raw).map((e) => HardwareSpec.fromJson(e)).toList();
  }

  Future<void> saveAll(List<HardwareSpec> specs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(specs.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(HardwareSpec spec) async {
    final specs = await loadAll();
    specs.removeWhere((e) => e.id == spec.id);
    specs.add(spec);
    await saveAll(specs);
  }

  Future<void> remove(String id) async {
    final specs = await loadAll();
    specs.removeWhere((e) => e.id == id);
    await saveAll(specs);
  }

  Future<bool> contains(String id) async {
    final specs = await loadAll();
    return specs.any((e) => e.id == id);
  }
}
