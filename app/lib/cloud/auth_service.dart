import 'dart:io';

import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../storage/avatar_image_store.dart';
import '../theme/theme_controller.dart';
import 'cloud_app.dart';

/// 云端账号状态：登录 / 注册 / 登出，以及当前用户信息。单例，变更后通知监听者。
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? _user;

  /// 注册第二步要用到的验证回调（第一步发送验证码时暂存）。
  Future<SignInRes> Function(VerifyOtpParams)? _pendingVerify;

  /// 当前登录用户。
  User? get user => _user;

  bool get isLoggedIn => _user != null;

  /// 用户名（登录标识）。
  String? get username => _user?.userMetadata?.username;

  /// 昵称（展示用，注册时先取用户名）。
  String? get nickname => _user?.userMetadata?.nickName ?? _user?.userMetadata?.username;

  /// 云端头像（可能是 fileId 或临时链接）。
  String? get avatarUrl => _user?.userMetadata?.avatarUrl;

  /// 当前登录用户的稳定 ID（云端方案归属 `owner` 用）。
  String? get uid => _user?.id;

  /// 登录/注册/恢复会话后，若本地昵称仍是默认值则同步为云端用户名。
  void _adoptNickname() {
    final name = nickname;
    if (name == null || name.isEmpty) return;
    ThemeController.instance.adoptNicknameIfDefault(name);
  }

  /// 登录/注册/恢复会话后，把云端头像下载到本地展示（若账号里有头像）。
  void _syncAvatar() {
    final fileId = avatarUrl;
    if (fileId == null || !fileId.startsWith('cloud://')) return;
    _doSyncAvatar(fileId);
  }

  Future<void> _doSyncAvatar(String fileId) async {
    try {
      final storage = CloudApp.app.storage.from();
      final res = await storage.getDownloadUrls([fileId], expiresIn: 3600);
      final url = res.data?.first.downloadUrl;
      if (url == null || url.isEmpty) return;
      final bytes = await _downloadBytes(url);
      final path = await AvatarImageStore.saveBytes(bytes, _extOf(fileId));
      await ThemeController.instance.setAvatar(path);
    } catch (_) {
      // 头像同步失败不阻塞登录，保持默认头像。
    }
  }

  /// 用 dart:io 拉取图片字节（云存储签名链接）。
  static Future<List<int>> _downloadBytes(String url) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw Exception('头像下载失败 HTTP ${res.statusCode}');
      }
      final bytes = <int>[];
      await for (final chunk in res) {
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      client.close();
    }
  }

  /// 从 fileId 里取图片扩展名，取不到默认 jpg。
  static String _extOf(String fileId) {
    final name = fileId.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot > 0 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    return 'jpg';
  }

  /// 启动时恢复已有会话（若之前登录过且 token 未过期）。
  Future<void> restore() async {
    if (!CloudApp.isReady) return;
    try {
      final res = await CloudApp.app.auth.getSession();
      _user = res.data?.user ?? res.data?.session?.user;
      notifyListeners();
      _adoptNickname();
      _syncAvatar();
    } catch (_) {
      // 未登录 / 无网络，保持未登录即可。
    }
  }

  /// 登录：自动识别邮箱还是用户名。
  Future<void> signIn({required String account, required String password}) async {
    final req = account.contains('@')
        ? SignInWithPasswordReq(email: account, password: password)
        : SignInWithPasswordReq(username: account, password: password);
    final res = await CloudApp.app.auth.signInWithPassword(req);
    if (res.error != null) throw Exception(res.error!.message);
    _user = res.data?.user ?? res.data?.session?.user;
    notifyListeners();
    _adoptNickname();
    _syncAvatar();
  }

  /// 注册第一步：向邮箱发送验证码，验证回调暂存。
  Future<void> sendSignUpCode({
    required String email,
    required String password,
    required String username,
  }) async {
    final res = await CloudApp.app.auth.signUp(
      SignUpReq(
        email: email,
        password: password,
        username: username,
        nickname: username,
      ),
    );
    if (res.error != null) throw Exception(res.error!.message);
    _pendingVerify = res.data?.verifyOtp;
    if (_pendingVerify == null) {
      throw Exception('发送验证码失败，请检查邮箱是否正确');
    }
  }

  /// 注册第二步：用验证码完成注册并登录。
  Future<void> confirmSignUp(String code) async {
    final verify = _pendingVerify;
    if (verify == null) throw StateError('请先点击「发送验证码」');
    final res = await verify(VerifyOtpParams(token: code));
    if (res.error != null) throw Exception(res.error!.message);
    _pendingVerify = null;
    _user = res.data?.user ?? res.data?.session?.user;
    notifyListeners();
    _adoptNickname();
    _syncAvatar();
  }

  /// 登出。
  Future<void> signOut() async {
    await CloudApp.app.auth.signOut();
    _user = null;
    _pendingVerify = null;
    notifyListeners();
  }

  /// 重新拉取当前用户资料（例如头像上传后刷新）。
  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final res = await CloudApp.app.auth.getUser();
      _user = res.data?.user ?? _user;
      notifyListeners();
    } catch (_) {
      // 拉取失败保持现状。
    }
  }
}
