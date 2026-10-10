import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 把用户选的头像复制到应用文档目录（固定前缀 `custom_avatar.`），
/// 这样重启后仍能加载，且换头像时旧的会被自动清掉
class AvatarImageStore {
  static const _prefix = 'custom_avatar.';

  static Future<String> saveImage(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    await _deleteExisting(dir);
    final ext = _extensionOf(file.path);
    // 文件名带时间戳保证唯一，避免换头像后路径不变导致图片缓存命中旧图
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final dest = File('${dir.path}/$_prefix$stamp.$ext');
    await dest.writeAsBytes(await file.readAsBytes());
    return dest.path;
  }

  /// 从云端下载头像时用
  static Future<String> saveBytes(List<int> bytes, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    await _deleteExisting(dir);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final dest = File('${dir.path}/$_prefix$stamp.$ext');
    await dest.writeAsBytes(bytes);
    return dest.path;
  }

  /// 找到已保存的头像路径；没有则返回 null
  static Future<String?> storedImagePath() async {
    final dir = await getApplicationDocumentsDirectory();
    for (final e in dir.listSync()) {
      if (e is File && e.uri.pathSegments.last.startsWith(_prefix)) {
        return e.path;
      }
    }
    return null;
  }

  static Future<void> delete() async {
    final dir = await getApplicationDocumentsDirectory();
    await _deleteExisting(dir);
  }

  static Future<void> _deleteExisting(Directory dir) async {
    for (final e in dir.listSync()) {
      if (e is File && e.uri.pathSegments.last.startsWith(_prefix)) {
        await e.delete();
      }
    }
  }

  static String _extensionOf(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot > 0 && dot < name.length - 1) return name.substring(dot + 1);
    return 'jpg';
  }
}
