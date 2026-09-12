import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../session.dart';
import '../theme/app_theme.dart';
import '../theme/theme_scope.dart';
import 'cambiar_contrasena_screen.dart';

// TODO: reemplazar por datos reales del usuario logueado una vez que
// el login guarde el token/id de sesión (por ahora no persiste nada).
class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
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

  Future<void> _confirmarEliminarCuenta() async {
    final colors = context.colors;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: colors.bottomSheetBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ZONA DE PELIGRO', style: TextStyle(color: Colors.red[400], fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '¿Estás seguro? Esta acción elimina todos tus datos permanentemente.',
                style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // TODO: llamar al endpoint de eliminación de cuenta cuando exista en el
    // backend. Por ahora solo se muestra la confirmación, sin efecto real.
    if (confirmado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta conectar esto al backend — todavía no hay endpoint de eliminación de cuenta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeController = ThemeScope.of(context);
    final iniciales = '${_nombre[0]}${_apellido[0]}';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'MI ', style: TextStyle(color: colors.textPrimary)),
                    TextSpan(text: 'PERFIL', style: TextStyle(color: colors.accentText)),
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
                      color: colors.accent,
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
                          style: TextStyle(color: colors.textPrimary, fontSize: 19, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _email,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MIEMBRO ACTIVO',
                          style: TextStyle(color: colors.accentText, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1.2),
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
                    color: colors.accent,
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.accent,
                  title: Text('Modo oscuro', style: TextStyle(color: colors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                  secondary: Icon(Icons.dark_mode_outlined, color: colors.textSecondary),
                  value: themeController.isDark,
                  onChanged: (v) => themeController.setDark(v),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DATOS PERSONALES', style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: habilitar edición cuando exista el endpoint de update de perfil.
                          },
                          icon: Icon(Icons.edit_outlined, size: 16, color: colors.accentText),
                          label: Text('Editar', style: TextStyle(color: colors.accentText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _campoSoloLectura(colors, 'NOMBRE', _nombre)),
                        const SizedBox(width: 12),
                        Expanded(child: _campoSoloLectura(colors, 'APELLIDO', _apellido)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _campoSoloLectura(colors, 'DNI', _dni),
                    const SizedBox(height: 12),
                    _campoSoloLectura(colors, 'FECHA DE NACIMIENTO', _fechaNacimiento),
                    const SizedBox(height: 12),
                    _campoSoloLectura(colors, 'EMAIL (solo lectura)', _email, candado: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Seguridad', style: TextStyle(color: colors.textMuted, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: _irACambiarContrasena,
                        title: Text('Cambiar contraseña', style: TextStyle(color: colors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: limpiar sesión real (token) cuando exista.
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  icon: Icon(Icons.logout, color: colors.textSecondary, size: 18),
                  label: Text('Cerrar sesión', style: TextStyle(color: colors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
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
                        onPressed: _confirmarEliminarCuenta,
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
            _navItem(colors, Icons.apartment_outlined, 'SEDES', false, () => Navigator.pushNamedAndRemoveUntil(context, '/sedes', (r) => false)),
            _navItem(colors, Icons.calendar_today_outlined, 'RESERVAS', false, () => Navigator.pushNamedAndRemoveUntil(context, '/reservas', (r) => false)),
            _navItem(colors, Icons.person, 'PERFIL', true, () {}),
          ],
        ),
      ),
    );
  }

  Widget _campoSoloLectura(AppColors colors, String label, String value, {bool candado = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.surfaceBorder),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter'))),
              if (candado) Icon(Icons.lock_outline, size: 14, color: colors.textMuted),
            ],
          ),
        ),
      ],
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
        ],
      ),
    );
  }
}
