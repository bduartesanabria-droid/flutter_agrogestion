import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAgroGestionTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AgroColors.primaryContainer,
    onPrimary: Colors.white,
    primaryContainer: AgroColors.secondaryContainer,
    onPrimaryContainer: AgroColors.primary,
    secondary: AgroColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AgroColors.secondaryContainer,
    onSecondaryContainer: AgroColors.onSecondaryContainer,
    tertiary: AgroColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: AgroColors.tertiaryFixed,
    onTertiaryContainer: AgroColors.tertiary,
    error: AgroColors.error,
    onError: Colors.white,
    errorContainer: AgroColors.errorContainer,
    onErrorContainer: AgroColors.onErrorContainer,
    surface: AgroColors.surface,
    onSurface: AgroColors.onSurface,
    onSurfaceVariant: AgroColors.onSurfaceVariant,
    outline: AgroColors.outline,
    outlineVariant: AgroColors.outlineVariant,
    surfaceTint: AgroColors.primaryContainer,
    surfaceContainerLowest: AgroColors.surfaceLowest,
    surfaceContainerLow: AgroColors.surfaceLow,
    surfaceContainer: AgroColors.surfaceMid,
    surfaceContainerHigh: AgroColors.surfaceHigh,
    surfaceContainerHighest: AgroColors.surfaceHighest,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AgroRadius.lg),
    borderSide: const BorderSide(color: AgroColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AgroColors.surface,
    fontFamily: 'PlusJakartaSans',
    textTheme: const TextTheme(
      headlineLarge: AgroText.headlineXl,
      headlineMedium: AgroText.headlineLg,
      headlineSmall: AgroText.headlineMd,
      titleLarge: AgroText.headlineMd,
      titleMedium: AgroText.labelMd,
      bodyLarge: AgroText.bodyLg,
      bodyMedium: AgroText.bodyMd,
      bodySmall: AgroText.bodySm,
      labelLarge: AgroText.labelMd,
      labelSmall: AgroText.labelSm,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AgroColors.surface,
      foregroundColor: AgroColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AgroColors.surfaceLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: AgroText.bodyMd.copyWith(color: AgroColors.outline),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(
          color: AgroColors.primaryContainer,
          width: 2,
        ),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AgroColors.error),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AgroColors.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        backgroundColor: AgroColors.primaryContainer,
        foregroundColor: Colors.white,
        textStyle: AgroText.labelMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AgroRadius.lg),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        foregroundColor: AgroColors.primaryContainer,
        textStyle: AgroText.labelMd,
        side: const BorderSide(color: AgroColors.primaryContainer, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AgroRadius.lg),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AgroColors.primaryContainer,
        textStyle: AgroText.labelMd,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AgroColors.primaryContainer,
      foregroundColor: Colors.white,
      extendedTextStyle: AgroText.labelMd.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AgroRadius.lg),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AgroColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AgroColors.surfaceLowest,
      modalBackgroundColor: AgroColors.surfaceLowest,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AgroRadius.xl),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AgroColors.onSurface,
      contentTextStyle: AgroText.bodyMd.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AgroRadius.md),
      ),
    ),
  );
}
