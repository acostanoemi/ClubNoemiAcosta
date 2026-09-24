import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? id;
  static String? email;
  static String? nombre;
  static String? apellido;
  static String? token;

  static const _kId = 'session_id';
  static const _kEmail = 'session_email';
  static const _kNombre = 'session_nombre';
  static const _kApellido = 'session_apellido';
  static const _kToken = 'session_token';

  static void set({
    required String id,
    required String email,
    required String nombre,
    required String apellido,
    required String token,
  }) {
    Session.id = id;
    Session.email = email;
    Session.nombre = nombre;
    Session.apellido = apellido;
    Session.token = token;
    _guardar();
  }

  static bool get estaLogueado => email != null;

  static StreamSubscription<User?>? _escuchaToken;

  /// Firebase renueva el ID token solo, mas o menos cada hora. Cada vez
  /// que lo hace, avisa por idTokenChanges() y aca pisamos Session.token.
  /// Asi authHeader sigue siendo sincronico y no hay que tocar las
  /// pantallas que lo usan.
  static void _escucharRenovacionToken() {
    _escuchaToken ??= FirebaseAuth.instance.idTokenChanges().listen((user) async {
      if (user == null) return;
      token = await user.getIdToken();
      _guardar();
    });
  }

  /// Header listo para pegarle a cualquier pedido HTTP protegido.
  static Map<String, String> get authHeader =>
      token != null ? {'Authorization': 'Bearer $token'} : {};

  static void clear() {
    id = null;
    email = null;
    nombre = null;
    apellido = null;
    token = null;
    _borrar();
    FirebaseAuth.instance.signOut();
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
    await prefs.setString(_kToken, token ?? '');
  }

  static Future<void> _borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kNombre);
    await prefs.remove(_kApellido);
    await prefs.remove(_kToken);
  }

  /// Carga la sesión guardada desde disco, si existe. Se llama una
  /// sola vez al arrancar la app, antes de decidir a qué pantalla ir.
  static Future<void> restore() async {
    _escucharRenovacionToken();

    // En web Firebase recupera al usuario de forma asincronica, por eso
    // se espera el primer evento en vez de leer currentUser directo.
    final usuarioFirebase = await FirebaseAuth.instance.authStateChanges().first;

    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmail);
    if (savedEmail == null || savedEmail.isEmpty) return;

    id = prefs.getString(_kId);
    email = savedEmail;
    nombre = prefs.getString(_kNombre);
    apellido = prefs.getString(_kApellido);
    token = prefs.getString(_kToken);

    // Si hay usuario de Firebase, su token manda. Si no, queda el JWT
    // viejo guardado (TEMPORAL, mientras el backend acepte los dos).
    if (usuarioFirebase != null) {
      token = await usuarioFirebase.getIdToken();
    }
  }
}
