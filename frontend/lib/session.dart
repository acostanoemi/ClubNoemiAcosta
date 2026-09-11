class Session {
  static String? id;
  static String? email;
  static String? nombre;
  static String? apellido;

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
  }

  static bool get estaLogueado => email != null;

  static void clear() {
    id = null;
    email = null;
    nombre = null;
    apellido = null;
  }
}
