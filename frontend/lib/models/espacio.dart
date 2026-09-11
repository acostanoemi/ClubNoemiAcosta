class Espacio {
  final String id;
  final String sedeId;
  final String nombre;
  final String deporte;
  final double precioPorHora;
  final String? subcategoria;
  final String? ambiente;
  final bool iluminada;
  final String? horaApertura;
  final String? horaCierre;
  final bool activo;

  Espacio({
    required this.id,
    required this.sedeId,
    required this.nombre,
    required this.deporte,
    required this.precioPorHora,
    this.subcategoria,
    this.ambiente,
    this.iluminada = false,
    this.horaApertura,
    this.horaCierre,
    required this.activo,
  });

  factory Espacio.fromJson(Map<String, dynamic> json) {
    return Espacio(
      id: json['id'].toString(),
      sedeId: json['sede_id'].toString(),
      nombre: json['nombre'] ?? '',
      deporte: json['deporte'] ?? '',
      precioPorHora: (json['precio_por_hora'] as num?)?.toDouble() ?? 0,
      subcategoria: json['subcategoria'],
      ambiente: json['ambiente'],
      iluminada: json['iluminada'] ?? false,
      horaApertura: json['hora_apertura']?.toString(),
      horaCierre: json['hora_cierre']?.toString(),
      activo: json['activo'] ?? true,
    );
  }
}