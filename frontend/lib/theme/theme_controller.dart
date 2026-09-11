import 'package:flutter/material.dart';

/// Controla el modo de tema (claro/oscuro) de toda la app.
/// Vive solo en memoria por ahora: arranca en oscuro y se resetea con
/// cada hot restart, mismo criterio que la sesión (persistencia
/// deprioritizada a propósito).
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setDark(bool dark) {
    final newMode = dark ? ThemeMode.dark : ThemeMode.light;
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
  }
}