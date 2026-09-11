class Sede {
  final String id;
  final String nombre;
  final String direccion;
  final String horaApertura;
  final String horaCierre;
  final bool activa;

  Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.horaApertura,
    required this.horaCierre,
    required this.activa,
  });

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      horaApertura: json['hora_apertura']?.toString() ?? '',
      horaCierre: json['hora_cierre']?.toString() ?? '',
      activa: json['activa'] ?? true,
    );
  }
}
