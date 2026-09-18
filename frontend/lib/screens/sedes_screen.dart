import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../session.dart';
import 'sede_detalle_screen.dart';

const String _apiBaseUrl = "http://localhost:8000";

const List<String> _ordenSedes = ['Morón', 'Ramos Mejía', 'San Justo', 'Castelar'];

int _indiceOrdenSede(String nombre) {
  final i = _ordenSedes.indexOf(nombre);
  return i == -1 ? _ordenSedes.length : i;
}


String _hhmm(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;

class SedesScreen extends StatefulWidget {
  const SedesScreen({super.key});

  @override
  State<SedesScreen> createState() => _SedesScreenState();
}

class _SedesScreenState extends State<SedesScreen> {
  List<Sede> _sedes = [];
  List<Espacio> _espacios = [];
  bool _loading = true;
  String? _error;

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
      if (resSedes.statusCode == 200 && resEspacios.statusCode == 200) {
        final List sedesJson = jsonDecode(resSedes.body);
        final List espaciosJson = jsonDecode(resEspacios.body);
        setState(() {
          _sedes = sedesJson.map((s) => Sede.fromJson(s)).where((s) => s.activa).toList()
            ..sort((a, b) => _indiceOrdenSede(a.nombre).compareTo(_indiceOrdenSede(b.nombre)));
          _espacios = espaciosJson.map((e) => Espacio.fromJson(e)).where((e) => e.activo).toList();
        });
      } else {
        setState(() => _error = 'No pudimos cargar las sedes');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Espacio> _espaciosDeSede(String sedeId) => _espacios.where((e) => e.sedeId == sedeId).toList();

  List<String> _deportesDeSede(String sedeId) {
    return _espaciosDeSede(sedeId).map((e) => e.deporte).toSet().toList();
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
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Misma foto que el hero de Home, en modo claro y oscuro
                      // por igual (es una foto, no un color de tema).
                      Image.asset('assets/images/cancha_hero.png', fit: BoxFit.cover),
                      // Mismo degradado que Home: negro fuerte arriba, se
                      // aclara hacia el centro, funde al fondo del tema abajo.
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('CLUB NOEMI ACOSTA', style: TextStyle(color: Color(0xFFD4FF00), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 3)),
                            const SizedBox(height: 4),
                            Text.rich(
                              const TextSpan(
                                children: [
                                  TextSpan(text: 'TODAS LAS ', style: TextStyle(color: Colors.white)),
                                  TextSpan(text: 'SEDES', style: TextStyle(color: Color(0xFFD4FF00))),
                                ],
                              ),
                              style: const TextStyle(fontSize: 32, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            if (!_loading)
                              Text('${_sedes.length} sedes · ${_espacios.length} canchas disponibles', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, fontFamily: 'Inter')),
                          ],
                        ),
                      ),
                    ],
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
                else
                  ...List.generate(_sedes.length, (i) {
                    final s = _sedes[i];
                    final cantCanchas = _espaciosDeSede(s.id).length;
                    final deportes = _deportesDeSede(s.id);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Image.asset(fotoParaSede(s.id), fit: BoxFit.cover, width: double.infinity, height: 150),
                                  Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.50))),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('SEDE ${s.nombre.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on_outlined, size: 13, color: Colors.white.withValues(alpha: 0.55)),
                                                    const SizedBox(width: 4),
                                                    Expanded(child: Text(s.direccion, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(10)),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('$cantCanchas', style: TextStyle(color: colors.accentText, fontSize: 18, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, height: 1)),
                                                Text('canchas', style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 9, fontFamily: 'Inter')),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              color: colors.surface,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: deportes.map((d) {
                                        final colorD = colorDeporte(d);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: colorD.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                                          child: Text(d, style: TextStyle(color: colorD, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => SedeDetalleScreen(sede: s),
                                      ));
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Ver canchas', style: TextStyle(color: colors.accentText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 2),
                                        Icon(Icons.arrow_forward, color: colors.accentText, size: 14),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
            _navItem(colors, Icons.home_outlined, 'INICIO', false, () => irATab(context, actual: '/sedes', destino: '/home')),
            _navItem(colors, Icons.apartment, 'SEDES', true, () {}),
            _navItem(colors, Icons.calendar_today_outlined, 'RESERVAS', false, () => irATab(context, actual: '/sedes', destino: '/reservas')),
            _navItem(colors, Icons.person_outline, 'PERFIL', false, () => irATab(context, actual: '/sedes', destino: '/perfil')),
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
}
