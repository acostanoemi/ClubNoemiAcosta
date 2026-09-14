import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? id;
  static String? email;
  static String? nombre;
  static String? apellido;

  static const _kId = 'session_id';
  static const _kEmail = 'session_email';
  static const _kNombre = 'session_nombre';
  static const _kApellido = 'session_apellido';

  static void set({
    required String id,
    required String email,
    required String nombre,
    required String apellido,
  }) {
    Session.id = id;
    Session.email = email;
    Session.nombre = nombre;
    Session.apellido = apellido;
    _guardar();
  }

  static bool get estaLogueado => email != null;

  static void clear() {
    id = null;
    email = null;
    nombre = null;
    apellido = null;
    _borrar();
  }

  /// Guarda la sesión actual en disco. Se llama sola desde set(),
  /// pero también se puede llamar aparte si se actualiza algún
  /// campo suelto (ej. tras editar el perfil).
  static Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, id ?? '');
    await prefs.setString(_kEmail, email ?? '');
    await prefs.setString(_kNombre, nombre ?? '');
    await prefs.setString(_kApellido, apellido ?? '');
  }

  static Future<void> _borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kNombre);
    await prefs.remove(_kApellido);
  }

  /// Carga la sesión guardada desde disco, si existe. Se llama una
  /// sola vez al arrancar la app, antes de decidir a qué pantalla ir.
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmail);
    if (savedEmail == null || savedEmail.isEmpty) return;

    id = prefs.getString(_kId);
    email = savedEmail;
    nombre = prefs.getString(_kNombre);
    apellido = prefs.getString(_kApellido);
  }
}
