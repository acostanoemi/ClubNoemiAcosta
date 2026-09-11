import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import 'email_enviado_screen.dart';

// Mismo host que main.dart usa para /auth/login y register_screen.dart para /auth/register.
const String _apiBaseUrl = "http://localhost:8000";

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
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/recover-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmailEnviadoScreen(email: email),
          ),
        );
        return;
      }

      // TODO: confirmar el texto/código exacto que devuelve el backend
      // para "usuario no encontrado" — por ahora se muestra el detail tal cual.
      String detail = 'No pudimos procesar la solicitud';
      try {
        final data = jsonDecode(response.body);
        detail = data['detail'] ?? detail;
      } catch (_) {}

      setState(() {
        _errorBanner = detail;
        _fieldErrors = {'email'};
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
                FieldLabel('EMAIL *', hasError: _fieldErrors.contains('email')),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: buildInputDecoration('juan@email.com', hasError: _fieldErrors.contains('email')),
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