import 'package:flutter/material.dart';

/// Colores propios de la app que no entran en el ColorScheme de Material.
/// Un solo lugar con los valores actuales (extraídos de shared_widgets.dart
/// y main.dart, que hoy los tenían hardcodeados) más un primer intento de
/// paleta clara — a ajustar cuando tengamos las pantallas Figma en modo día.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface; // fondo de inputs/cards
  final Color surfaceBorder;
  final Color bottomSheetBackground;
  final Color textPrimary;
  final Color textSecondary; // ~45% alpha original
  final Color textMuted; // ~30% alpha original
  final Color accent;
  final Color overlayScrim; // gradiente sobre imágenes de fondo (AppBackground)

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.bottomSheetBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.overlayScrim,
  });

  static const dark = AppColors(
    background: Color(0xFF050508),
    surface: Color(0x14FFFFFF), // white 8%
    surfaceBorder: Color(0x24FFFFFF), // white 14%
    bottomSheetBackground: Color(0xFF0B0B10),
    textPrimary: Colors.white,
    textSecondary: Color(0x73FFFFFF), // white 45%
    textMuted: Color(0x4DFFFFFF), // white 30%
    accent: Color(0xFFD4FF00),
    overlayScrim: Color(0xE0000000), // black 88%
  );

  static const light = AppColors(
    background: Color(0xFFF4F4F6),
    surface: Color(0x0A000000), // black 4%
    surfaceBorder: Color(0x1F000000), // black 12%
    bottomSheetBackground: Colors.white,
    textPrimary: Color(0xFF0A0A0C),
    textSecondary: Color(0x99000000), // black 60%
    textMuted: Color(0x66000000), // black 40%
    accent: Color(0xFFD4FF00),
    overlayScrim: Color(0xE0FFFFFF), // white 88% — provisorio, ajustar con Figma claro
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceBorder,
    Color? bottomSheetBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? overlayScrim,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      bottomSheetBackground: bottomSheetBackground ?? this.bottomSheetBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      overlayScrim: overlayScrim ?? this.overlayScrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      bottomSheetBackground: Color.lerp(bottomSheetBackground, other.bottomSheetBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
    );
  }
}

/// Atajo para no escribir Theme.of(context).extension<AppColors>()! en cada pantalla.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildDarkTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.dark.background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.dark.accent,
      surface: AppColors.dark.background,
    ),
    extensions: const [AppColors.dark],
  );
}

ThemeData buildLightTheme() {
  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.light.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.light.accent,
      surface: AppColors.light.background,
    ),
    extensions: const [AppColors.light],
  );
}