// DIYHelper —— DIY 硬件性价比助手
// 版本：1.1.0 Beta
// 设计与创作：CreativeDesign ZkeRurQwQ · 蓝色大肥鱼Accomplish
// 版权署名，请勿盗用。

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  runApp(const DiyHelperApp());
}

class DiyHelperApp extends StatelessWidget {
  const DiyHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final c = ThemeController.instance;
        return MaterialApp(
          title: 'DIY 硬件性价比助手',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(
            seed: c.seed,
            transparentBackground: c.hasBackground,
          ),
          darkTheme: buildDarkTheme(
            seed: c.seed,
            transparentBackground: c.hasBackground,
          ),
          themeMode: c.mode,
          builder: (context, child) => _AppBackground(
            path: c.backgroundPath,
            blur: c.backgroundBlur,
            child: child,
          ),
          home: const HomeShell(),
        );
      },
    );
  }
}

/// 全屏背景层：有背景图时铺满并可选模糊，再叠半透明遮罩保证文字可读。
class _AppBackground extends StatelessWidget {
  const _AppBackground({
    required this.path,
    required this.blur,
    required this.child,
  });

  final String? path;
  final bool blur;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (path == null) return child ?? const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    Widget image = Image.file(File(path!), fit: BoxFit.cover);
    if (blur) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: image,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        // 遮罩：模糊开时图像已柔化，遮罩更淡；模糊关时遮罩略重，保证卡片/文字可读。
        ColoredBox(
          color: scheme.surface.withValues(alpha: blur ? 0.35 : 0.55),
        ),
        child ?? const SizedBox.shrink(),
      ],
    );
  }
}
