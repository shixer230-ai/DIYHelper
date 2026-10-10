import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:flutter/foundation.dart';

/// CloudBase 全局实例：启动时初始化一次，其它地方通过 [CloudApp.app] 取用
/// 环境 ID、地域在这里统一维护
class CloudApp {
  CloudApp._();

  /// 环境 ID（「环境总览」页可查）
  static const String _env = 'diyhelper-d4g1qnj5l0db7d16e';

  static CloudBase? _app;

  static bool get isReady => _app != null;

  /// 初始化（main() 里调用一次）；失败不抛出，后续用时再提示
  static Future<void> init() async {
    try {
      _app = await CloudBase.init(
        env: _env,
        region: 'ap-shanghai',
      );
    } catch (e) {
      debugPrint('CloudBase 初始化失败：$e');
    }
  }

  /// 获取全局 app 实例；未初始化时抛出，调用方先用 [isReady] 判断
  static CloudBase get app {
    final a = _app;
    if (a == null) {
      throw StateError('CloudBase 尚未初始化，请先调用 CloudApp.init()');
    }
    return a;
  }
}
