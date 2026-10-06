import 'package:flutter/material.dart';

/// 预设主题色（用户可在「我的」页一键切换）。
const Color kDefaultSeed = Color(0xFFEC4899);

/// 卡片圆角半径：各页卡片共用，保证圆角一致。
const double kCardRadius = 16;

/// 底部导航外层胶囊的圆角：NavigationBar 高 68，取半高即胶囊形。
const double kNavBarRadius = 34;

/// 底部导航悬浮在内容上方时，内容底部需预留的高度：
/// 导航高 68 + 上边距 8 + 下边距 12 = 88（系统底部安全区另算）。
const double kNavOverlaySpace = 88;

/// 底部导航悬浮时，内容底部需预留的总高度（含系统底部安全区）。
double bottomNavClearance(BuildContext context) =>
    kNavOverlaySpace + MediaQuery.paddingOf(context).bottom;

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

/// 输入框圆角。
const _inputRadius = BorderRadius.all(Radius.circular(12));

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
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
    // 转场用透明底：FadeForwards 默认会垫一块不透明的 surface 色防止页面间露黑，
    // 但本 app 自带全屏背景，垫上它反而会在跳转时盖住自定义背景造成「闪白」。
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android:
            FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
        TargetPlatform.iOS:
            FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
        TargetPlatform.macOS:
            FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
        TargetPlatform.windows:
            FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
        TargetPlatform.linux:
            FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
      },
    ),
  );
}
