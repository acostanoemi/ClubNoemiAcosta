import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';
import 'email_enviado_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _loading = false;
  String? _errorBanner;
  Set<String> _fieldErrors = {};

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    final missing = <String>{};
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      missing.add('email');
    } else if (!RegExp(r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      missing.add('email');
    }

    if (missing.isNotEmpty) {
      setState(() {
        _fieldErrors = missing;
        _errorBanner = 'Ingresá un email válido';
      });
      return false;
    }
    return true;
  }

  Future<void> _handleEnviar() async {
    setState(() {
      _errorBanner = null;
      _fieldErrors = {};
    });

    if (!_validateFields()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();

    try {
      // Firebase manda el mail con el enlace para elegir contraseña nueva.
      // Por seguridad no avisa si el email no existe: la respuesta es la
      // misma en los dos casos, asi nadie puede averiguar quien tiene cuenta.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EmailEnviadoScreen(email: email)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorBanner = e.code == 'invalid-email'
            ? 'Ingresá un email válido'
            : 'No pudimos enviar el enlace. Probá de nuevo';
        _fieldErrors = e.code == 'invalid-email' ? {'email'} : {};
      });
    } catch (e) {
      setState(() => _errorBanner = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.60), size: 22),
                      Text(
                        'Volver',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 14, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'RECUPERACIÓN',
                  style: TextStyle(
                    color: kAccentColor,
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: 'OLVIDÉ MI ', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'CONTRASEÑA', style: TextStyle(color: kAccentColor)),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 34,
                    fontFamily: 'Barlow Condensed',
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresá tu email y te enviamos un enlace para restablecerla.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                if (_errorBanner != null) ...[
                  const SizedBox(height: 16),
                  ErrorBanner(message: _errorBanner!),
                ],
                const SizedBox(height: 24),
                FieldLabel('EMAIL *', hasError: _fieldErrors.contains('email'), colorsOverride: AppColors.dark),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: buildInputDecoration(context, 'juan@email.com', hasError: _fieldErrors.contains('email'), colorsOverride: AppColors.dark),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleEnviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            'ENVIAR ENLACE',
                            style: TextStyle(fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
