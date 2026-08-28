import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

class Corners {
  const Corners._();

  static const double xs = 10;
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 36;
  static const double pill = 999;
}

class Insets {
  const Insets._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 44;
}

class HenyardTheme {
  const HenyardTheme._();

  static const String fontFamily = 'SpaceGrotesk';

  static ThemeData light(Color seed) => _build(Palette.light, seed, Brightness.light);

  static ThemeData dark(Color seed) => _build(Palette.dark, seed, Brightness.dark);

  static ThemeData _build(Palette base, Color seed, Brightness brightness) {
    final colors = base.copyWith(
      accent: seed,
      accentSoft: brightness == Brightness.light
          ? Color.alphaBlend(seed.withValues(alpha: 0.14), Colors.white)
          : Color.alphaBlend(seed.withValues(alpha: 0.20), base.canvas),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      surface: colors.surface,
      primary: colors.accent,
      onPrimary: _onColor(colors.accent),
      onSurface: colors.textPrimary,
      outline: colors.outline,
      error: colors.danger,
    );

    final textTheme = _textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      fontFamily: fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colors.textPrimary),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.canvas,
                systemNavigationBarIconBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.canvas,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
      ),
      dividerTheme: DividerThemeData(color: colors.outline, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: _onColor(colors.accent),
          minimumSize: const Size.fromHeight(56),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: colors.outlineStrong),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide(color: colors.accent, width: 1.6),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _onColor(colors.accent)
              : colors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.outlineStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        inactiveTrackColor: colors.outline,
        thumbColor: colors.accent,
        overlayColor: colors.accent.withValues(alpha: 0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceInverse,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.textInverse),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.sm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.lg),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static Color _onColor(Color background) =>
      background.computeLuminance() > 0.55 ? const Color(0xFF102117) : Colors.white;

  static TextTheme _textTheme(Palette c) {
    TextStyle base(double size, FontWeight weight, {double? height, double? spacing}) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: c.textPrimary,
      );
    }

    return TextTheme(
      displayLarge: base(42, FontWeight.w800, height: 1.05, spacing: -1.2),
      displayMedium: base(34, FontWeight.w800, height: 1.08, spacing: -0.9),
      displaySmall: base(28, FontWeight.w700, height: 1.12, spacing: -0.6),
      headlineMedium: base(24, FontWeight.w700, height: 1.18, spacing: -0.4),
      headlineSmall: base(20, FontWeight.w700, height: 1.2, spacing: -0.2),
      titleLarge: base(18, FontWeight.w600, height: 1.25),
      titleMedium: base(16, FontWeight.w600, height: 1.3),
      titleSmall: base(14, FontWeight.w600, height: 1.3),
      bodyLarge: base(16, FontWeight.w400, height: 1.45).copyWith(color: c.textPrimary),
      bodyMedium: base(14, FontWeight.w400, height: 1.5).copyWith(color: c.textSecondary),
      bodySmall: base(12.5, FontWeight.w400, height: 1.45).copyWith(color: c.textSecondary),
      labelLarge: base(15, FontWeight.w600, spacing: 0.1),
      labelMedium: base(13, FontWeight.w600, spacing: 0.2),
      labelSmall: base(11, FontWeight.w600, spacing: 0.8).copyWith(color: c.textSecondary),
    );
  }
}
