import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../session.dart';

class ProfileDropdown extends StatelessWidget {
  final VoidCallback onClose;

  const ProfileDropdown({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
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
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  decoration: BoxDecoration(color: kAccentColor, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(iniciales, style: const TextStyle(color: Colors.black, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$nombre $apellido', style: const TextStyle(color: Colors.white, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('MIEMBRO ACTIVO', style: TextStyle(color: kAccentColor, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            // DNI y fecha de nacimiento: mock, el login no los devuelve.
            _fila('Email', email),
            _fila('DNI', '31.234.567'),
            _fila('Nac.', '1990-05-15'),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 4),
            _accion(context, Icons.person_outline, 'Perfil completo', () {
              onClose();
              Navigator.pushNamed(context, '/perfil');
            }),
            _accion(context, Icons.calendar_today_outlined, 'Mis reservas', () {
              onClose();
              // TODO: navegar cuando exista la pantalla de Mis Reservas.
            }),
            _accion(context, Icons.logout, 'Cerrar sesión', () {
              onClose();
              Session.clear();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 13, fontFamily: 'Inter')),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _accion(BuildContext context, IconData icon, String texto, VoidCallback onTap, {Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(texto, style: TextStyle(color: color, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}