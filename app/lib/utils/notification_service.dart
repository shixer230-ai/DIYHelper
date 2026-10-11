import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地系统通知：感谢捐赠、硬件库更新等消息
/// 走手机本地通知，不依赖服务器，国内手机也能收到
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;

  /// 启动时初始化：建通知渠道 + 申请通知权限（Android 13+ 需要显式申请）
  Future<void> init() async {
    if (_inited) return;
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: init);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _inited = true;
  }

  /// 弹一条本地通知（标题 + 正文）
  Future<void> show(String title, String body) async {
    if (!_inited) await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default',
        '通知',
        channelDescription: 'DIYAss 的消息通知',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
