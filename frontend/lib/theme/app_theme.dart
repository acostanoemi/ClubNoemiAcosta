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
  final Color accentText; // accent usado como TEXTO/ícono (precios, badges,
  // nav activo) — en modo claro el lima puro se lee mal sobre blanco, así
  // que acá va una versión más oscura. El acento como FONDO de botón sigue
  // siendo `accent` en los dos temas (ese sí funciona bien siempre).
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
    required this.accentText,
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
    accentText: Color(0xFFD4FF00), // sobre fondo oscuro el lima puro se lee bien
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
    accentText: Color(0xFF5E7000), // versión oscura del lima, legible sobre blanco
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
    Color? accentText,
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
      accentText: accentText ?? this.accentText,
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
      accentText: Color.lerp(accentText, other.accentText, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
    );
  }
}

/// Atajo para no escribir Theme.of(context).extension<AppColors>()! en cada pantalla.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Transición de página compartida por toda la app: la pantalla nueva entra
/// deslizando desde la derecha con un fade rápido al inicio, y la pantalla
/// anterior se corre levemente hacia la izquierda (efecto parallax), como
/// un push nativo de iOS/Android — en vez del fade plano/instantáneo que
/// trae Flutter Web por defecto en target linux/desktop.
///
/// Se aplica una sola vez acá, vía ThemeData.pageTransitionsTheme, y cubre
/// automáticamente TODA navegación con Navigator.push/pushNamed/
/// pushReplacementNamed/pushNamedAndRemoveUntil/MaterialPageRoute en toda
/// la app — no hace falta tocar cada pantalla.
class AppSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entrada = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final salida = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    final deslizeEntrada = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(entrada);
    final deslizeSalida = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.22, 0)).animate(salida);
    final fadeEntrada = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.35)));

    return SlideTransition(
      position: deslizeSalida,
      child: SlideTransition(
        position: deslizeEntrada,
        child: FadeTransition(opacity: fadeEntrada, child: child),
      ),
    );
  }
}

const _appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: AppSlidePageTransitionsBuilder(),
    TargetPlatform.iOS: AppSlidePageTransitionsBuilder(),
    TargetPlatform.linux: AppSlidePageTransitionsBuilder(),
    TargetPlatform.macOS: AppSlidePageTransitionsBuilder(),
    TargetPlatform.windows: AppSlidePageTransitionsBuilder(),
    TargetPlatform.fuchsia: AppSlidePageTransitionsBuilder(),
  },
);

ThemeData buildDarkTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.dark.background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.dark.accent,
      surface: AppColors.dark.background,
    ),
    pageTransitionsTheme: _appPageTransitionsTheme,
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
    pageTransitionsTheme: _appPageTransitionsTheme,
    extensions: const [AppColors.light],
  );
}
