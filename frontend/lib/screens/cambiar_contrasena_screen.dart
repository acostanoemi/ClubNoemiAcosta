import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _repetirController = TextEditingController();

  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureRepetir = true;
  bool _loading = false;
  String? _errorActual;

  @override
  void initState() {
    super.initState();
    _nuevaController.addListener(() => setState(() {}));
    _repetirController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _repetirController.dispose();
    super.dispose();
  }

  bool get _tiene8 => _nuevaController.text.length >= 8;
  bool get _tieneMayuscula => RegExp(r'[A-Z]').hasMatch(_nuevaController.text);
  bool get _tieneNumero => RegExp(r'[0-9]').hasMatch(_nuevaController.text);
  bool get _coinciden => _nuevaController.text.isNotEmpty && _nuevaController.text == _repetirController.text;

  int get _fuerza => [_tiene8, _tieneMayuscula, _tieneNumero].where((c) => c).length;

  bool get _formularioValido =>
      _actualController.text.isNotEmpty && _tiene8 && _tieneMayuscula && _tieneNumero && _coinciden;

  Future<void> _guardarCambios() async {
    if (!_formularioValido) return;

    setState(() {
      _loading = true;
      _errorActual = null;
    });

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null || usuario.email == null) {
      // Sesion iniciada con el login viejo (antes de Firebase).
      setState(() {
        _loading = false;
        _errorActual = 'Cerrá sesión y volvé a entrar para cambiar la contraseña.';
      });
      return;
    }

    try {
      // Firebase pide volver a validar la contraseña actual antes de
      // cambiarla (reautenticacion). Si es incorrecta, tira excepcion.
      final credencial = EmailAuthProvider.credential(
        email: usuario.email!,
        password: _actualController.text,
      );
      await usuario.reauthenticateWithCredential(credencial);
      await usuario.updatePassword(_nuevaController.text);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final String mensaje;
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          mensaje = 'La contraseña actual no es correcta.';
          break;
        case 'too-many-requests':
          mensaje = 'Demasiados intentos. Probá de nuevo en unos minutos.';
          break;
        case 'weak-password':
          mensaje = 'La contraseña nueva es muy débil.';
          break;
        case 'network-request-failed':
          mensaje = 'Sin conexión';
          break;
        default:
          mensaje = 'No pudimos actualizar la contraseña. Intentá de nuevo.';
      }
      setState(() => _errorActual = mensaje);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorActual = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, color: colors.textSecondary, size: 22),
                    Text('Volver', style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SEGURIDAD',
                style: TextStyle(color: colors.accentText, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'CAMBIAR ', style: TextStyle(color: colors.textPrimary)),
                    TextSpan(text: 'CONTRASEÑA', style: TextStyle(color: colors.accentText)),
                  ],
                ),
                style: const TextStyle(fontSize: 32, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresá tu contraseña actual y elegí una nueva.',
                style: TextStyle(color: colors.textMuted, fontSize: 13, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 24),

              FieldLabel('CONTRASEÑA ACTUAL', hasError: _errorActual != null),
              TextField(
                controller: _actualController,
                obscureText: _obscureActual,
                style: TextStyle(color: colors.textPrimary),
                decoration: buildInputDecoration(context, '', hasError: _errorActual != null).copyWith(
                  suffixIcon: IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(_obscureActual ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscureActual = !_obscureActual),
                  ),
                ),
                onChanged: (_) {
                  if (_errorActual != null) setState(() => _errorActual = null);
                },
              ),
              if (_errorActual != null) ...[
                const SizedBox(height: 6),
                Text(_errorActual!, style: TextStyle(color: Colors.red[300], fontSize: 12, fontFamily: 'Inter')),
              ],

              const SizedBox(height: 16),
              const FieldLabel('NUEVA CONTRASEÑA'),
              TextField(
                controller: _nuevaController,
                obscureText: _obscureNueva,
                style: TextStyle(color: colors.textPrimary),
                decoration: buildInputDecoration(context, '').copyWith(
                  suffixIcon: IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(_obscureNueva ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(3, (i) {
                  final activo = i < _fuerza;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: activo ? colors.accent : colors.surfaceBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              if (_nuevaController.text.isNotEmpty)
                Text(
                  _fuerza == 3 ? 'CONTRASEÑA FUERTE' : (_fuerza >= 1 ? 'CONTRASEÑA MEDIA' : 'CONTRASEÑA DÉBIL'),
                  style: TextStyle(color: colors.accentText, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              const SizedBox(height: 10),
              _requisito(colors, 'Al menos 8 caracteres', _tiene8),
              _requisito(colors, 'Una letra mayúscula', _tieneMayuscula),
              _requisito(colors, 'Un número', _tieneNumero),

              const SizedBox(height: 16),
              const FieldLabel('REPETIR NUEVA CONTRASEÑA'),
              TextField(
                controller: _repetirController,
                obscureText: _obscureRepetir,
                style: TextStyle(color: colors.textPrimary),
                decoration: buildInputDecoration(context, '', hasError: _repetirController.text.isNotEmpty && !_coinciden).copyWith(
                  suffixIcon: IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(_obscureRepetir ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscureRepetir = !_obscureRepetir),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_formularioValido && !_loading) ? _guardarCambios : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: colors.surface,
                    disabledForegroundColor: colors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('GUARDAR CAMBIOS', style: TextStyle(fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requisito(AppColors colors, String texto, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: cumplido ? colors.accentText : colors.textMuted),
          const SizedBox(width: 8),
          Text(texto, style: TextStyle(color: cumplido ? colors.accentText : colors.textMuted, fontSize: 12, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}
