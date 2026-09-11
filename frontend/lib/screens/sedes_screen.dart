import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../session.dart';
import 'sede_detalle_screen.dart';

const String _apiBaseUrl = "http://localhost:8000";

String _hhmm(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;

const _gradientesSede = [
  [Color(0xFF0D1B2A), Color(0xFF050508)],
  [Color(0xFF141C0A), Color(0xFF050508)],
  [Color(0xFF1A1030), Color(0xFF050508)],
  [Color(0xFF0A1F1C), Color(0xFF050508)],
];

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
          _sedes = sedesJson.map((s) => Sede.fromJson(s)).where((s) => s.activa).toList();
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
    if (!Session.estaLogueado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const Scaffold(backgroundColor: Color(0xFF050508));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CLUB NOEMI ACOSTA', style: TextStyle(color: kAccentColor, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 3)),
                      const SizedBox(height: 4),
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'TODAS LAS ', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'SEDES', style: TextStyle(color: kAccentColor)),
                          ],
                        ),
                        style: const TextStyle(fontSize: 32, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      if (!_loading)
                        Text('${_sedes.length} sedes · ${_espacios.length} canchas disponibles', style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 13, fontFamily: 'Inter')),
                    ],
                  ),
                ),
                if (_loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: kAccentColor)))
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        Text(_error!, style: TextStyle(color: Colors.red[300], fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _cargarDatos, child: const Text('Reintentar', style: TextStyle(color: kAccentColor))),
                      ],
                    ),
                  )
                else
                  ...List.generate(_sedes.length, (i) {
                    final s = _sedes[i];
                    final cantCanchas = _espaciosDeSede(s.id).length;
                    final deportes = _deportesDeSede(s.id);
                    final gradiente = _gradientesSede[i % _gradientesSede.length];

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradiente),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(10)),
                                      child: Column(
                                        children: [
                                          Text('$cantCanchas', style: const TextStyle(color: kAccentColor, fontSize: 16, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                                          Text('canchas', style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 9, fontFamily: 'Inter')),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('SEDE ${s.nombre.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 13, color: Colors.white.withValues(alpha: 0.55)),
                                            const SizedBox(width: 4),
                                            Text(s.direccion, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontFamily: 'Inter')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              color: Colors.white.withValues(alpha: 0.05),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: deportes.map((d) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: kAccentColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                                          child: Text(d, style: const TextStyle(color: kAccentColor, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
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
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Ver canchas', style: TextStyle(color: kAccentColor, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward, color: kAccentColor, size: 14),
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
          color: const Color(0xFF0A0A0E),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, Icons.home_outlined, 'INICIO', false, () => Navigator.pushReplacementNamed(context, '/home')),
            _navItem(context, Icons.apartment, 'SEDES', true, () {}),
            _navItem(context, Icons.calendar_today_outlined, 'RESERVAS', false, () => Navigator.pushNamed(context, '/reservas')),
            _navItem(context, Icons.person_outline, 'PERFIL', false, () => Navigator.pushNamed(context, '/perfil')),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? kAccentColor : Colors.white38;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
