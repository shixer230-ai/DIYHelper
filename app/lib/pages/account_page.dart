import 'package:flutter/material.dart';

import '../cloud/auth_service.dart';
import '../theme/app_theme.dart';

/// 登录 / 注册页：登录用「用户名/邮箱 + 密码」；注册用「邮箱 + 用户名 + 密码 + 验证码」。
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController(); // 登录：用户名 / 邮箱
  final _emailCtrl = TextEditingController(); // 注册：邮箱
  final _usernameCtrl = TextEditingController(); // 注册：用户名
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController(); // 注册：验证码

  bool _isRegister = false;
  bool _busy = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_isRegister) {
        if (!_codeSent) {
          // 第一步：发验证码到邮箱。
          await AuthService.instance.sendSignUpCode(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
          );
          setState(() => _codeSent = true);
          _snack('验证码已发送到邮箱，请查收');
        } else {
          // 第二步：填验证码完成注册。
          await AuthService.instance.confirmSignUp(_codeCtrl.text.trim());
          if (mounted) Navigator.pop(context);
        }
      } else {
        await AuthService.instance.signIn(
          account: _accountCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _codeSent = false;
      _codeCtrl.clear();
    });
  }

  String? _validateEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '请输入邮箱';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    return ok ? null : '邮箱格式不对';
  }

  String? _validateUsername(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '请输入用户名';
    // 与云端规则一致：小写字母开头，6~25 位，仅限小写字母/数字/下划线/连字符。
    return RegExp(r'^[a-z][0-9a-z_-]{5,24}$').hasMatch(t)
        ? null
        : '小写字母开头，6~25 位，仅限小写字母/数字/下划线/连字符';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? '注册账号' : '登录')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _isRegister
                  ? '注册后即可把整机方案同步到云端'
                  : '登录后同步你的方案与账号资料',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_isRegister) ...[
              _field(_emailCtrl, '邮箱 *', '用于收验证码，例如 you@example.com',
                  validator: _validateEmail),
              const SizedBox(height: 12),
              _field(_usernameCtrl, '用户名 *', '小写字母开头，6~25位，可用字母/数字/_/-',
                  validator: _validateUsername),
            ] else ...[
              _field(_accountCtrl, '用户名 / 邮箱 *', '',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请输入用户名或邮箱' : null),
            ],
            const SizedBox(height: 12),
            _field(_passwordCtrl, '密码 *', '至少 6 位',
                obscure: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? '密码至少 6 位' : null),
            if (_isRegister && _codeSent) ...[
              const SizedBox(height: 12),
              _field(_codeCtrl, '邮箱验证码 *', '6 位数字',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请输入验证码' : null),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: capsuleButtonStyle(theme),
              child: Text(
                _busy
                    ? '处理中…'
                    : _isRegister
                        ? (_codeSent ? '注册' : '发送验证码')
                        : '登录',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _toggleMode,
              child: Text(_isRegister ? '已有账号？去登录' : '没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
    );
  }
}
