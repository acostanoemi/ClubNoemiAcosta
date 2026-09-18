import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla el modo de tema (claro/oscuro) de toda la app. Arranca en
/// oscuro por defecto, pero persiste la eleccion del usuario con
/// SharedPreferences (mismo criterio que la sesion).
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  static const _kModo = 'theme_mode_dark';

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _guardar();
  }

  void setDark(bool dark) {
    final newMode = dark ? ThemeMode.dark : ThemeMode.light;
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
    _guardar();
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kModo, isDark);
  }

  /// Carga la preferencia guardada desde disco, si existe. Se llama una
  /// sola vez al arrancar la app, antes de construir el MaterialApp.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final guardadoOscuro = prefs.getBool(_kModo);
    if (guardadoOscuro == null) return;
    _mode = guardadoOscuro ? ThemeMode.dark : ThemeMode.light;
  }
}
