import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_item.dart';
import '../utils/json_safe.dart';

/// 保存「分析」模块的自定义项目。
class CustomItemStore {
  static const _key = 'custom_items';

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
}
