import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/ai_analysis.dart';
import '../theme/app_theme.dart';

/// AI 分析结果页：拿到云函数返回的全文后，逐字打字机展示（闪烁光标）。
class AiAnalysisPage extends StatefulWidget {
  const AiAnalysisPage({
    super.key,
    required this.title,
    required this.prompt,
    this.mode = 'general',
  });

  /// 方案名（用于标题）。
  final String title;

  /// 已拼好的完整提示词（含方案信息）。
  final String prompt;

  /// 分析类型：'general'（常规）或 'reliability'（可靠性）。
  final String mode;

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  final _scroll = ScrollController();
  Timer? _cursorTimer;

  String _text = '';
  String? _error;
  bool _running = false;
  bool _cursorOn = false;

  /// 是否自动滚到底部：用户上滑时暂停，滑回底部再恢复。
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _start();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final atBottom = _scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 24;
    if (_autoScroll != atBottom && mounted) {
      setState(() => _autoScroll = atBottom);
    }
  }

  Future<void> _start() async {
    setState(() {
      _text = '';
      _error = null;
      _running = true;
      _cursorOn = true;
      _autoScroll = true;
    });
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _cursorOn = !_cursorOn);
    });
    try {
      // 云函数里已完成「登录校验 + 限流 + 调 DeepSeek」，这里只拿最终文本。
      final full = await analyzeViaCloud(widget.prompt, mode: widget.mode);
      if (!mounted) return;
      await _typeOut(full);
      _finish();
    } catch (e) {
      _finish(error: _friendly(e));
    }
  }

  /// 拿到全文后逐字打字机展示，模拟流式输出，避免一次性把整段生硬地弹出来。
  Future<void> _typeOut(String full) async {
    const step = 2; // 每帧推进 2 个字
    const delay = Duration(milliseconds: 18);
    for (var i = 0; i < full.length; i += step) {
      if (!mounted) return;
      final end = i + step < full.length ? i + step : full.length;
      setState(() => _text = full.substring(0, end));
      _scrollToEnd();
      await Future<void>.delayed(delay);
    }
    if (mounted) setState(() => _text = full);
  }

  void _finish({String? error}) {
    if (!mounted) return;
    _cursorTimer?.cancel();
    _cursorTimer = null;
    setState(() {
      _running = false;
      _error = error;
    });
  }

  void _scrollToEnd() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  String _friendly(Object e) {
    final s = e.toString().replaceFirst('Exception: ', '');
    if (s.contains('登录')) return '需要登录后才能使用 AI 分析，请先在「我的」页登录';
    if (s.contains('次数已用完')) return s;
    if (s.contains('FUNCTION') || s.contains('不存在') || s.contains('not found')) {
      return 'AI 云函数未部署，请先在云开发控制台部署 aiChat 函数';
    }
    if (s.contains('余额') || s.contains('402')) return 'DeepSeek 账户余额不足，请先充值';
    if (s.contains('Key') || s.contains('401')) return 'AI 接口 Key 未配置或无效';
    if (s.contains('SocketException') ||
        s.contains('Connection') ||
        s.contains('网络') ||
        s.contains('timeout') ||
        s.contains('超时')) {
      return '网络连接失败，请检查网络后重试';
    }
    return '分析失败：$s';
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finishedEmpty = !_running && _error == null && _text.isEmpty;
    final cursor = _running && _cursorOn ? '▍' : '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.mode == 'reliability' ? '可靠性分析' : 'AI 分析'} · ${widget.title}',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                child: _error != null
                    ? _errorView(theme)
                    : Text(
                        finishedEmpty ? 'AI 没有返回内容，请重试' : '$_text$cursor',
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),
              ),
            ),
          ),
          if (_running)
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 4),
              child: Text(
                'AI 正在分析…',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _running ? null : _start,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新分析'),
                      style: capsuleOutlinedButtonStyle(theme),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _text.isEmpty ? null : () => _copy(_text),
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                      style: capsuleButtonStyle(theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
        const SizedBox(height: 8),
        Text(_error!, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已复制分析结果')));
  }
}
