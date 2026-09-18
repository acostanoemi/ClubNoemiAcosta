import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../models/reserva.dart';
import '../session.dart';
import 'mis_reservas_screen.dart';
import 'detalle_reserva_screen.dart';
import '../widgets/profile_dropdown.dart';
import '../widgets/notifications_dropdown.dart';
import 'consultar_canchas_screen.dart';
import '../theme/app_theme.dart';

const String _apiBaseUrl = "http://localhost:8000";

const List<String> _ordenSedes = ['Morón', 'Ramos Mejía', 'San Justo', 'Castelar'];

int _indiceOrdenSede(String nombre) {
  final i = _ordenSedes.indexOf(nombre);
  return i == -1 ? _ordenSedes.length : i;
}


// El backend devuelve "08:00:00" -- para mostrar solo recortamos a "08:00".
String _hhmm(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;

const _diasSemana = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _formatearFecha(DateTime f) {
  final dia = _diasSemana[f.weekday - 1];
  final mes = _meses[f.month - 1];
  return '$dia, ${f.day} $mes';
}

String _normalizar(String s) {
  return s
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}

String _saludoSegunHora() {
  final hora = DateTime.now().hour;
  if (hora < 12) return 'BUENOS DÍAS,';
  if (hora < 20) return 'BUENAS TARDES,';
  return 'BUENAS NOCHES,';
}
String _formatearMonto(double monto) {
  final entero = monto.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
    buffer.write(entero[i]);
  }
  return '\$ $buffer';
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Sede> _sedes = [];
  List<Espacio> _espacios = [];
  List<Reserva> _reservas = [];
  bool _loading = true;
  String? _error;
  String _deporteSeleccionado = 'Todos';

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
      final resSedes = await http.get(Uri.parse('$_apiBaseUrl/sedes'));
      final resEspacios = await http.get(Uri.parse('$_apiBaseUrl/espacios'));
      final resReservas = Session.id == null
          ? null
          : await http.get(Uri.parse('$_apiBaseUrl/reservas?usuario_id=${Session.id}'));

      if (resSedes.statusCode == 200 && resEspacios.statusCode == 200) {
        final List sedesJson = jsonDecode(resSedes.body);
        final List espaciosJson = jsonDecode(resEspacios.body);
        setState(() {
          _sedes = sedesJson.map((s) => Sede.fromJson(s)).where((s) => s.activa).toList()
            ..sort((a, b) => _indiceOrdenSede(a.nombre).compareTo(_indiceOrdenSede(b.nombre)));
          _espacios = espaciosJson.map((e) => Espacio.fromJson(e)).where((e) => e.activo).toList();
          if (resReservas != null && resReservas.statusCode == 200) {
            final List reservasJson = jsonDecode(resReservas.body);
            _reservas = reservasJson.map((r) => Reserva.fromJson(r)).toList();
          }
        });
      } else {
        setState(() => _error = 'No pudimos cargar los datos');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Reserva? get _proximaReserva {
    final hoy = DateTime.now();
    final futuras = _reservas.where((r) {
      final noCancelada = r.estado.toLowerCase() != 'cancelada';
      final esFutura = !r.fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
      return noCancelada && esFutura;
    }).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return futuras.isEmpty ? null : futuras.first;
  }

  Espacio? _espacioPorId(String id) {
    try {
      return _espacios.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Sede? _sedePorId(String id) {
    try {
      return _sedes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  final List<String> _deportesFijos = const ['Todos', 'Fútbol', 'Tenis', 'Hockey', 'Golf', 'Vóley'];

  List<String> _deportesDeSede(String sedeId) {
    return _espacios.where((e) => e.sedeId == sedeId).map((e) => e.deporte).toSet().toList();
  }

  List<Sede> get _sedesFiltradas {
    if (_deporteSeleccionado == 'Todos') return _sedes;
    final buscado = _normalizar(_deporteSeleccionado);
    final idsConDeporte = _espacios.where((e) => _normalizar(e.deporte).startsWith(buscado)).map((e) => e.sedeId).toSet();
    return _sedes.where((s) => idsConDeporte.contains(s.id)).toList();
  }

  bool _mostrarNotificaciones = false;
  bool _mostrarPerfilMenu = false;

  @override
  Widget build(BuildContext context) {
    if (!Session.estaLogueado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const Scaffold(backgroundColor: Color(0xFF050508));
    }

    final nombre = Session.nombre ?? '';
    final apellido = Session.apellido ?? '';
    final iniciales = (nombre.isNotEmpty && apellido.isNotEmpty) ? '${nombre[0]}${apellido[0]}' : '?';
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero -- cancha dibujada vectorialmente (sin asset de imagen) + glow inferior, como el Figma.
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Foto real de cancha -- misma imagen en modo claro y oscuro
                      // a propósito (es una foto, no un color de tema).
                      Image.asset(
                        'assets/images/cancha_hero.png',
                        fit: BoxFit.cover,
                      ),
                      // Degradado del hero: negro fuerte arriba (legibilidad del
                      // texto), se aclara hasta casi transparente a mitad de
                      // imagen, y funde al fondo del tema al final.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color.fromRGBO(0, 0, 0, 0.84),
                                const Color.fromRGBO(0, 0, 0, 0.52),
                                const Color.fromRGBO(0, 0, 0, 0.08),
                                colors.background,
                              ],
                              stops: const [0.0, 0.48, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Saludo + notificaciones + avatar, ancladas arriba del
                      // hero (antes estaban agrupadas con el título abajo del
                      // todo, quedaban apretadas).
                      Positioned(
                        top: 20,
                        left: 24,
                        right: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_saludoSegunHora(), style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 2)),
                                  const SizedBox(height: 2),
                                  Text(nombre.isEmpty ? '' : '$nombre $apellido', style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _mostrarNotificaciones = true),
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                                child: const Icon(Icons.notifications_none, color: Colors.white70, size: 20),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _mostrarPerfilMenu = true),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: kAccentColor, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(iniciales, style: const TextStyle(color: Colors.black, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Título, anclado abajo del hero -- mismo criterio que Sedes.
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CLUB NOEMI ACOSTA', style: TextStyle(color: kAccentColor, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 3)),
                            const SizedBox(height: 4),
                            const Text('ZONA DEPORTIVA', style: TextStyle(color: Colors.white, fontSize: 34, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Próxima reserva -- real, cruzando /reservas con /sedes y /espacios.
                      Builder(builder: (context) {
                        final reserva = _proximaReserva;
                        if (reserva == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.surfaceBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PRÓXIMA RESERVA', style: TextStyle(color: colors.accentText, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                const SizedBox(height: 10),
                                Text('Todavía no tenés reservas.', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
                              ],
                            ),
                          );
                        }
                        final espacio = _espacioPorId(reserva.espacioId);
                        final sede = espacio == null ? null : _sedePorId(espacio.sedeId);
                        final dias = reserva.fecha.difference(DateTime.now()).inDays;
                        final enCuantos = dias <= 0 ? 'hoy' : (dias == 1 ? 'mañana' : 'en $dias días');

                        return GestureDetector(
                          onTap: () async {
                            final cancelada = await Navigator.of(context).push<bool>(MaterialPageRoute(
                              builder: (_) => DetalleReservaScreen(
                                item: ReservaConDetalle(reserva: reserva, espacio: espacio, sede: sede),
                              ),
                            ));
                            if (cancelada == true) _cargarDatos();
                          },
                          child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('PRÓXIMA RESERVA', style: TextStyle(color: colors.accentText, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                  Text(enCuantos, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      espacio != null ? fotoParaCancha(espacio.id) : fotoGenerica,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sede?.nombre ?? 'Sede', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                        Text(espacio?.nombre ?? '', style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_hhmm(reserva.horaInicio), style: TextStyle(color: colors.accentText, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                      Text(_hhmm(reserva.horaFin), style: TextStyle(color: colors.textMuted, fontSize: 12, fontFamily: 'Inter')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(color: colors.surfaceBorder),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatearFecha(reserva.fecha), style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
                                  Text(_formatearMonto(reserva.montoTotal), style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Entrada a Consultar Canchas (CU13) -- buscador por filtros,
                      // complementa el flujo Home -> Sedes -> Cancha -> Horarios.
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConsultarCanchasScreen())),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: colors.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.search, color: colors.accentText, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Buscar disponibilidad', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                              ),
                              Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 36,
                        child: _loading
                            ? const SizedBox.shrink()
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _deportesFijos.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final d = _deportesFijos[i];
                                  final activo = d == _deporteSeleccionado;
                                  return GestureDetector(
                                    onTap: () => setState(() => _deporteSeleccionado = d),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: activo ? colors.accent : colors.surface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(d, style: TextStyle(color: activo ? Colors.black : colors.textSecondary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SEDES DISPONIBLES', style: TextStyle(color: colors.textPrimary, fontSize: 17, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/sedes'),
                            child: Row(
                              children: [
                                Text('Ver todas', style: TextStyle(color: colors.accentText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_forward, color: colors.accentText, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                if (_loading)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator(color: colors.accent)))
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
                else if (_sedesFiltradas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Text('No hay sedes para este filtro.', style: TextStyle(color: colors.textMuted, fontFamily: 'Inter')),
                  )
                else
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _sedesFiltradas.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final s = _sedesFiltradas[i];
                        final deportes = _deportesDeSede(s.id);
                        return Container(
                          width: 220,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                fotoParaSede(s.id),
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.nombre.toUpperCase(), style: TextStyle(color: colors.textPrimary, fontSize: 17, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 13, color: colors.textMuted),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(s.direccion, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: deportes.isEmpty
                                          ? [Text('Sin espacios cargados', style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter'))]
                                          : deportes.map((d) {
                                              final colorD = colorDeporte(d);
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: colorD.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                                                child: Text(d, style: TextStyle(color: colorD, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                              );
                                            }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: colors.textMuted),
                                        const SizedBox(width: 4),
                                        Text('${_hhmm(s.horaApertura)} - ${_hhmm(s.horaCierre)}', style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
          ),
          if (_mostrarNotificaciones)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _mostrarNotificaciones = false),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
                child: Align(
                  alignment: const Alignment(0.75, -0.72),
                  child: GestureDetector(
                    onTap: () {},
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1.0),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      builder: (context, value, child) => Opacity(
                        opacity: ((value - 0.92) / 0.08).clamp(0.0, 1.0),
                        child: Transform.scale(scale: value, alignment: Alignment.topRight, child: child),
                      ),
                      child: NotificationsDropdown(onClose: () => setState(() => _mostrarNotificaciones = false)),
                    ),
                  ),
                ),
              ),
            ),
          if (_mostrarPerfilMenu)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _mostrarPerfilMenu = false),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
                child: Align(
                  alignment: const Alignment(0.7, -0.72),
                  child: GestureDetector(
                    onTap: () {},
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1.0),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      builder: (context, value, child) => Opacity(
                        opacity: ((value - 0.92) / 0.08).clamp(0.0, 1.0),
                        child: Transform.scale(scale: value, alignment: Alignment.topRight, child: child),
                      ),
                      child: ProfileDropdown(onClose: () => setState(() => _mostrarPerfilMenu = false)),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
            _navItem(colors, Icons.home, 'INICIO', true, () {}),
            _navItem(colors, Icons.apartment_outlined, 'SEDES', false, () => Navigator.pushNamed(context, '/sedes')),
            _navItem(colors, Icons.calendar_today_outlined, 'RESERVAS', false, () => Navigator.pushNamed(context, '/reservas')),
            _navItem(colors, Icons.person_outline, 'PERFIL', false, () => Navigator.pushNamed(context, '/perfil')),
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
