import 'package:flutter/material.dart';

/// ins 风主题：玫瑰粉主色，大圆角、低阴影、留白多。
const _seed = Color(0xFFEC4899);

/// 卡片圆角。
const _cardRadius = BorderRadius.all(Radius.circular(16));

/// 输入框圆角。
const _inputRadius = BorderRadius.all(Radius.circular(12));

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seed);
  return _base(scheme).copyWith(
    scaffoldBackgroundColor: const Color(0xFFFDF8FB),
    // 卡片用纯白，和偏暖白的背景拉开层次。
    colorScheme: scheme.copyWith(surface: Colors.white),
  );
}

ThemeData buildDarkTheme() {
  final scheme =
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
  return _base(scheme).copyWith(
    scaffoldBackgroundColor: const Color(0xFF191216),
  );
}

ThemeData _base(ColorScheme scheme) {
  OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: side,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
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
      color: scheme.surface,
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
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
