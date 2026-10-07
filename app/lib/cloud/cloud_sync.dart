import 'package:cloudbase_flutter/cloudbase_flutter.dart';

import '../models/build_plan.dart';
import 'auth_service.dart';
import 'cloud_app.dart';

/// 云端数据读写：整机方案的上传 / 拉取 / 删除（按用户隔离），以及头像上传到云存储。
class CloudSync {
  const CloudSync._();

  /// 每个用户云端方案数量上限（防恶意占用）。
  static const int kMaxCloudPlans = 30;

  /// 方案名最大长度。
  static const int kMaxPlanNameLen = 50;

  /// 单个方案最大配件数（兜底校验，实际槽位约 7 个）。
  static const int kMaxComponentsPerPlan = 16;

  /// 取当前登录用户的稳定 ID；未登录抛错。
  static String _requireUid() {
    final uid = AuthService.instance.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('请先在「我的」页登录');
    }
    return uid;
  }

  /// 校验方案数据合法，拦下异常 / 超大 payload（防恶意刷数据）。
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

  /// 上传单个方案：用方案 id 当文档 id 幂等覆盖（重复上传不产生重复数据），
  /// 并写入 `owner` 记录归属人，实现用户隔离。
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

  /// 从云拉取当前用户自己的所有方案（按 owner 过滤，避免串号/隐私泄露）。
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

  /// 统计当前用户云端方案数（上传前判上限）。
  /// 统计失败时返回一个足够大的数，让上限检查直接跳过、不阻塞上传。
  static Future<int> countPlans() async {
    final uid = _requireUid();
    final db = CloudApp.app.database();
    final res = await db.collection('plans').where({'owner': uid}).count();
    if (!res.isSuccess) return kMaxCloudPlans + 1;
    return res.total;
  }

  /// 删除云端某个方案（本地删除时同步调用）。
  static Future<void> deletePlan(String planId) async {
    _requireUid();
    final db = CloudApp.app.database();
    final res = await db.collection('plans').doc(planId).remove();
    if (!res.isSuccess) {
      throw Exception('云端删除失败：${res.message ?? res.code}');
    }
  }

  /// 上传头像图片到云存储，并把 fileId 存进账号资料。
  ///
  /// [bytes] 为图片文件字节，[ext] 为扩展名（jpg / png）。
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
    // 把文件 ID 存到账号资料（头像的稳定引用，展示时再换临时下载链接）。
    await CloudApp.app.auth.updateUser(UpdateUserReq(avatarUrl: fileId));
    // 上传后刷新本地缓存的用户资料。
    await AuthService.instance.refreshUser();
  }

  /// 用账号里存的 fileId 换一个临时下载链接（头像展示用）。
  static Future<String?> avatarDownloadUrl() async {
    final fileId = AuthService.instance.avatarUrl;
    if (fileId == null || !fileId.startsWith('cloud://')) return null;
    final storage = CloudApp.app.storage.from();
    final res = await storage.getDownloadUrls([fileId], expiresIn: 3600);
    return res.data?.first.downloadUrl;
  }
}
