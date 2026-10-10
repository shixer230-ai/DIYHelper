import 'package:cloudbase_flutter/cloudbase_flutter.dart';

import '../models/build_plan.dart';
import '../models/custom_item.dart';
import 'auth_service.dart';
import 'cloud_app.dart';

/// 云端数据读写：方案上传/拉取/删除（按用户隔离），以及头像上传
class CloudSync {
  const CloudSync._();

  /// 每个用户云端方案数量上限（防恶意占用）
  static const int kMaxCloudPlans = 30;

  static const int kMaxPlanNameLen = 50;

  /// 单个方案最大配件数（实际槽位约 7 个）
  static const int kMaxComponentsPerPlan = 16;

  /// 每个用户云端自定义项目数量上限（防恶意占用）
  static const int kMaxCloudCustomItems = 30;

  static const int kMaxCustomNameLen = 50;

  /// 取当前登录用户 uid；未登录抛错
  static String _requireUid() {
    final uid = AuthService.instance.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('请先在「我的」页登录');
    }
    return uid;
  }

  /// 校验方案数据合法，拦异常/超大 payload（防恶意刷数据）
  static void _validatePlan(BuildPlan plan) {
    if (plan.name.length > kMaxPlanNameLen) {
      throw Exception('方案名过长（最多 $kMaxPlanNameLen 字）');
    }
    if (plan.components.length > kMaxComponentsPerPlan) {
      throw Exception('方案配件数量异常');
    }
    for (final c in plan.components.values) {
      if (c.price < 0) throw Exception('配件价格异常');
    }
  }

  /// 上传单个方案：按 id 幂等覆盖，写入 owner 做用户隔离
  static Future<void> uploadPlan(BuildPlan plan) async {
    final uid = _requireUid();
    _validatePlan(plan);
    final db = CloudApp.app.database();
    final data = plan.toJson()..['owner'] = uid;
    final res = await db.collection('plans').doc(plan.id).set(data);
    if (!res.isSuccess) {
      throw Exception('上传失败：${res.message ?? res.code}');
    }
  }

  /// 拉取当前用户自己的方案（按 owner 过滤，避免串号）
  static Future<List<BuildPlan>> downloadPlans() async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res = await db
        .collection('plans')
        .where({'owner': uid})
        .limit(kMaxCloudPlans)
        .get();
    if (!res.isSuccess) {
      throw Exception('拉取失败：${res.message ?? res.code}');
    }
    return res.data.map((e) => BuildPlan.fromJson(e)).toList();
  }

  /// 统计云端方案数（上传前判上限）；失败返回大数让上限检查跳过
  static Future<int> countPlans() async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res = await db.collection('plans').where({'owner': uid}).count();
    if (!res.isSuccess) return kMaxCloudPlans + 1;
    return res.total;
  }

  /// 删除云端方案：只删自己名下的（owner + id 过滤，防删到别人的数据）
  static Future<void> deletePlan(String planId) async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res = await db
        .collection('plans')
        .where({'owner': uid, 'id': planId})
        .remove();
    if (!res.isSuccess) {
      throw Exception('云端删除失败：${res.message ?? res.code}');
    }
  }

  /// 校验自定义项目数据合法
  static void _validateCustomItem(CustomItem item) {
    if (item.name.length > kMaxCustomNameLen) {
      throw Exception('项目名过长（最多 $kMaxCustomNameLen 字）');
    }
    if (item.description.length > 200) {
      throw Exception('画质描述过长');
    }
  }

  /// 上传单个自定义项目（按 id 幂等覆盖，写入 owner）
  static Future<void> uploadCustomItem(CustomItem item) async {
    final uid = _requireUid();
    _validateCustomItem(item);
    final db = CloudApp.app.database();
    final data = item.toJson()..['owner'] = uid;
    final res = await db.collection('custom_items').doc(item.id).set(data);
    if (!res.isSuccess) {
      throw Exception('上传失败：${res.message ?? res.code}');
    }
  }

  /// 拉取当前用户自己的自定义项目
  static Future<List<CustomItem>> downloadCustomItems() async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res = await db
        .collection('custom_items')
        .where({'owner': uid})
        .limit(kMaxCloudCustomItems)
        .get();
    if (!res.isSuccess) {
      throw Exception('拉取失败：${res.message ?? res.code}');
    }
    return res.data.map((e) => CustomItem.fromJson(e)).toList();
  }

  /// 统计云端自定义项目数（上传前判上限）
  static Future<int> countCustomItems() async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res =
        await db.collection('custom_items').where({'owner': uid}).count();
    if (!res.isSuccess) return kMaxCloudCustomItems + 1;
    return res.total;
  }

  /// 删除云端自定义项目：只删自己名下的（owner + id 过滤，防删到别人的数据）
  static Future<void> deleteCustomItem(String itemId) async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res = await db
        .collection('custom_items')
        .where({'owner': uid, 'id': itemId})
        .remove();
    if (!res.isSuccess) {
      throw Exception('云端删除失败：${res.message ?? res.code}');
    }
  }

  /// 上传头像到云存储，并把 fileId 存进账号资料
  static Future<void> uploadAvatar(List<int> bytes, String ext) async {
    final storage = CloudApp.app.storage.from();
    final name = '${AuthService.instance.username ?? 'user'}'
        '_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final up = await storage.upload(
      'avatars/$name',
      bytes,
      options: StorageUploadOptions(contentType: 'image/$ext', upsert: true),
    );
    final fileId = up.data?.id;
    if (fileId == null || fileId.isEmpty) {
      throw Exception('头像上传失败：${up.error?.message ?? '未知错误'}');
    }
    // 把 fileId 存进账号资料（头像的稳定引用）
    await CloudApp.app.auth.updateUser(UpdateUserReq(avatarUrl: fileId));
    // 上传后刷新本地缓存的用户资料
    await AuthService.instance.refreshUser();
  }

  /// 用账号里的 fileId 换临时下载链接
  static Future<String?> avatarDownloadUrl() async {
    final fileId = AuthService.instance.avatarUrl;
    if (fileId == null || !fileId.startsWith('cloud://')) return null;
    final storage = CloudApp.app.storage.from();
    final res = await storage.getDownloadUrls([fileId], expiresIn: 3600);
    return res.data?.first.downloadUrl;
  }
}
