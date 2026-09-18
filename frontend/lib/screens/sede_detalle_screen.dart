import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../models/reserva.dart';
import '../theme/app_theme.dart';
import 'horarios_bottom_sheet.dart';

const String _apiBaseUrl = "http://localhost:8000";

String _hhmm(String? hora) => (hora != null && hora.length >= 5) ? hora.substring(0, 5) : (hora ?? '');

class SedeDetalleScreen extends StatefulWidget {
  final Sede sede;
  // Si viene, esta pantalla actúa como "elegí la cancha nueva" dentro del
  // flujo de Modificar Reserva: al elegir horario, en vez de crear una
  // reserva nueva se modifica esta. Ver HorariosBottomSheet para el resto
  // del flujo.
  final Reserva? reservaAModificar;

  const SedeDetalleScreen({super.key, required this.sede, this.reservaAModificar});

  @override
  State<SedeDetalleScreen> createState() => _SedeDetalleScreenState();
}

class _SedeDetalleScreenState extends State<SedeDetalleScreen> {
  List<Espacio> _espacios = [];
  bool _loading = true;
  String? _error;

  String? _deporteSeleccionado;
  String _subcategoriaSeleccionada = 'Todos';

  bool get _modificando => widget.reservaAModificar != null;

  @override
  void initState() {
    super.initState();
    _cargarEspacios();
  }

  Future<void> _cargarEspacios() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/espacios?sede_id=${widget.sede.id}'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final espacios = data.map((e) => Espacio.fromJson(e)).where((e) => e.activo).toList();
        setState(() {
          _espacios = espacios;
          if (espacios.isNotEmpty) {
            // Si estamos modificando una reserva, arrancamos filtrados en el
            // deporte de la cancha actual (más cómodo que arrancar en el
            // primer deporte de la lista, que puede no tener nada que ver).
            if (_modificando) {
              final actual = espacios.where((e) => e.id == widget.reservaAModificar!.espacioId);
              _deporteSeleccionado = actual.isNotEmpty ? actual.first.deporte : espacios.first.deporte;
            } else {
              _deporteSeleccionado = espacios.first.deporte;
            }
          }
        });
      } else {
        setState(() => _error = 'No pudimos cargar las canchas');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _deportes {
    final set = _espacios.map((e) => e.deporte).toSet().toList();
    return set;
  }

  List<Espacio> get _espaciosDelDeporte {
    if (_deporteSeleccionado == null) return [];
    return _espacios.where((e) => e.deporte == _deporteSeleccionado).toList();
  }

  List<String> get _subcategorias {
    final set = _espaciosDelDeporte
        .map((e) => e.subcategoria)
        .whereType<String>()
        .toSet()
        .toList();
    return ['Todos', ...set];
  }

  List<Espacio> get _espaciosFiltrados {
    if (_subcategoriaSeleccionada == 'Todos') return _espaciosDelDeporte;
    return _espaciosDelDeporte.where((e) => e.subcategoria == _subcategoriaSeleccionada).toList();
  }

  void _seleccionarDeporte(String d) {
    setState(() {
      _deporteSeleccionado = d;
      _subcategoriaSeleccionada = 'Todos';
    });
  }

  Future<void> _abrirHorarios(Espacio espacio) async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HorariosBottomSheet(sede: widget.sede, espacio: espacio, reservaAModificar: widget.reservaAModificar),
    );
    // Si HorariosBottomSheet guardó los cambios (modo edición), avisamos
    // hacia arriba en la pila para que el Detalle/Listado de reservas refresque.
    if (resultado == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Hero — foto real de la sede si existe, si no cae en la genérica.
            // Queda siempre oscuro (foto + overlay), igual en los dos temas.
            Stack(
              children: [
                Image.asset(fotoParaSede(widget.sede.id), fit: BoxFit.cover, width: double.infinity, height: 165),
                Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.55))),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.55), size: 20),
                        Text('Sedes', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_modificando) ...[
                    Text('MODIFICANDO RESERVA', style: TextStyle(color: colors.accent, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 2)),
                    const SizedBox(height: 4),
                  ],
                  if (_deporteSeleccionado != null)
                    Text(
                      _subcategoriaSeleccionada == 'Todos'
                          ? _deporteSeleccionado!.toUpperCase()
                          : '${_deporteSeleccionado!.toUpperCase()} · ${_subcategoriaSeleccionada.toUpperCase()}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 2),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    'SEDE ${widget.sede.nombre.toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900),
                  ),
                ],
              ),
                ),
              ],
            ),

            // Contenido — sigue el tema (a diferencia del hero, que queda fijo oscuro).
            Expanded(
              child: Container(
                width: double.infinity,
                color: colors.bottomSheetBackground,
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: colors.accent))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 8),
                                TextButton(onPressed: _cargarEspacios, child: const Text('Reintentar')),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _deportes.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, i) {
                                      final d = _deportes[i];
                                      final activo = d == _deporteSeleccionado;
                                      return GestureDetector(
                                        onTap: () => _seleccionarDeporte(d),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: activo ? colors.accent : colors.surface,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: activo ? colors.accent : colors.surfaceBorder),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            d,
                                            style: TextStyle(
                                              color: activo ? Colors.black : colors.textPrimary,
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 34,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _subcategorias.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, i) {
                                      final s = _subcategorias[i];
                                      final activo = s == _subcategoriaSeleccionada;
                                      return GestureDetector(
                                        onTap: () => setState(() => _subcategoriaSeleccionada = s),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: activo ? colors.accent : colors.surface,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              color: activo ? Colors.black : colors.textPrimary,
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                              fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    '${_espaciosFiltrados.length} cancha${_espaciosFiltrados.length == 1 ? '' : 's'} · ${_deporteSeleccionado ?? ''}',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._espaciosFiltrados.map((e) => Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colors.surface,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: colors.surfaceBorder),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 150,
                                              width: double.infinity,
                                              color: colors.surfaceBorder,
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Image.asset(fotoParaCancha(e.id), fit: BoxFit.cover),
                                                  ),
                                                  Positioned.fill(
                                                    child: Container(color: Colors.black.withValues(alpha: 0.20)),
                                                  ),
                                                  Positioned(
                                                    top: 10,
                                                    left: 10,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(8)),
                                                      child: Text(e.subcategoria ?? e.deporte, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 10,
                                                    bottom: 8,
                                                    child: Text(e.nombre, style: TextStyle(color: colors.accent, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          _tagChip(colors, e.ambiente == 'Outdoor' ? '☀ Outdoor' : '🏢 Indoor'),
                                                          if (e.iluminada) ...[
                                                            const SizedBox(width: 6),
                                                            _tagChip(colors, '💡 Iluminada'),
                                                          ],
                                                        ],
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text('\$ ${e.precioPorHora.round()}', style: TextStyle(color: colors.textPrimary, fontSize: 17, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                                          Text('/ hora', style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter')),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.access_time, size: 13, color: colors.textMuted),
                                                      const SizedBox(width: 4),
                                                      Text('${_hhmm(e.horaApertura)} - ${_hhmm(e.horaCierre)}', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    height: 46,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => _abrirHorarios(e),
                                                      icon: const Icon(Icons.bolt, size: 18, color: Colors.black),
                                                      label: Text(
                                                        _modificando ? 'ELEGIR ESTA CANCHA' : 'VER HORARIOS / RESERVAR',
                                                        style: const TextStyle(color: Colors.black, fontSize: 13, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: colors.accent,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: 90),
                              ],
                            ),
                          ),
              ),
            ),
          ],
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
            _navItem(colors, Icons.apartment, 'SEDES', true, () => Navigator.pop(context)),
            _navItem(colors, Icons.calendar_today_outlined, 'RESERVAS', false, () => Navigator.pushNamedAndRemoveUntil(context, '/reservas', (r) => false)),
            _navItem(colors, Icons.person_outline, 'PERFIL', false, () => Navigator.pushNamed(context, '/perfil')),
          ],
        ),
      ),
    );
  }

  Widget _navItem(AppColors colors, IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? colors.accentText : colors.textMuted;
    return TapScale(
      scale: 0.82,
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

  Widget _tagChip(AppColors colors, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
    );
  }
}
