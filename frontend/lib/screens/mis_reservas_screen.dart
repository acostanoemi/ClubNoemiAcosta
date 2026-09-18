import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/reserva.dart';
import '../models/espacio.dart';
import '../models/sede.dart';
import '../session.dart';
import 'detalle_reserva_screen.dart';
import 'cancelar_reserva_screen.dart';

const String _apiBaseUrl = "http://localhost:8000";

const _diasCortos = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _mesesCortos = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String formatearFechaCorta(DateTime f) => '${_diasCortos[f.weekday - 1]}, ${f.day} ${_mesesCortos[f.month - 1]}';

String formatearMonto(double m) {
  final entero = m.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
    buffer.write(entero[i]);
  }
  return '\$ ${buffer.toString()}';
}

IconData iconoDeporte(String deporte) {
  switch (deporte) {
    case 'Fútbol':
      return Icons.sports_soccer;
    case 'Tenis':
      return Icons.sports_tennis;
    case 'Golf':
      return Icons.sports_golf;
    case 'Hockey':
      return Icons.sports_hockey;
    case 'Vóley':
      return Icons.sports_volleyball;
    default:
      return Icons.sports;
  }
}

/// Agrupa una reserva con la cancha y sede a la que pertenece, ya resueltas
/// (el backend solo devuelve espacio_id en /reservas, así que se cruza acá).
class ReservaConDetalle {
  final Reserva reserva;
  final Espacio? espacio;
  final Sede? sede;

  ReservaConDetalle({required this.reserva, this.espacio, this.sede});

  bool get esActiva {
    if (reserva.estado == 'cancelada') return false;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return !reserva.fecha.isBefore(hoySinHora);
  }

  bool get estaCancelada => reserva.estado == 'cancelada';
}

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  List<ReservaConDetalle> _reservas = [];
  bool _loading = true;
  String? _error;
  bool _tabProximas = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resReservas = await http.get(Uri.parse('$_apiBaseUrl/reservas?usuario_id=${Session.id}&incluir_canceladas=true'));
      final resEspacios = await http.get(Uri.parse('$_apiBaseUrl/espacios'));
      final resSedes = await http.get(Uri.parse('$_apiBaseUrl/sedes'));

      if (resReservas.statusCode == 200 && resEspacios.statusCode == 200 && resSedes.statusCode == 200) {
        final List reservasJson = jsonDecode(resReservas.body);
        final List espaciosJson = jsonDecode(resEspacios.body);
        final List sedesJson = jsonDecode(resSedes.body);

        final espacios = {for (var e in espaciosJson) e['id'].toString(): Espacio.fromJson(e)};
        final sedes = {for (var s in sedesJson) s['id'].toString(): Sede.fromJson(s)};

        final lista = reservasJson.map<ReservaConDetalle>((r) {
          final reserva = Reserva.fromJson(r);
          final espacio = espacios[reserva.espacioId];
          final sede = espacio != null ? sedes[espacio.sedeId] : null;
          return ReservaConDetalle(reserva: reserva, espacio: espacio, sede: sede);
        }).toList();

        setState(() => _reservas = lista);
      } else {
        setState(() => _error = 'No pudimos cargar tus reservas');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ReservaConDetalle> get _activas {
    final l = _reservas.where((r) => r.esActiva).toList();
    l.sort((a, b) => a.reserva.fecha.compareTo(b.reserva.fecha));
    return l;
  }

  List<ReservaConDetalle> get _historial {
    final l = _reservas.where((r) => !r.esActiva).toList();
    l.sort((a, b) => b.reserva.fecha.compareTo(a.reserva.fecha));
    return l;
  }

  Future<void> _abrirDetalle(ReservaConDetalle item) async {
    final cancelada = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => DetalleReservaScreen(item: item),
    ));
    if (cancelada == true) _cargarDatos();
  }

  Future<void> _abrirCancelar(ReservaConDetalle item) async {
    final cancelada = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CancelarReservaScreen(item: item),
    ));
    if (cancelada == true) _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!Session.estaLogueado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return Scaffold(backgroundColor: colors.background);
    }

    final lista = _tabProximas ? _activas : _historial;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'MIS ', style: TextStyle(color: colors.textPrimary)),
                            TextSpan(text: 'RESERVAS', style: TextStyle(color: colors.accentText)),
                          ],
                        ),
                        style: const TextStyle(fontSize: 32, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      if (!_loading)
                        Text(
                          '${_activas.length} activas · ${_historial.length} historial',
                          style: TextStyle(color: colors.textMuted, fontSize: 13, fontFamily: 'Inter'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(child: _tabButton(colors, 'Próximas (${_activas.length})', _tabProximas, () => setState(() => _tabProximas = true))),
                        Expanded(child: _tabButton(colors, 'Historial', !_tabProximas, () => setState(() => _tabProximas = false))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: colors.accent)))
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        Text(_error!, style: TextStyle(color: Colors.red[300], fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _cargarDatos, child: Text('Reintentar', style: TextStyle(color: colors.accentText))),
                      ],
                    ),
                  )
                else if (lista.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Text(
                      _tabProximas
                          ? 'No se encontraron próximas reservas asociadas a su cuenta'
                          : 'No se encontraron reservas pasadas asociadas a su cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  ...lista.map((item) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: _reservaCard(colors, item),
                      )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.bottomSheetBackground,
          border: Border(top: BorderSide(color: colors.surfaceBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(colors, Icons.home_outlined, 'INICIO', false, () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false)),
            _navItem(colors, Icons.apartment_outlined, 'SEDES', false, () => Navigator.pushNamed(context, '/sedes')),
            _navItem(colors, Icons.calendar_today, 'RESERVAS', true, () {}),
            _navItem(colors, Icons.person_outline, 'PERFIL', false, () => Navigator.pushNamed(context, '/perfil')),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(AppColors colors, String label, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: activo ? Colors.black : colors.textSecondary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _reservaCard(AppColors colors, ReservaConDetalle item) {
    final sedeNombre = item.sede?.nombre ?? 'Sede';
    final espacioNombre = item.espacio?.nombre ?? item.reserva.espacioId;
    final deporte = item.espacio?.deporte ?? '';

    return GestureDetector(
      onTap: () => _abrirDetalle(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Sede $sedeNombre', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (item.estaCancelada
                                      ? Colors.red
                                      : (item.esActiva ? colors.accent : Colors.green))
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.estaCancelada ? 'Cancelada' : (item.esActiva ? 'Activa' : 'Completada'),
                              style: TextStyle(
                                color: item.estaCancelada
                                    ? Colors.red[300]
                                    : (item.esActiva ? colors.accentText : Colors.green[400]),
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(espacioNombre, style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'monospace')),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(formatearFechaCorta(item.reserva.fecha), style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time, size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${item.reserva.horaInicio.substring(0, 5)} – ${item.reserva.horaFin.substring(0, 5)}', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatearMonto(item.reserva.montoTotal), style: TextStyle(color: colors.accentText, fontSize: 20, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                if (item.esActiva)
                  GestureDetector(
                    onTap: () => _abrirCancelar(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 14, color: Colors.red[300]),
                          const SizedBox(width: 4),
                          Text('Cancelar', style: TextStyle(color: Colors.red[300], fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(AppColors colors, IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? colors.accentText : colors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 24 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: colors.accentText,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
