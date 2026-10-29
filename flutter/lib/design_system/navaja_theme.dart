import 'package:flutter/material.dart';

abstract final class NavajaColors {
  static const ground = Color(0xFF0A0A0B);
  static const surface = Color(0xFF161618);
  static const surfaceRaised = Color(0xFF1F1F22);
  static const hairline = Color(0x14FFFFFF);
  static const ink = Color(0xFFF5F2EC);
  static const inkSecondary = Color(0x94F5F2EC);
  static const inkTertiary = Color(0x4DF5F2EC);
  static const tint = Color(0xFFD93A26);
  static const tintText = Color(0xFFEC7C6C);
  static const tintSoft = Color(0x33D93A26);
  static const open = Color(0xFF4ADE80);
  static const warning = Color(0xFFFFB048);
  static const barberTones = <Color>[
    Color(0xFF6B261C),
    Color(0xFF214538),
    Color(0xFF3B3057),
  ];

  static Color barberTone(int index) => barberTones[index % barberTones.length];
}

abstract final class NavajaSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const gutter = 20.0;
  static const lg = 24.0;
  static const section = 34.0;
}

abstract final class NavajaRadii {
  static const control = 18.0;
  static const compactCard = 24.0;
  static const card = 26.0;
  static const sheet = 36.0;
}

abstract final class NavajaMotion {
  static const snappy = Duration(milliseconds: 320);
  static const gentle = Duration(milliseconds: 500);
  static const page = Duration(milliseconds: 450);
  static const stagger = Duration(milliseconds: 70);
  static const pressScale = 0.96;
  static const snappyCurve = Curves.easeOutBack;
  static const gentleCurve = Curves.easeOutCubic;
  static const pageCurve = Curves.easeInOutCubic;
}

abstract final class NavajaText {
  static TextStyle display(double size, {Color color = NavajaColors.ink}) =>
      TextStyle(
        fontFamily: 'BricolageGrotesque',
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 0.98,
        color: color,
      );

  static TextStyle numeral(double size, {Color color = NavajaColors.ink}) =>
      TextStyle(
        fontFamily: 'BricolageGrotesque',
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

abstract final class NavajaTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: NavajaColors.ground,
    colorScheme: const ColorScheme.dark(
      primary: NavajaColors.tint,
      onPrimary: Colors.white,
      surface: NavajaColors.surface,
      onSurface: NavajaColors.ink,
      error: NavajaColors.warning,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: NavajaColors.ink, fontSize: 17),
      bodyMedium: TextStyle(color: NavajaColors.ink, fontSize: 15),
      bodySmall: TextStyle(color: NavajaColors.inkSecondary, fontSize: 13),
      headlineSmall: TextStyle(
        color: NavajaColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: NavajaColors.hairline,
  );
}
