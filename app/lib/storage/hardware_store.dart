import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hardware_item.dart';

/// 用手机本地存储保存硬件清单（当前阶段不接服务器）。
class HardwareStore {
  static const _key = 'hardware_items';

  Future<List<HardwareItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => HardwareItem.fromJson(e as Map<String, dynamic>))
        .toList();
    // 按录入时间倒序，最新在前
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveAll(List<HardwareItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(HardwareItem item) async {
    final items = await loadAll();
    items.add(item);
    await saveAll(items);
  }

  Future<void> addAll(List<HardwareItem> newItems) async {
    final items = await loadAll();
    items.addAll(newItems);
    await saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == id);
    await saveAll(items);
  }
}
