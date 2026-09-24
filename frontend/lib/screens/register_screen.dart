import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

// Mismo host que main.dart usa para /auth/login.
const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _birthDate;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _success = false;

  String? _errorBanner;
  Set<String> _fieldErrors = {};

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await mostrarSelectorFecha(
      context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _fieldErrors.remove('fecha');
      });
    }
  }

  bool _validateFields() {
    final missing = <String>{};
    if (_nombreController.text.trim().isEmpty) missing.add('nombre');
    if (_apellidoController.text.trim().isEmpty) missing.add('apellido');
    if (_dniController.text.trim().isEmpty) missing.add('dni');
    if (_birthDate == null) missing.add('fecha');
    if (_emailController.text.trim().isEmpty) missing.add('email');
    if (_passwordController.text.length < 8) missing.add('password');

    if (missing.isNotEmpty) {
      setState(() {
        _fieldErrors = missing;
        _errorBanner = 'Completá todos los campos';
      });
      return false;
    }
    return true;
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorBanner = null;
      _fieldErrors = {};
    });

    if (!_validateFields()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    User? usuarioFirebase;

    try {
      // 1. Firebase crea la cuenta (email + contraseña).
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      usuarioFirebase = credencial.user!;
      final token = await usuarioFirebase.getIdToken();

      // 2. El backend guarda los datos del club atados a ese uid.
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'dni': _dniController.text.trim(),
          'fecha_nacimiento': _birthDate!.toIso8601String().split('T').first,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // createUser deja la sesion iniciada; se cierra para que el
        // flujo siga igual que antes (cartel de exito y despues login).
        await FirebaseAuth.instance.signOut();
        setState(() => _success = true);
        return;
      }

      // El backend rechazo el perfil (ej. DNI repetido): se borra la
      // cuenta de Firebase recien creada para no dejarla huerfana.
      await usuarioFirebase.delete();

      String detail = 'No se pudo crear la cuenta';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        detail = data['detail'] ?? detail;
      } catch (_) {}

      final dniRepetido = detail.toLowerCase().contains('dni');
      setState(() {
        _errorBanner = detail;
        _fieldErrors = dniRepetido ? {'dni'} : {};
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorBanner = 'Este email ya está registrado';
            _fieldErrors = {'email'};
            break;
          case 'invalid-email':
            _errorBanner = 'El email no es válido';
            _fieldErrors = {'email'};
            break;
          case 'weak-password':
            _errorBanner = 'La contraseña es muy débil';
            _fieldErrors = {'password'};
            break;
          default:
            _errorBanner = 'No se pudo crear la cuenta';
        }
      });
    } catch (e) {
      await usuarioFirebase?.delete();
      if (mounted) setState(() => _errorBanner = 'Sin conexión con el servidor');
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
                  'NUEVA CUENTA',
                  style: TextStyle(
                    color: kAccentColor,
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                _success
                    ? _buildSuccessCard()
                    : _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'CREAR ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'CUENTA', style: TextStyle(color: kAccentColor)),
            ],
          ),
          style: const TextStyle(
            fontSize: 38,
            fontFamily: 'Barlow Condensed',
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                '¡Usuario Registrado!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'VOLVER AL LOGIN',
                    style: TextStyle(fontSize: 14, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'CREAR ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'CUENTA', style: TextStyle(color: kAccentColor)),
            ],
          ),
          style: const TextStyle(
            fontSize: 38,
            fontFamily: 'Barlow Condensed',
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        if (_errorBanner != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(message: _errorBanner!),
        ],
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel('NOMBRE *', hasError: _fieldErrors.contains('nombre'), colorsOverride: AppColors.dark),
                  TextField(
                    controller: _nombreController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration(context, 'Juan', hasError: _fieldErrors.contains('nombre'), colorsOverride: AppColors.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel('APELLIDO *', hasError: _fieldErrors.contains('apellido'), colorsOverride: AppColors.dark),
                  TextField(
                    controller: _apellidoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration(context, 'Pérez', hasError: _fieldErrors.contains('apellido'), colorsOverride: AppColors.dark),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FieldLabel('DNI *', hasError: _fieldErrors.contains('dni'), colorsOverride: AppColors.dark),
        TextField(
          controller: _dniController,
          keyboardType: TextInputType.number,
          inputFormatters: [DniInputFormatter()],
          style: const TextStyle(color: Colors.white),
          decoration: buildInputDecoration(context, '31.234.567', hasError: _fieldErrors.contains('dni'), colorsOverride: AppColors.dark),
        ),
        const SizedBox(height: 16),
        FieldLabel('FECHA DE NACIMIENTO *', hasError: _fieldErrors.contains('fecha'), colorsOverride: AppColors.dark),
        TextField(
          controller: _birthDateController,
          readOnly: true,
          onTap: _pickBirthDate,
          style: const TextStyle(color: Colors.white),
          decoration: buildInputDecoration(context, '', hasError: _fieldErrors.contains('fecha'), colorsOverride: AppColors.dark),
        ),
        const SizedBox(height: 16),
        FieldLabel('EMAIL *', hasError: _fieldErrors.contains('email'), colorsOverride: AppColors.dark),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: buildInputDecoration(context, 'juan@email.com', hasError: _fieldErrors.contains('email'), colorsOverride: AppColors.dark),
        ),
        const SizedBox(height: 16),
        FieldLabel('CONTRASEÑA *', hasError: _fieldErrors.contains('password'), colorsOverride: AppColors.dark),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: buildInputDecoration(context, 'Mínimo 8 caracteres', hasError: _fieldErrors.contains('password'), colorsOverride: AppColors.dark).copyWith(
            suffixIcon: IconButton(
              icon: SvgPicture.asset('assets/icons/Icon.svg', width: 16, height: 16),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleRegister,
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
                    'CREAR CUENTA',
                    style: TextStyle(fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
          ),
        ),
      ],
    );
  }
}
