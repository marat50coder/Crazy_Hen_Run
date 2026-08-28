import 'package:flutter/material.dart';

/// Meadow colours sampled from the Crazy Hen Run artwork.
class Meadow {
  const Meadow._();

  static const Color forest = Color(0xFF0E4429);
  static const Color forestDeep = Color(0xFF02311D);
  static const Color moss = Color(0xFF2F7D4F);
  static const Color lime = Color(0xFF8FD13F);
  static const Color limeSoft = Color(0xFFCBE86D);
  static const Color corn = Color(0xFFFFC72C);
  static const Color yolk = Color(0xFFF6A21E);
  static const Color comb = Color(0xFFE4443A);
  static const Color blush = Color(0xFFF7A8B8);
  static const Color sky = Color(0xFF6FB3E0);
  static const Color lavender = Color(0xFF9B8CE0);
  static const Color sunset = Color(0xFFFF8A5B);
  static const Color cream = Color(0xFFFAF6E9);
}

/// Accent colours a user can pick for individual habits.
class HabitSwatches {
  const HabitSwatches._();

  static const List<Color> swatches = <Color>[
    Meadow.lime,
    Meadow.moss,
    Meadow.corn,
    Meadow.sunset,
    Meadow.comb,
    Meadow.blush,
    Meadow.lavender,
    Meadow.sky,
    Color(0xFF17BEBB),
    Color(0xFF7A5C3E),
  ];

  static Color at(int index) => swatches[index % swatches.length];
}

/// Semantic colours resolved per brightness, exposed through [ThemeExtension]
/// so screens never branch on `Theme.of(context).brightness` by hand.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.canvas,
    required this.canvasAlt,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceInverse,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInverse,
    required this.accent,
    required this.accentSoft,
    required this.positive,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  final Color canvas;
  final Color canvasAlt;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceInverse;
  final Color outline;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textInverse;
  final Color accent;
  final Color accentSoft;
  final Color positive;
  final Color warning;
  final Color danger;
  final Color shadow;

  static const Palette light = Palette(
    canvas: Color(0xFFF5F7F0),
    canvasAlt: Color(0xFFEDF1E4),
    surface: Colors.white,
    surfaceMuted: Color(0xFFF0F3EA),
    surfaceInverse: Meadow.forest,
    outline: Color(0xFFE3E8DA),
    outlineStrong: Color(0xFFCBD3BE),
    textPrimary: Color(0xFF102117),
    textSecondary: Color(0xFF6C7A6E),
    textInverse: Color(0xFFF4FBF2),
    accent: Meadow.moss,
    accentSoft: Color(0xFFE3F3E3),
    positive: Color(0xFF3F9D5B),
    warning: Meadow.yolk,
    danger: Meadow.comb,
    shadow: Color(0x1A0E4429),
  );

  static const Palette dark = Palette(
    canvas: Color(0xFF0B1310),
    canvasAlt: Color(0xFF101B16),
    surface: Color(0xFF15221C),
    surfaceMuted: Color(0xFF1B2A23),
    surfaceInverse: Meadow.limeSoft,
    outline: Color(0xFF243429),
    outlineStrong: Color(0xFF32473A),
    textPrimary: Color(0xFFEDF5EE),
    textSecondary: Color(0xFF93A69A),
    textInverse: Color(0xFF07130D),
    accent: Meadow.lime,
    accentSoft: Color(0xFF1D3226),
    positive: Color(0xFF64C97F),
    warning: Meadow.corn,
    danger: Color(0xFFFF6B60),
    shadow: Color(0x66000000),
  );

  @override
  Palette copyWith({
    Color? canvas,
    Color? canvasAlt,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceInverse,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textInverse,
    Color? accent,
    Color? accentSoft,
    Color? positive,
    Color? warning,
    Color? danger,
    Color? shadow,
  }) {
    return Palette(
      canvas: canvas ?? this.canvas,
      canvasAlt: canvasAlt ?? this.canvasAlt,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textInverse: textInverse ?? this.textInverse,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      positive: positive ?? this.positive,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    return Palette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      canvasAlt: Color.lerp(canvasAlt, other.canvasAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
