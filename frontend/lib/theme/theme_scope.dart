import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// Expone el ThemeController a toda la app vía InheritedNotifier.
/// Cualquier pantalla puede leer el modo actual o togglearlo con
/// ThemeScope.of(context), sin pasar el controller a mano.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope.of() llamado sin un ThemeScope en el árbol');
    return scope!.notifier!;
  }
}