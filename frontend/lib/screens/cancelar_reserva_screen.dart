import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../session.dart';
import 'mis_reservas_screen.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class CancelarReservaScreen extends StatefulWidget {
  final ReservaConDetalle item;

  const CancelarReservaScreen({super.key, required this.item});

  @override
  State<CancelarReservaScreen> createState() => _CancelarReservaScreenState();
}

class _CancelarReservaScreenState extends State<CancelarReservaScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _confirmarCancelacion() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.delete(Uri.parse('$_apiBaseUrl/reservas/${widget.item.reserva.id}'), headers: Session.authHeader);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'No pudimos cancelar la reserva');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reserva = widget.item.reserva;
    final sedeNombre = widget.item.sede?.nombre ?? 'Sede';
    final espacioNombre = widget.item.espacio?.nombre ?? reserva.espacioId;
    final deporte = widget.item.espacio?.deporte ?? '';

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
              Text('¿Querés cancelar la reserva?', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'El espacio quedará liberado inmediatamente para otros jugadores. Esta acción no se puede revertir.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
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
                              Text('Sede $sedeNombre', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                              Text(espacioNombre, style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'monospace')),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: colors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(formatearFechaCorta(reserva.fecha), style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                                  const SizedBox(width: 10),
                                  Icon(Icons.access_time, size: 12, color: colors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('${reserva.horaInicio.substring(0, 5)} – ${reserva.horaFin.substring(0, 5)}', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: colors.surfaceBorder),
                    const SizedBox(height: 12),
                    Text(formatearMonto(reserva.montoTotal), style: TextStyle(color: colors.accentText, fontSize: 22, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Colors.red[300], fontFamily: 'Inter', fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmarCancelacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Cancelar reserva', style: TextStyle(fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Volver', style: TextStyle(fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
