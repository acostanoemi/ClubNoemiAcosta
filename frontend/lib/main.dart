import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/shared_widgets.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'session.dart';
import 'screens/mi_perfil_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sedes_screen.dart';
import 'screens/mis_reservas_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_scope.dart';

void main() {
  runApp(const ClubApp());
}

const String apiBaseUrl = "http://localhost:8000";

class ClubApp extends StatefulWidget {
  const ClubApp({super.key});

  @override
  State<ClubApp> createState() => _ClubAppState();
}

class _ClubAppState extends State<ClubApp> {
  final _themeController = ThemeController();

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: _themeController.mode,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot': (context) => const ForgotPasswordScreen(),
              '/perfil': (context) => const MiPerfilScreen(),
              '/home': (context) => const HomeScreen(),
              '/sedes': (context) => const SedesScreen(),
              '/reservas': (context) => const MisReservasScreen(),
            },
            builder: (context, child) {
              const designWidth = 412.0;
              const designHeight = 892.0;

              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = (constraints.maxWidth / designWidth) <
                              (constraints.maxHeight / designHeight)
                          ? constraints.maxWidth / designWidth
                          : constraints.maxHeight / designHeight;

                      return Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: designWidth,
                          height: designHeight,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: const Size(designWidth, designHeight),
                            ),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _loading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Completá email y contraseña');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Session.set(
          id: data['id'],
          email: data['email'],
          nombre: data['nombre'],
          apellido: data['apellido'],
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final data = jsonDecode(response.body);
        _showError(data['detail'] ?? 'No se pudo iniciar sesión');
      }
    } catch (e) {
      _showError('Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
    final nombre = Session.nombre ?? '';
    final apellido = Session.apellido ?? '';
    final iniciales = (nombre.isNotEmpty && apellido.isNotEmpty) ? '${nombre[0]}${apellido[0]}' : '?';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'BIENVENIDO A',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'CLUB ', style: TextStyle(color: colors.textPrimary)),
                        TextSpan(text: 'NOEMI ACOSTA', style: TextStyle(color: colors.accent)),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 38,
                      fontFamily: 'Barlow Condensed',
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestión de espacios deportivos',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: colors.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    decoration: buildInputDecoration(context, 'Email', colorsOverride: AppColors.dark),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: buildInputDecoration(context, 'Contraseña', colorsOverride: AppColors.dark).copyWith(
                      suffixIcon: IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/Icon.svg',
                          width: 16,
                          height: 16,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
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
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Barlow Condensed',
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.surfaceBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o', style: TextStyle(color: colors.textMuted, fontSize: 12, fontFamily: 'Inter')),
                      ),
                      Expanded(child: Divider(color: colors.surfaceBorder)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tenés cuenta? ',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'COMENZAR →',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 13,
                            fontFamily: 'Barlow Condensed',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
