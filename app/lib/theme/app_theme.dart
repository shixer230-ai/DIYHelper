import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// 预设主题色（用户可在「我的」页一键切换）。
const Color kDefaultSeed = Color(0xFFEC4899);

/// 卡片圆角半径：各页卡片共用，增大到与底部胶囊导航栏（kNavBarRadius）一致。
const double kCardRadius = 34;

/// 底部导航外层胶囊的圆角：NavigationBar 高 68，取半高即胶囊形。
const double kNavBarRadius = 34;

/// 底部导航悬浮在内容上方时，内容底部需预留的高度：
/// 导航高 68 + 上边距 8 + 下边距 12 = 88（系统底部安全区另算）。
const double kNavOverlaySpace = 88;

/// 底部导航悬浮时，内容底部需预留的总高度（含系统底部安全区）。
double bottomNavClearance(BuildContext context) =>
    kNavOverlaySpace + MediaQuery.paddingOf(context).bottom;

/// 主操作按钮统一风格：胶囊圆角 + 半透明底色（透明圆角），
/// 用于「加入我的清单」「保存到我的清单」等主要按钮，保证观感一致。
ButtonStyle capsuleButtonStyle(ThemeData theme) {
  final scheme = theme.colorScheme;
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
    ),
    backgroundColor: scheme.surface.withValues(alpha: 0.5),
    foregroundColor: scheme.primary,
    disabledBackgroundColor: scheme.surface.withValues(alpha: 0.3),
    disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.4),
  );
}

/// 玻璃风格输入框外壳：半透明磨砂底色 + 细边框，配合 BackdropFilter 模糊，
/// 用于搜索框 / 选择框，与底部液态玻璃导航的「玻璃」质感保持一致。
class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.child,
    this.radius = kNavBarRadius,
  });

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 一个可选的预设主色。
class SeedOption {
  const SeedOption(this.name, this.color);

  final String name;
  final Color color;
}

/// 预设色卡：默认玫瑰粉 + 7 个常用色，贴合国内 app 的柔和配色。
const List<SeedOption> kSeedOptions = [
  SeedOption('玫瑰粉', Color(0xFFEC4899)),
  SeedOption('天空蓝', Color(0xFF3B82F6)),
  SeedOption('青绿', Color(0xFF10B981)),
  SeedOption('活力橙', Color(0xFFF97316)),
  SeedOption('优雅紫', Color(0xFF8B5CF6)),
  SeedOption('热情红', Color(0xFFEF4444)),
  SeedOption('湖水青', Color(0xFF06B6D4)),
  SeedOption('深邃靛', Color(0xFF6366F1)),
];

/// 卡片圆角。
const _cardRadius = BorderRadius.all(Radius.circular(kCardRadius));

/// 输入框圆角：胶囊形（与全站胶囊风格一致，取值足够大保证两端全圆）。
const _inputRadius = BorderRadius.all(Radius.circular(999));

/// 淡入淡出转场（非对称）：
/// - 入栈：新页淡入、旧页淡出（旧页连同底部液态玻璃导航一起淡出，不残留）；
/// - 出栈：当前页淡出，下层旧页保持不透明（玻璃不会「淡入消失」）。
///
/// 旧页用 secondaryAnimation 淡出，但反向（被重新露出）时用阈值曲线立即回到
/// 不透明，从而兼顾「入栈玻璃一起淡出」和「返回时玻璃不闪现」。
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 本页随自身 animation 淡入/淡出（入栈 0→1、出栈 1→0）。
    final incoming = FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );

    // 被新页压住时（secondaryAnimation 0→1）淡出；被重新露出时（1→0）
    // 用 Threshold(1.0) 让中间值直接归 0 → 完全不动，避免玻璃淡入闪现。
    final outgoing = FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOut,
          reverseCurve: const Threshold(1.0),
        ),
      ),
      child: incoming,
    );

    return outgoing;
  }
}

ThemeData buildLightTheme({
  Color seed = kDefaultSeed,
  bool transparentBackground = false,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: seed);
  return _base(scheme, transparentBackground).copyWith(
    scaffoldBackgroundColor:
        transparentBackground ? Colors.transparent : const Color(0xFFFDF8FB),
    // 卡片用纯白，和偏暖白的背景拉开层次。
    colorScheme: scheme.copyWith(surface: Colors.white),
  );
}

ThemeData buildDarkTheme({
  Color seed = kDefaultSeed,
  bool transparentBackground = false,
}) {
  final scheme =
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
  return _base(scheme, transparentBackground).copyWith(
    scaffoldBackgroundColor:
        transparentBackground ? Colors.transparent : const Color(0xFF191216),
  );
}

ThemeData _base(ColorScheme scheme, bool transparentBackground) {
  OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: side,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: transparentBackground
          ? Colors.transparent
          : scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      // 卡片半透明，和「分析项目」输入框一致（fillColor 0.5 透明度），让背景图透出。
      color: scheme.surface.withValues(alpha: 0.5),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      isDense: true,
      border: inputBorder(BorderSide(color: scheme.outlineVariant)),
      enabledBorder: inputBorder(BorderSide(color: scheme.outlineVariant)),
      focusedBorder:
          inputBorder(BorderSide(color: scheme.primary, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        minimumSize: const Size(64, 48),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.primaryContainer,
      // 选中指示器用圆形（内层小圆块）。
      indicatorShape: const CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      // 与卡片 / 主按钮统一：胶囊圆角 + 半透明底色，「保存成功」等提示观感一致。
      backgroundColor: scheme.surface.withValues(alpha: 0.6),
      contentTextStyle: TextStyle(color: scheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kCardRadius)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    // 转场用「纯滑动、无淡入淡出」：既不会因透明底露黑，也不会让页面（含液态玻璃）
    // 在跳转时淡成透明——返回录入页等场景下玻璃不会再短暂消失。
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadePageTransitionsBuilder(),
        TargetPlatform.iOS: FadePageTransitionsBuilder(),
        TargetPlatform.macOS: FadePageTransitionsBuilder(),
        TargetPlatform.windows: FadePageTransitionsBuilder(),
        TargetPlatform.linux: FadePageTransitionsBuilder(),
      },
    ),
  );
}
