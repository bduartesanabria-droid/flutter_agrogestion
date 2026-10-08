import 'package:flutter/material.dart';

class AgroColors {
  const AgroColors._();

  static const surface = Color(0xFFF0FDF2);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFEAF7ED);
  static const surfaceMid = Color(0xFFE4F1E7);
  static const surfaceHigh = Color(0xFFDEEBE1);
  static const surfaceHighest = Color(0xFFD9E6DC);
  static const onSurface = Color(0xFF131E18);
  static const onSurfaceVariant = Color(0xFF3F4943);
  static const outline = Color(0xFF6F7A73);
  static const outlineVariant = Color(0xFFBEC9C1);
  static const primary = Color(0xFF005138);
  static const primaryContainer = Color(0xFF176B4D);
  static const onPrimaryContainer = Color(0xFF9AE9C3);
  static const secondary = Color(0xFF2F6952);
  static const secondaryContainer = Color(0xFFB0EDD0);
  static const onSecondaryContainer = Color(0xFF346D56);
  static const tertiary = Color(0xFF6E3900);
  static const tertiaryContainer = Color(0xFF904D00);
  static const tertiaryFixed = Color(0xFFFFDCC3);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const info = Color(0xFF1D4ED8);
  static const infoContainer = Color(0xFFDBE6FE);
  static const success = Color(0xFF047857);
  static const border = Color(0xFFBEC9C1);
}

class AgroSpace {
  const AgroSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double touch = 48;
  static const double fabClearance = 96;
}

class AgroRadius {
  const AgroRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class AgroShadows {
  const AgroShadows._();

  static const level1 = [
    BoxShadow(
      color: Color(0x0D17221C),
      blurRadius: 8,
      spreadRadius: -2,
      offset: Offset(0, 2),
    ),
  ];
  static const level2 = [
    BoxShadow(
      color: Color(0x14176B4D),
      blurRadius: 20,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];
  static const level3 = [
    BoxShadow(
      color: Color(0x29104E39),
      blurRadius: 36,
      spreadRadius: -6,
      offset: Offset(0, 16),
    ),
  ];
}

class AgroText {
  const AgroText._();

  static const _sans = 'PlusJakartaSans';
  static const _mono = 'JetBrainsMono';
  static const _tabular = [FontFeature.tabularFigures()];

  static const headlineXl = TextStyle(
    fontFamily: _sans,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.64,
    color: AgroColors.onSurface,
  );
  static const headlineLg = TextStyle(
    fontFamily: _sans,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.39,
    color: AgroColors.onSurface,
  );
  static const headlineMd = TextStyle(
    fontFamily: _sans,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AgroColors.onSurface,
  );
  static const bodyLg = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AgroColors.onSurface,
  );
  static const bodyMd = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AgroColors.onSurface,
  );
  static const bodySm = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: AgroColors.onSurfaceVariant,
  );
  static const labelMd = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    color: AgroColors.onSurface,
  );
  static const labelSm = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.55,
    color: AgroColors.onSurfaceVariant,
  );
  static const monoXl = TextStyle(
    fontFamily: _mono,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.72,
    color: AgroColors.onSurface,
    fontFeatures: _tabular,
  );
  static const monoMd = TextStyle(
    fontFamily: _mono,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.32,
    color: AgroColors.onSurface,
    fontFeatures: _tabular,
  );
  static const monoSm = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AgroColors.onSurfaceVariant,
    fontFeatures: _tabular,
  );
}
