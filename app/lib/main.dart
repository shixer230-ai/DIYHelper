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
        return MaterialApp(
          title: 'DIY 硬件性价比助手',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ThemeController.instance.mode,
          home: const HomeShell(),
        );
      },
    );
  }
}
