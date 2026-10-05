import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/build_plan.dart';

/// 保存「整机方案」（单个方案）。
class BuildPlanStore {
  static const _key = 'build_plan';

  Future<BuildPlan> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return BuildPlan();
    return BuildPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(BuildPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plan.toJson()));
  }
}
