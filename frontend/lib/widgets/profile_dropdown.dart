import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../session.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class ProfileDropdown extends StatefulWidget {
  final VoidCallback onClose;

  const ProfileDropdown({super.key, required this.onClose});

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  String? _dni;
  String? _fechaNacimiento;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (Session.id == null) {
      setState(() => _cargando = false);
      return;
    }
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/usuarios/${Session.id}'), headers: Session.authHeader);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _dni = data['dni']?.toString();
          _fechaNacimiento = data['fecha_nacimiento']?.toString();
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final colors = context.colors;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.bottomSheetBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.surfaceBorder),
          ),
          title: Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: colors.textPrimary, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800, fontSize: 20),
          ),
          content: Text(
            'Vas a tener que volver a iniciar sesión para acceder a tu cuenta.',
            style: TextStyle(color: colors.textSecondary, fontFamily: 'Inter', fontSize: 13),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Volver', style: TextStyle(color: colors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Cerrar sesión', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      widget.onClose();
      Session.clear();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nombre = Session.nombre ?? '';
    final apellido = Session.apellido ?? '';
    final email = Session.email ?? '';
    final iniciales = (nombre.isNotEmpty && apellido.isNotEmpty) ? '${nombre[0]}${apellido[0]}' : '?';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
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
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(iniciales, style: const TextStyle(color: Colors.black, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$nombre $apellido', style: TextStyle(color: colors.textPrimary, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('MIEMBRO ACTIVO', style: TextStyle(color: colors.accentText, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.surfaceBorder),
            const SizedBox(height: 8),
            _fila(colors, 'Email', email),
            _fila(colors, 'DNI', _cargando ? '—' : (_dni ?? '—')),
            _fila(colors, 'Nac.', _cargando ? '—' : (_fechaNacimiento ?? '—')),
            const SizedBox(height: 8),
            Divider(color: colors.surfaceBorder),
            const SizedBox(height: 4),
            _accion(context, colors, Icons.person_outline, 'Perfil completo', () {
              widget.onClose();
              Navigator.pushNamed(context, '/perfil');
            }),
            _accion(context, colors, Icons.calendar_today_outlined, 'Mis reservas', () {
              widget.onClose();
              Navigator.pushNamed(context, '/reservas');
            }),
            _accion(context, colors, Icons.logout, 'Cerrar sesión', () {
              _confirmarCerrarSesion(context);
            }, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _fila(AppColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 13, fontFamily: 'Inter')),
          const SizedBox(width: 12),
          // Flexible + ellipsis: un email largo se corta con "..." en vez
          // de desbordar la fila (la franja amarilla y negra).
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accion(BuildContext context, AppColors colors, IconData icon, String texto, VoidCallback onTap, {Color? color}) {
    final c = color ?? colors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 10),
            Text(texto, style: TextStyle(color: c, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
