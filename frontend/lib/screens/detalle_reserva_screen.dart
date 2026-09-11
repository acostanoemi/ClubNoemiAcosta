import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mis_reservas_screen.dart';
import 'cancelar_reserva_screen.dart';

const _diasLargos = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _mesesLargos = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

String _formatearFechaLarga(DateTime f) => '${_diasLargos[f.weekday - 1]} ${f.day} de ${_mesesLargos[f.month - 1]}';

class DetalleReservaScreen extends StatelessWidget {
  final ReservaConDetalle item;

  const DetalleReservaScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reserva = item.reserva;
    final sedeNombre = item.sede?.nombre ?? 'Sede';
    final espacioNombre = item.espacio?.nombre ?? reserva.espacioId;
    final deporte = item.espacio?.deporte ?? '';
    final ambiente = item.espacio?.ambiente;
    final direccion = item.sede != null ? '${item.sede!.direccion}, ${item.sede!.nombre}' : '—';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
                  child: Icon(Icons.chevron_left, color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'DETALLE DE ', style: TextStyle(color: colors.textPrimary)),
                    TextSpan(text: 'LA RESERVA', style: TextStyle(color: colors.accent)),
                  ],
                ),
                style: const TextStyle(fontSize: 30, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, height: 1.1),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (item.esActiva ? colors.accent : Colors.green).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: item.esActiva ? colors.accent : Colors.green[400], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      item.esActiva ? 'Activa' : 'Completada',
                      style: TextStyle(color: item.esActiva ? colors.accent : Colors.green[400], fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: colors.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                          child: Icon(iconoDeporte(deporte), color: colors.accent, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sede $sedeNombre', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                              Text(espacioNombre, style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: colors.surfaceBorder),
                    const SizedBox(height: 12),
                    _filaDato(colors, 'Fecha', _formatearFechaLarga(reserva.fecha)),
                    _filaDato(colors, 'Horario', '${reserva.horaInicio.substring(0, 5)} a ${reserva.horaFin.substring(0, 5)}'),
                    _filaDato(colors, 'Espacio', ambiente != null ? '$deporte · $ambiente' : deporte),
                    _filaDato(colors, 'Dirección', direccion),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: colors.surfaceBorder),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter')),
                        Text(formatearMonto(reserva.montoTotal), style: TextStyle(color: colors.accent, fontSize: 26, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.esActiva) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () async {
                      final cancelada = await Navigator.of(context).push<bool>(MaterialPageRoute(
                        builder: (_) => CancelarReservaScreen(item: item),
                      ));
                      if (cancelada == true && context.mounted) Navigator.pop(context, true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[300],
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 18, color: Colors.red[300]),
                        const SizedBox(width: 8),
                        Text('Cancelar reserva', style: TextStyle(color: Colors.red[300], fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaDato(AppColors colors, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter')),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
