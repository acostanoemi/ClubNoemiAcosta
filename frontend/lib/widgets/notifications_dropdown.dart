import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../session.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class NotificationsDropdown extends StatefulWidget {
  final VoidCallback onClose;

  const NotificationsDropdown({super.key, required this.onClose});

  @override
  State<NotificationsDropdown> createState() => _NotificationsDropdownState();
}

class _NotificationsDropdownState extends State<NotificationsDropdown> {
  List<dynamic> _notificaciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    if (Session.id == null) {
      setState(() {
        _cargando = false;
        _error = 'No hay sesión activa';
      });
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$_apiBaseUrl/usuarios/${Session.id}/notificaciones'),
        headers: Session.authHeader,
      );
      if (res.statusCode == 200) {
        setState(() {
          _notificaciones = jsonDecode(res.body);
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'No se pudieron cargar las notificaciones';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión';
        _cargando = false;
      });
    }
  }

  Future<void> _marcarLeida(String id, int index) async {
    // Actualiza en pantalla al instante; si el PATCH falla, no rompe la UI,
    // solo queda desincronizado hasta la próxima apertura del dropdown.
    setState(() => _notificaciones[index]['leida'] = true);
    try {
      await http.patch(Uri.parse('$_apiBaseUrl/notificaciones/$id'), headers: Session.authHeader);
    } catch (_) {}
  }

  String _formatearFecha(String isoString) {
    final fecha = DateTime.tryParse(isoString);
    if (fecha == null) return '';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bottomSheetBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notificaciones', style: TextStyle(color: colors.textPrimary, fontSize: 17, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800)),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(Icons.close, color: colors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_cargando)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: colors.accentText)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: TextStyle(color: colors.textMuted, fontSize: 13, fontFamily: 'Inter')),
              )
            else if (_notificaciones.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No tenés notificaciones todavía.', style: TextStyle(color: colors.textMuted, fontSize: 13, fontFamily: 'Inter')),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_notificaciones.length, (i) {
                      final n = _notificaciones[i];
                      final leida = n['leida'] == true;
                      return GestureDetector(
                        onTap: leida ? null : () => _marcarLeida(n['id'], i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: leida ? colors.textMuted : colors.accentText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['titulo'] ?? '',
                                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['cuerpo'] ?? '',
                                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Inter'),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatearFecha(n['creada_en'] ?? ''),
                                      style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
