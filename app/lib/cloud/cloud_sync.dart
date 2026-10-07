import 'package:cloudbase_flutter/cloudbase_flutter.dart';

import '../models/build_plan.dart';
import 'auth_service.dart';
import 'cloud_app.dart';

/// 云端数据读写：整机方案的上传 / 拉取，以及头像上传到云存储。
class CloudSync {
  const CloudSync._();

  /// 把单个方案上传到云（plans 集合）。
  static Future<void> uploadPlan(BuildPlan plan) async {
    final db = CloudApp.app.database();
    final res = await db.collection('plans').add(plan.toJson());
    if (!res.isSuccess) {
      throw Exception('上传失败：${res.message ?? res.code}');
    }
  }

  /// 从云拉取当前用户的所有方案。
  static Future<List<BuildPlan>> downloadPlans() async {
    final db = CloudApp.app.database();
    final res = await db.collection('plans').get();
    if (!res.isSuccess) {
      throw Exception('拉取失败：${res.message ?? res.code}');
    }
    return res.data.map((e) => BuildPlan.fromJson(e)).toList();
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
