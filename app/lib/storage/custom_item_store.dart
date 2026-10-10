import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_item.dart';
import '../utils/json_safe.dart';

/// 保存「分析」模块的自定义项目
class CustomItemStore {
  static const _key = 'custom_items';
  static const _pendingKey = 'custom_items_pending_delete'; // 待补删云端的项目 id

  Future<List<CustomItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return decodeMapList(raw).map((e) => CustomItem.fromJson(e)).toList();
  }

  Future<void> saveAll(List<CustomItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(CustomItem item) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == item.id);
    items.add(item);
    await saveAll(items);
  }

  Future<void> update(CustomItem item) => add(item);

  Future<void> remove(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == id);
    await saveAll(items);
  }

  /// 读取「待补删云端」的项目 id（离线删除时记下的墓碑）
  Future<Set<String>> loadPendingDeleteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
    } catch (_) {
      // 坏数据直接当空，不影响主流程
    }
    return <String>{};
  }

  Future<void> savePendingDeleteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(ids.toList()));
    }
  }
}
