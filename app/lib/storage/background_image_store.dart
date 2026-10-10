import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 把用户选的背景图复制到应用文档目录（固定前缀 `custom_background.`），
/// 这样重启后仍能加载，且换图时旧的会被自动清掉
class BackgroundImageStore {
  static const _prefix = 'custom_background.';

  static Future<String> saveImage(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    await _deleteExisting(dir);
    final ext = _extensionOf(file.path);
    // 文件名带时间戳保证唯一：Flutter 的图片缓存按「路径」命中，
    // 若换图后路径不变会继续显示上一张，导致「更换背景」看起来无效
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final dest = File('${dir.path}/$_prefix$stamp.$ext');
    await dest.writeAsBytes(await file.readAsBytes());
    return dest.path;
  }

  /// 找到已保存的背景图路径；没有则返回 null
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
