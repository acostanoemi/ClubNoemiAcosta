class Reserva {
  final String id;
  final String usuarioId;
  final String espacioId;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final double montoTotal;
  final String estado;

  Reserva({
    required this.id,
    required this.usuarioId,
    required this.espacioId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.montoTotal,
    required this.estado,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'].toString(),
      usuarioId: json['usuario_id'].toString(),
      espacioId: json['espacio_id'].toString(),
      fecha: DateTime.parse(json['fecha']),
      horaInicio: json['hora_inicio']?.toString() ?? '',
      horaFin: json['hora_fin']?.toString() ?? '',
      montoTotal: (json['monto_total'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] ?? '',
    );
  }
}