import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import 'resultados_disponibilidad_screen.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class ConsultarCanchasScreen extends StatefulWidget {
  const ConsultarCanchasScreen({super.key});

  @override
  State<ConsultarCanchasScreen> createState() => _ConsultarCanchasScreenState();
}

class _ConsultarCanchasScreenState extends State<ConsultarCanchasScreen> {
  List<Sede> _sedes = [];
  List<Espacio> _espacios = [];
  bool _cargando = true;

  Sede? _sedeSeleccionada;
  String? _deporteSeleccionado;
  DateTime _fecha = DateTime.now();
  int? _horaInicio;
  int? _horaFin;
  String _tipoCancha = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final resSedes = await http.get(Uri.parse('$_apiBaseUrl/sedes'));
      final resEspacios = await http.get(Uri.parse('$_apiBaseUrl/espacios'));
      if (resSedes.statusCode == 200 && resEspacios.statusCode == 200) {
        final List sedesJson = jsonDecode(resSedes.body);
        final List espaciosJson = jsonDecode(resEspacios.body);
        setState(() {
          _sedes = sedesJson.map((s) => Sede.fromJson(s)).where((s) => s.activa).toList();
          _espacios = espaciosJson.map((e) => Espacio.fromJson(e)).where((e) => e.activo).toList();
        });
      }
    } catch (e) {
      // Si falla, el formulario queda vacío — el usuario puede reintentar
      // recargando la pantalla; no hace falta un estado de error dedicado
      // acá, el que importa es el de la consulta en sí (pantalla siguiente).
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> get _deportesDisponibles {
    if (_sedeSeleccionada == null) return [];
    return _espacios.where((e) => e.sedeId == _sedeSeleccionada!.id).map((e) => e.deporte).toSet().toList();
  }

  List<String> get _tiposDisponibles {
    if (_sedeSeleccionada == null || _deporteSeleccionado == null) return [];
    return _espacios
        .where((e) => e.sedeId == _sedeSeleccionada!.id && e.deporte == _deporteSeleccionado)
        .map((e) => e.subcategoria)
        .whereType<String>()
        .toSet()
        .toList();
  }

  bool get _puedeConsultar =>
      _sedeSeleccionada != null && _deporteSeleccionado != null && _horaInicio != null && _horaFin != null && _horaFin! > _horaInicio!;

  void _limpiarFiltros() {
    setState(() {
      _sedeSeleccionada = null;
      _deporteSeleccionado = null;
      _fecha = DateTime.now();
      _horaInicio = null;
      _horaFin = null;
      _tipoCancha = 'Todas';
    });
  }

  Future<void> _elegirSede() async {
    final elegida = await showModalBottomSheet<Sede>(
      context: context,
      backgroundColor: context.colors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _listaOpciones(
        titulo: 'Elegí una sede',
        opciones: _sedes.map((s) => s.nombre).toList(),
        onElegir: (nombre) => Navigator.pop(context, _sedes.firstWhere((s) => s.nombre == nombre)),
      ),
    );
    if (elegida != null) {
      setState(() {
        _sedeSeleccionada = elegida;
        _deporteSeleccionado = null;
        _tipoCancha = 'Todas';
      });
    }
  }

  Future<void> _elegirDeporte() async {
    final opciones = _deportesDisponibles;
    if (opciones.isEmpty) return;
    final elegido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _listaOpciones(
        titulo: 'Elegí un deporte',
        opciones: opciones,
        onElegir: (v) => Navigator.pop(context, v),
      ),
    );
    if (elegido != null) {
      setState(() {
        _deporteSeleccionado = elegido;
        _tipoCancha = 'Todas';
      });
    }
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: buildDarkTheme(),
          child: child!,
        );
      },
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _elegirHora(bool esInicio) async {
    int minima = 6;
    int maxima = 23;
    if (_sedeSeleccionada != null) {
      minima = int.tryParse(_sedeSeleccionada!.horaApertura.split(':').first) ?? minima;
      maxima = int.tryParse(_sedeSeleccionada!.horaCierre.split(':').first) ?? maxima;
    }
    final horas = [for (int h = minima; h <= maxima; h++) h];

    final elegida = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.colors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final colors = context.colors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(esInicio ? 'Hora de inicio' : 'Hora de fin', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: horas.map((h) {
                    final texto = '${h.toString().padLeft(2, '0')}:00';
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, h),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(10)),
                        child: Text(texto, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (elegida != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = elegida;
          if (_horaFin != null && _horaFin! <= elegida) _horaFin = null;
        } else {
          _horaFin = elegida;
        }
      });
    }
  }

  Widget _listaOpciones({required String titulo, required List<String> opciones, required ValueChanged<String> onElegir}) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...opciones.map((o) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o, style: TextStyle(color: colors.textPrimary, fontFamily: 'Inter')),
                  onTap: () => onElegir(o),
                )),
          ],
        ),
      ),
    );
  }

  void _consultar() {
    if (!_puedeConsultar) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultadosDisponibilidadScreen(
        sede: _sedeSeleccionada!,
        deporte: _deporteSeleccionado!,
        fecha: _fecha,
        horaInicio: _horaInicio!,
        horaFin: _horaFin!,
        tipoCanchaInicial: _tipoCancha,
      ),
    ));
  }

  String _formatearFecha(DateTime f) {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[f.weekday - 1]}, ${f.day} ${meses[f.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              Text('CONSULTAR CANCHAS', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Elegí sede, deporte, fecha y horario para ver disponibilidad.', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
              const SizedBox(height: 24),
              if (_cargando)
                Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator(color: colors.accent)))
              else ...[
                _campoLabel(colors, 'SEDE'),
                _campoSeleccionable(colors, _sedeSeleccionada?.nombre, 'Elegí una sede', _elegirSede),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _campoLabel(colors, 'DEPORTE'),
                          _campoSeleccionable(colors, _deporteSeleccionado, 'Deporte', _elegirDeporte, habilitado: _sedeSeleccionada != null),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _campoLabel(colors, 'FECHA'),
                          _campoSeleccionable(colors, _formatearFecha(_fecha), null, _elegirFecha, icono: Icons.calendar_today),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _campoLabel(colors, 'HORA INICIO'),
                          _campoSeleccionable(colors, _horaInicio != null ? '${_horaInicio!.toString().padLeft(2, '0')}:00' : null, '--:--', () => _elegirHora(true), icono: Icons.access_time),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _campoLabel(colors, 'HORA FIN'),
                          _campoSeleccionable(colors, _horaFin != null ? '${_horaFin!.toString().padLeft(2, '0')}:00' : null, '--:--', () => _elegirHora(false), icono: Icons.access_time, habilitado: _horaInicio != null),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _campoLabel(colors, 'TIPO DE CANCHA'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Todas', ..._tiposDisponibles].map((t) {
                    final activo = t == _tipoCancha;
                    return GestureDetector(
                      onTap: () => setState(() => _tipoCancha = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: activo ? colors.accent : colors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t, style: TextStyle(color: activo ? Colors.black : colors.textSecondary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _puedeConsultar ? _consultar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      disabledBackgroundColor: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Consultar disponibilidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _puedeConsultar ? Colors.black : colors.textMuted, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _limpiarFiltros,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Limpiar filtros', style: TextStyle(fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoLabel(AppColors colors, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto, style: TextStyle(color: colors.accentText, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }

  Widget _campoSeleccionable(AppColors colors, String? valor, String? placeholder, VoidCallback onTap, {IconData? icono, bool habilitado = true}) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: habilitado ? colors.surface : colors.surface.withValues(alpha: colors.surface.a * 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          children: [
            if (icono != null) ...[
              Icon(icono, size: 16, color: colors.textMuted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                valor ?? (placeholder ?? ''),
                style: TextStyle(color: valor != null ? colors.textPrimary : colors.textMuted, fontSize: 15, fontFamily: 'Inter', fontWeight: valor != null ? FontWeight.w600 : FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
