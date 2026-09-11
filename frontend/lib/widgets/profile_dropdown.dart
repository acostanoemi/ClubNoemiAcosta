import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../session.dart';

class ProfileDropdown extends StatelessWidget {
  final VoidCallback onClose;

  const ProfileDropdown({super.key, required this.onClose});

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
            // DNI y fecha de nacimiento: mock, el login no los devuelve.
            _fila(colors, 'Email', email),
            _fila(colors, 'DNI', '31.234.567'),
            _fila(colors, 'Nac.', '1990-05-15'),
            const SizedBox(height: 8),
            Divider(color: colors.surfaceBorder),
            const SizedBox(height: 4),
            _accion(context, colors, Icons.person_outline, 'Perfil completo', () {
              onClose();
              Navigator.pushNamed(context, '/perfil');
            }),
            _accion(context, colors, Icons.calendar_today_outlined, 'Mis reservas', () {
              onClose();
              Navigator.pushNamed(context, '/reservas');
            }),
            _accion(context, colors, Icons.logout, 'Cerrar sesión', () {
              onClose();
              Session.clear();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
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
