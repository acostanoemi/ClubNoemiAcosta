class Espacio {
  final String id;
  final String sedeId;
  final String nombre;
  final String deporte;
  final double precioPorHora;
  final bool activo;

  Espacio({
    required this.id,
    required this.sedeId,
    required this.nombre,
    required this.deporte,
    required this.precioPorHora,
    required this.activo,
  });

  factory Espacio.fromJson(Map<String, dynamic> json) {
    return Espacio(
      id: json['id'].toString(),
      sedeId: json['sede_id'].toString(),
      nombre: json['nombre'] ?? '',
      deporte: json['deporte'] ?? '',
      precioPorHora: (json['precio_por_hora'] as num?)?.toDouble() ?? 0,
      activo: json['activo'] ?? true,
    );
  }
}