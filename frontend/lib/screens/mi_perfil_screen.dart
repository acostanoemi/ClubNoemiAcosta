
import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../session.dart';
import 'cambiar_contrasena_screen.dart';

// TODO: reemplazar por datos reales del usuario logueado una vez que
// el login guarde el token/id de sesión (por ahora no persiste nada).
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  bool _modoOscuro = true;
  bool _mostrarBannerActualizada = false;

  // Mock — reemplazar por el usuario real.
  final _nombre = Session.nombre ?? '';
  final _apellido = Session.apellido ?? '';
  final _dni = '31.234.567';
  final _fechaNacimiento = '1990-05-15';
  final _email = Session.email ?? '';

  Future<void> _irACambiarContrasena() async {
    final huboCambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen()),
    );
    if (huboCambio == true && mounted) {
      setState(() => _mostrarBannerActualizada = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iniciales = '${_nombre[0]}${_apellido[0]}';

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'MI ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'PERFIL', style: TextStyle(color: kAccentColor)),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 34,
                  fontFamily: 'Barlow Condensed',
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: 'Barlow Condensed',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_nombre $_apellido',
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _email,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'MIEMBRO ACTIVO',
                          style: TextStyle(color: kAccentColor, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_mostrarBannerActualizada) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.black, size: 18),
                      SizedBox(width: 8),
                      Text('Contraseña actualizada', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: kAccentColor,
                  title: const Text('Modo oscuro', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                  secondary: const Icon(Icons.dark_mode_outlined, color: Colors.white70),
                  value: _modoOscuro,
                  onChanged: (v) => setState(() => _modoOscuro = v),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DATOS PERSONALES', style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: habilitar edición cuando exista el endpoint de update de perfil.
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16, color: kAccentColor),
                          label: const Text('Editar', style: TextStyle(color: kAccentColor, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _campoSoloLectura('NOMBRE', _nombre)),
                        const SizedBox(width: 12),
                        Expanded(child: _campoSoloLectura('APELLIDO', _apellido)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _campoSoloLectura('DNI', _dni),
                    const SizedBox(height: 12),
                    _campoSoloLectura('FECHA DE NACIMIENTO', _fechaNacimiento),
                    const SizedBox(height: 12),
                    _campoSoloLectura('EMAIL (solo lectura)', _email, candado: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Seguridad', style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ),
                    ),
                    ListTile(
                      onTap: _irACambiarContrasena,
                      title: const Text('Cambiar contraseña', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: limpiar sesión real (token) cuando exista.
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white70, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red[300], size: 16),
                        const SizedBox(width: 6),
                        Text('ZONA DE PELIGRO', style: TextStyle(color: Colors.red[300], fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: endpoint de eliminación de cuenta, cuando exista.
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Eliminar cuenta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Barra inferior solo visual por ahora — Inicio/Sedes/Reservas todavía no existen como pantallas.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0E),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.home_outlined, 'INICIO', false),
            _navItem(Icons.apartment_outlined, 'SEDES', false),
            _navItem(Icons.calendar_today_outlined, 'RESERVAS', false),
            _navItem(Icons.person, 'PERFIL', true),
          ],
        ),
      ),
    );
  }

  Widget _campoSoloLectura(String label, String value, {bool candado = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, fontFamily: 'Inter'))),
              if (candado) Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.30)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? kAccentColor : Colors.white38;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ],
    );
  }
}