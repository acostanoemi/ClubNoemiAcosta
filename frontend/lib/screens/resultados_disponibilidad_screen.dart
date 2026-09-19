import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../models/reserva.dart';
import 'mis_reservas_screen.dart' show formatearFechaCorta, formatearMonto;
import 'confirmar_reserva_screen.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class ResultadosDisponibilidadScreen extends StatefulWidget {
  final Sede sede;
  final String deporte;
  final DateTime fecha;
  final int horaInicio;
  final int horaFin;
  final String tipoCanchaInicial;

  const ResultadosDisponibilidadScreen({
    super.key,
    required this.sede,
    required this.deporte,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.tipoCanchaInicial,
  });

  @override
  State<ResultadosDisponibilidadScreen> createState() => _ResultadosDisponibilidadScreenState();
}

class _ResultadosDisponibilidadScreenState extends State<ResultadosDisponibilidadScreen> {
  bool _cargando = true;
  bool _error = false;
  List<Espacio> _disponibles = [];
  late String _tipoCancha;

  @override
  void initState() {
    super.initState();
    _tipoCancha = widget.tipoCanchaInicial;
    _consultar();
  }

  Future<void> _consultar() async {
    setState(() {
      _cargando = true;
      _error = false;
    });

    try {
      final resEspacios = await http.get(Uri.parse('$_apiBaseUrl/espacios?sede_id=${widget.sede.id}'));
      if (resEspacios.statusCode != 200) throw Exception();

      final List espaciosJson = jsonDecode(resEspacios.body);
      final candidatos = espaciosJson
          .map((e) => Espacio.fromJson(e))
          .where((e) => e.activo && e.deporte == widget.deporte)
          .toList();

      final fechaStr = widget.fecha.toIso8601String().split('T').first;
      final disponibles = <Espacio>[];

      for (final espacio in candidatos) {
        final resReservas = await http.get(Uri.parse('$_apiBaseUrl/reservas?espacio_id=${espacio.id}&fecha=$fechaStr'));
        if (resReservas.statusCode != 200) continue;

        final List reservasJson = jsonDecode(resReservas.body);
        final reservas = reservasJson.map((r) => Reserva.fromJson(r)).toList();

        final libre = reservas.every((r) {
          final inicioR = int.tryParse(r.horaInicio.split(':')[0]) ?? 0;
          final finR = int.tryParse(r.horaFin.split(':')[0]) ?? 0;
          return widget.horaInicio >= finR || inicioR >= widget.horaFin;
        });

        if (libre) disponibles.add(espacio);
      }

      if (!mounted) return;
      setState(() => _disponibles = disponibles);
    } catch (e) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Map<String, int> get _conteosPorTipo {
    final conteos = <String, int>{'Todas': _disponibles.length};
    for (final e in _disponibles) {
      final tipo = e.subcategoria ?? e.deporte;
      conteos[tipo] = (conteos[tipo] ?? 0) + 1;
    }
    return conteos;
  }

  List<Espacio> get _disponiblesFiltrados {
    if (_tipoCancha == 'Todas') return _disponibles;
    return _disponibles.where((e) => (e.subcategoria ?? e.deporte) == _tipoCancha).toList();
  }

  void _reservar(Espacio espacio) {
    final duracion = widget.horaFin - widget.horaInicio;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConfirmarReservaScreen(
        sede: widget.sede,
        espacio: espacio,
        fecha: widget.fecha,
        horaInicio: widget.horaInicio,
        duracionHoras: duracion,
        total: espacio.precioPorHora * duracion,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipos = ['Todas', ..._conteosPorTipo.keys.where((t) => t != 'Todas')];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                  Text('CANCHAS DISPONIBLES', style: TextStyle(color: colors.textPrimary, fontSize: 26, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.sede.nombre} · ${widget.deporte} · ${formatearFechaCorta(widget.fecha)} · ${widget.horaInicio.toString().padLeft(2, '0')}:00 a ${widget.horaFin.toString().padLeft(2, '0')}:00',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 16),
                  if (!_cargando && !_error)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tipos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final t = tipos[i];
                          final activo = t == _tipoCancha;
                          final conteo = _conteosPorTipo[t] ?? 0;
                          return GestureDetector(
                            onTap: () => setState(() => _tipoCancha = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: activo ? colors.accent : colors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text('$t ($conteo)', style: TextStyle(color: activo ? Colors.black : colors.textSecondary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: _cargando
                  ? Center(child: CircularProgressIndicator(color: colors.accent))
                  : _error
                      ? _estadoError(colors)
                      : _disponiblesFiltrados.isEmpty
                          ? _estadoVacio(colors)
                          : _listaResultados(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoError(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NO SE PUDO CONSULTAR', style: TextStyle(color: Colors.red[300], fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('No se pudo consultar la disponibilidad', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('Revisá tu conexión e intentá nuevamente. Los filtros ingresados se mantienen cargados.', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _consultar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoVacio(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.accentText, width: 1.5)),
              child: Icon(Icons.search, color: colors.accentText, size: 32),
            ),
            const SizedBox(height: 20),
            Text('SIN CANCHAS DISPONIBLES', style: TextStyle(color: colors.accentText, fontSize: 20, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'No encontramos canchas libres para ese horario. Probá cambiar la fecha, la hora o el tipo de cancha.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Modificar búsqueda', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaResultados(AppColors colors) {
    final lista = _disponiblesFiltrados;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      itemCount: lista.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${lista.length} canchas disponibles', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
          );
        }
        final espacio = lista[i - 1];
        final total = espacio.precioPorHora * (widget.horaFin - widget.horaInicio);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(widget.sede.nombre, style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800))),
                    Text('Disponible', style: TextStyle(color: colors.accentText, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                  ],
                ),
                Text(espacio.nombre, style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'monospace')),
                Text(widget.sede.direccion, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                const SizedBox(height: 10),
                Divider(height: 1, color: colors.surfaceBorder),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(formatearFechaCorta(widget.fecha), style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time, size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${widget.horaInicio.toString().padLeft(2, '0')}:00–${widget.horaFin.toString().padLeft(2, '0')}:00', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                    const Spacer(),
                    Text(formatearMonto(total), style: TextStyle(color: colors.accentText, fontSize: 16, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _reservar(espacio),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Reservar', style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
