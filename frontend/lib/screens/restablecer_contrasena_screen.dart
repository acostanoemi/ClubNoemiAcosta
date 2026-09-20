import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class RestablecerContrasenaScreen extends StatefulWidget {
  final String token;

  const RestablecerContrasenaScreen({super.key, required this.token});

  @override
  State<RestablecerContrasenaScreen> createState() => _RestablecerContrasenaScreenState();
}

class _RestablecerContrasenaScreenState extends State<RestablecerContrasenaScreen> {
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorBanner;
  bool _exito = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _handleRestablecer() async {
    setState(() => _errorBanner = null);

    final nueva = _passwordController.text.trim();
    final confirmar = _confirmarController.text.trim();

    if (nueva.isEmpty || nueva.length < 6) {
      setState(() => _errorBanner = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (nueva != confirmar) {
      setState(() => _errorBanner = 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token, 'new_password': nueva}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _exito = true);
      } else {
        String detail = 'No pudimos restablecer la contraseña';
        try {
          final data = jsonDecode(response.body);
          detail = data['detail'] ?? detail;
        } catch (_) {}
        setState(() => _errorBanner = detail);
      }
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
                if (!_exito) ...[
                  Text(
                    'RECUPERACIÓN',
                    style: TextStyle(color: kAccentColor, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w900, letterSpacing: 4),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'NUEVA ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'CONTRASEÑA', style: TextStyle(color: kAccentColor)),
                      ],
                    ),
                    style: const TextStyle(fontSize: 34, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresá tu nueva contraseña.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13, fontFamily: 'Inter'),
                  ),
                  if (_errorBanner != null) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(message: _errorBanner!),
                  ],
                  const SizedBox(height: 24),
                  FieldLabel('NUEVA CONTRASEÑA *', colorsOverride: AppColors.dark),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration(context, '••••••••', colorsOverride: AppColors.dark).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FieldLabel('CONFIRMAR CONTRASEÑA *', colorsOverride: AppColors.dark),
                  TextField(
                    controller: _confirmarController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration(context, '••••••••', colorsOverride: AppColors.dark),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleRestablecer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('RESTABLECER', style: TextStyle(fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 60),
                  Icon(Icons.check_circle, color: kAccentColor, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Contraseña actualizada!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ya podés iniciar sesión con tu nueva contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('VOLVER AL LOGIN', style: TextStyle(fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
