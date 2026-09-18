import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../session.dart';
import '../theme/app_theme.dart';
import '../theme/theme_scope.dart';
import 'cambiar_contrasena_screen.dart';

const String _apiBaseUrl = "http://localhost:8000";

class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  bool _mostrarBannerActualizada = false;

  void _autoOcultarBanner() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _mostrarBannerActualizada = false);
    });
  }
  bool _editando = false;
  bool _guardando = false;
  bool _cargandoDatos = true;

  // Nombre/apellido/email ya llegan del login vía Session. DNI y fecha de
  // nacimiento no, así que se piden con GET /usuarios/{id} al entrar.
  String _nombre = Session.nombre ?? '';
  String _apellido = Session.apellido ?? '';
  final _email = Session.email ?? '';
  String? _dni;
  DateTime? _fechaNacimiento;
  DateTime? _fechaEditando; // borrador de fecha mientras se edita -- solo se
  // aplica a _fechaNacimiento si se toca "Guardar", nunca con "Cancelar".

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuario() async {
    if (Session.id == null) return;
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/usuarios/${Session.id}'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nombre = data['nombre'] ?? _nombre;
          _apellido = data['apellido'] ?? _apellido;
          _dni = data['dni']?.toString();
          if (data['fecha_nacimiento'] != null) {
            _fechaNacimiento = DateTime.tryParse(data['fecha_nacimiento']);
          }
        });
      }
    } catch (e) {
      // Si falla, los campos de solo lectura muestran "—" y se puede
      // reintentar entrando de nuevo a la pantalla; no es crítico para
      // el resto de Mi Perfil (nombre/apellido/email ya vienen del login).
    } finally {
      if (mounted) setState(() => _cargandoDatos = false);
    }
  }

  String get _fechaFormateada {
    if (_fechaNacimiento == null) return '—';
    final f = _fechaNacimiento!;
    return '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
  }

  void _iniciarEdicion() {
    _nombreController.text = _nombre;
    _apellidoController.text = _apellido;
    _dniController.text = _dni ?? '';
    _fechaEditando = _fechaNacimiento;
    _fechaController.text = _fechaNacimiento != null ? _fechaFormateada : '';
    setState(() => _editando = true);
  }

  void _cancelarEdicion() {
    setState(() => _editando = false);
  }

  Future<void> _elegirFechaNacimiento() async {
    final elegida = await mostrarSelectorFecha(
      context,
      initialDate: _fechaEditando ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (elegida != null) {
      setState(() {
        _fechaEditando = elegida;
        _fechaController.text = '${elegida.year}-${elegida.month.toString().padLeft(2, '0')}-${elegida.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _guardarPerfil() async {
    if (Session.id == null) return;

    setState(() => _guardando = true);

    final nuevoNombre = _nombreController.text.trim();
    final nuevoApellido = _apellidoController.text.trim();
    final nuevoDni = _dniController.text.trim();

    try {
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/usuarios/${Session.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nuevoNombre,
          'apellido': nuevoApellido,
          'dni': nuevoDni,
          if (_fechaEditando != null) 'fecha_nacimiento': _fechaEditando!.toIso8601String().split('T').first,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _nombre = nuevoNombre;
          _apellido = nuevoApellido;
          _dni = nuevoDni;
          _fechaNacimiento = _fechaEditando;
          _editando = false;
          _mostrarBannerActualizada = true;
          _autoOcultarBanner();
        });
        // Para que el saludo de Home y el avatar reflejen el cambio sin
        // tener que volver a loguearse.
        Session.set(id: Session.id!, email: Session.email!, nombre: nuevoNombre, apellido: nuevoApellido);
      } else {
        String detail = 'No pudimos actualizar el perfil';
        try {
          final data = jsonDecode(response.body);
          detail = data['detail'] ?? detail;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(detail), backgroundColor: Colors.red[900]));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin conexión con el servidor')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _irACambiarContrasena() async {
    final huboCambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen()),
    );
    if (huboCambio == true && mounted) {
      setState(() => _mostrarBannerActualizada = true);
      _autoOcultarBanner();
    }
  }

  Future<void> _confirmarEliminarCuenta() async {
    final confirmado = await showConfirmDialog(
      context,
      title: 'ZONA DE PELIGRO',
      message: '¿Estás seguro? Esta acción elimina todos tus datos permanentemente.',
      confirmLabel: 'Eliminar',
      titleColor: Colors.red[400],
      confirmColor: Colors.red[600]!,
      icon: Icons.warning_amber_rounded,
    );

    // Llama al endpoint real de baja lógica (marca activo=False en el
    // backend, no borra la fila). Si sale bien, la sesión ya no sirve --
    // se limpia y se vuelve al login.
    if (confirmado == true && mounted) {
      setState(() => _guardando = true);
      try {
        final response = await http.delete(Uri.parse('$_apiBaseUrl/usuarios/${Session.id}'));
        if (!mounted) return;

        if (response.statusCode == 200) {
          Session.clear();
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pudimos eliminar la cuenta. Intentá de nuevo.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sin conexión con el servidor')),
          );
        }
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmado = await showConfirmDialog(
      context,
      title: '¿Estás seguro de cerrar sesión?',
      message: 'Vas a tener que volver a iniciar sesión para acceder a tu cuenta.',
      confirmLabel: 'Cerrar sesión',
      confirmColor: Colors.red[600]!,
    );

    if (confirmado == true && mounted) {
      Session.clear();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeController = ThemeScope.of(context);
    final iniciales = (_nombre.isNotEmpty && _apellido.isNotEmpty) ? '${_nombre[0]}${_apellido[0]}' : '?';

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
                      Text('Datos actualizados', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
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
                child: Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: colors.accent,
                    title: Text('Modo oscuro', style: TextStyle(color: colors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                    secondary: Icon(Icons.dark_mode_outlined, color: colors.textSecondary),
                    value: themeController.isDark,
                    onChanged: (v) => themeController.setDark(v),
                  ),
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
                        if (_editando)
                          TextButton.icon(
                            onPressed: _guardando ? null : _guardarPerfil,
                            icon: _guardando
                                ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentText))
                                : Icon(Icons.check, size: 16, color: colors.accentText),
                            label: Text('Guardar', style: TextStyle(color: colors.accentText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          )
                        else
                          TextButton.icon(
                            onPressed: _iniciarEdicion,
                            icon: Icon(Icons.edit_outlined, size: 16, color: colors.accentText),
                            label: Text('Editar', style: TextStyle(color: colors.accentText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_editando) ...[
                      Row(
                        children: [
                          Expanded(child: _campoEditable(colors, 'NOMBRE', _nombreController)),
                          const SizedBox(width: 12),
                          Expanded(child: _campoEditable(colors, 'APELLIDO', _apellidoController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _campoEditable(colors, 'DNI', _dniController, formatters: [DniInputFormatter()], tipoNumerico: true),
                      const SizedBox(height: 12),
                      _campoLabel(colors, 'FECHA DE NACIMIENTO'),
                      GestureDetector(
                        onTap: _elegirFechaNacimiento,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: colors.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                _fechaController.text.isEmpty ? 'Elegí una fecha' : _fechaController.text,
                                style: TextStyle(color: _fechaController.text.isEmpty ? colors.textMuted : colors.textPrimary, fontSize: 14, fontFamily: 'Inter'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _campoSoloLectura(colors, 'EMAIL (solo lectura)', _email, candado: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _guardando ? null : _cancelarEdicion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            side: BorderSide(color: colors.surfaceBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: _campoSoloLectura(colors, 'NOMBRE', _nombre)),
                          const SizedBox(width: 12),
                          Expanded(child: _campoSoloLectura(colors, 'APELLIDO', _apellido)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _campoSoloLectura(colors, 'DNI', _cargandoDatos ? '—' : (_dni ?? '—')),
                      const SizedBox(height: 12),
                      _campoSoloLectura(colors, 'FECHA DE NACIMIENTO', _cargandoDatos ? '—' : _fechaFormateada),
                      const SizedBox(height: 12),
                      _campoSoloLectura(colors, 'EMAIL (solo lectura)', _email, candado: true),
                    ],
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
                  onPressed: _confirmarCerrarSesion,
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
            _navItem(colors, Icons.home_outlined, 'INICIO', false, () => irATab(context, actual: '/perfil', destino: '/home')),
            _navItem(colors, Icons.apartment_outlined, 'SEDES', false, () => irATab(context, actual: '/perfil', destino: '/sedes')),
            _navItem(colors, Icons.calendar_today_outlined, 'RESERVAS', false, () => irATab(context, actual: '/perfil', destino: '/reservas')),
            _navItem(colors, Icons.person, 'PERFIL', true, () {}),
          ],
        ),
      ),
    );
  }

  Widget _campoLabel(AppColors colors, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }

  Widget _campoSoloLectura(AppColors colors, String label, String value, {bool candado = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _campoLabel(colors, label),
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

  Widget _campoEditable(AppColors colors, String label, TextEditingController controller, {List<TextInputFormatter>? formatters, bool tipoNumerico = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _campoLabel(colors, label),
        TextField(
          controller: controller,
          keyboardType: tipoNumerico ? TextInputType.number : TextInputType.text,
          inputFormatters: formatters,
          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontFamily: 'Inter'),
          decoration: buildInputDecoration(context, ''),
        ),
      ],
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
