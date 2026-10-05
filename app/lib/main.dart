import 'package:flutter/material.dart';

import 'pages/home_shell.dart';

void main() {
  runApp(const DiyHelperApp());
}

class DiyHelperApp extends StatelessWidget {
  const DiyHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIY 硬件性价比助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2962FF)),
      ),
      home: const HomeShell(),
    );
  }
}
