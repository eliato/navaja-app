import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_system/navaja_theme.dart';
import 'root_screen.dart';

class NavajaApp extends StatelessWidget {
  const NavajaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navaja',
      debugShowCheckedModeBanner: false,
      theme: NavajaTheme.dark,
      themeMode: ThemeMode.dark,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: NavajaColors.ground,
        ),
        child: child!,
      ),
      home: const RootScreen(),
    );
  }
}
