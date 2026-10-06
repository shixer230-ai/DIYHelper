import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/build_plan.dart';
import '../utils/json_safe.dart';

/// 保存多个「整机方案」以及当前选中的方案 id。
class BuildPlanStore {
  static const _plansKey = 'build_plans';
  static const _currentKey = 'build_plan_current_id';
  static const _legacyKey = 'build_plan'; // 旧版单个方案，迁移后删除

  Future<List<BuildPlan>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansKey);
    if (raw != null && raw.isNotEmpty) {
      return decodeMapList(raw).map((e) => BuildPlan.fromJson(e)).toList();
    }
    // 迁移旧版单个方案（key = build_plan）。
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      final oldJson = decodeMap(legacy);
      if (oldJson != null) {
        final old = BuildPlan.fromJson(oldJson);
        final migrated = [
          BuildPlan(id: old.id, name: '方案 1', components: old.components),
        ];
        await prefs.remove(_legacyKey);
        await saveAll(migrated);
        return migrated;
      }
    }
    return [];
  }

  Future<void> saveAll(List<BuildPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(plans.map((e) => e.toJson()).toList());
    await prefs.setString(_plansKey, raw);
  }

  Future<String?> loadCurrentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentKey);
  }

  Future<void> saveCurrentId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_currentKey);
    } else {
      await prefs.setString(_currentKey, id);
    }
  }
}
