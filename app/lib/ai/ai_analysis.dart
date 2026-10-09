import 'dart:convert';

import '../cloud/cloud_app.dart';
import '../models/build_plan.dart';

/// 用户消息最大长度（合规：拦下超长/异常输入，避免把异常内容发给 AI 接口）。
const int kMaxPromptLen = 4000;

/// 把整机方案拼成发给 AI 的用户消息（常规分析）。
///
/// 注意：分析规则（系统提示词）在云函数里，不在这里；这里只负责把方案信息
/// 拼成用户消息，App 端拿不到也看不到任何 API Key。
String buildPlanPrompt(BuildPlan plan) =>
    '请分析下面这套 DIY 整机配置：\n\n${_planBody(plan)}';

/// 把整机方案拼成发给 AI 的用户消息（可靠性分析）。
///
/// 可靠性分析的具体规则在云函数里（mode='reliability' 时切换系统提示词），
/// 这里只负责把方案信息拼成用户消息。
String buildReliabilityPrompt(BuildPlan plan) =>
    '请对下面这套 DIY 整机配置做可靠性分析：\n\n${_planBody(plan)}';

/// 两种分析共用的方案信息正文（配件清单 + 总价 + 功耗）。
String _planBody(BuildPlan plan) {
  final b = StringBuffer();
  for (final c in plan.components.values) {
    final brand = c.brand.isEmpty ? '' : '（${c.brand}）';
    b.writeln('· ${c.category}：${c.model}$brand　¥${_fmtPrice(c.price)}');
  }
  b.writeln();
  b.writeln('整机总价：¥${_fmtPrice(plan.total)}');
  if (plan.customPower != null) {
    b.writeln('自定义整机功耗：${_fmtPrice(plan.customPower!)} W');
  }
  return b.toString();
}

String _fmtPrice(double p) =>
    p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

/// 合规检测：内容为空或过长时拒绝发送，防止把异常输入发给 AI 接口。
void validateAiPrompt(String prompt) {
  final t = prompt.trim();
  if (t.isEmpty) throw Exception('方案内容为空，无法分析');
  if (prompt.length > kMaxPromptLen) throw Exception('方案内容过长，无法分析');
}

/// 调云函数做 AI 分析：云函数里校验登录 + 限流 + 用云端 Key 调 DeepSeek。
/// App 只拿到最终分析文本，Key 不离开云端。
///
/// [mode] 决定分析类型：'general'（默认，常规分析）或 'reliability'（可靠性分析）。
Future<String> analyzeViaCloud(String prompt, {String mode = 'general'}) async {
  validateAiPrompt(prompt);

  final res = await CloudApp.app.callFunction(
    name: 'aiChat',
    data: {'prompt': prompt, 'mode': mode},
  );

  if (!res.isSuccess) {
    throw Exception(res.message ?? '云函数调用失败');
  }

  // 云函数返回 { content } 或 { error }。result 可能是 Map 或 JSON 字符串。
  Map<String, dynamic>? map;
  final result = res.result;
  if (result is Map) {
    map = Map<String, dynamic>.from(result);
  } else if (result is String) {
    try {
      map = jsonDecode(result) as Map<String, dynamic>;
    } catch (_) {
      // 非 JSON 字符串按无结果处理。
    }
  }

  final error = map?['error'];
  if (error is String && error.isNotEmpty) {
    throw Exception(error);
  }
  final content = map?['content'];
  if (content is String && content.isNotEmpty) {
    return content;
  }
  throw Exception('AI 未返回内容，请重试');
}
