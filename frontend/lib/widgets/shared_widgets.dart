import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Alias de compatibilidad para pantallas que todavía no migraron a
/// context.colors.accent — mismo valor en claro y oscuro, se puede
/// borrar cuando ya no quede ninguna referencia.
const Color kAccentColor = Color(0xFFD4FF00);

/// Fondo compartido: foto de fondo + gradiente, usado en Login, Register y
/// ForgotPassword. Estas pantallas van SIEMPRE en modo oscuro, sin importar
/// el tema elegido por el usuario en Mi Perfil — el toggle claro/oscuro
/// aplica solo a la parte logueada de la app (Home, Sedes, Mi Perfil...).
/// El Figma nunca mostró una versión clara de estas pantallas: la foto +
/// overlay oscuro es el diseño fijo. Por eso se fuerza buildDarkTheme() acá,
/// en un solo lugar, en vez de tocar cada pantalla que usa este widget.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.dark;
    return Theme(
      data: buildDarkTheme(),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Image.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.overlayScrim,
                    colors.overlayScrim,
                    colors.overlayScrim.withValues(alpha: colors.overlayScrim.a * 0.95),
                  ],
                ),
              ),
            ),
          ),
          // El contenido va envuelto en Positioned.fill también. Si no,
          // el Stack termina midiendo lo mismo que el contenido (por ejemplo
          // un SingleChildScrollView se achica al alto de sus campos), y el
          // fondo se corta justo ahí en vez de cubrir toda la pantalla.
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Decoración compartida para TextFields. `hasError` pinta el borde rojo
/// (usado en validación de campos vacíos y en el caso "usuario ya registrado").
InputDecoration buildInputDecoration(BuildContext context, String label, {bool hasError = false}) {
  final colors = context.colors;
  final errorColor = Colors.red[400]!;
  return InputDecoration(
    hintText: label,
    hintStyle: TextStyle(color: colors.textMuted, fontSize: 14, fontFamily: 'Inter'),
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: hasError ? errorColor : colors.surfaceBorder,
        width: hasError ? 1.3 : 1.13,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: hasError ? errorColor : colors.accent, width: 1.5),
    ),
  );
}

/// Label tipo "NOMBRE *" arriba de cada campo, como en el Figma.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool hasError;

  const FieldLabel(this.text, {super.key, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: hasError ? Colors.red[300] : context.colors.textSecondary,
          fontSize: 11,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Banner rojo de error, tipo "Completá todos los campos" / "Este usuario ya esta registrado".
/// El rojo queda fijo en ambos modos — no depende del tema.
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[300], fontSize: 13, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatea el DNI con puntos de miles a medida que se escribe: 38196142 -> 38.196.142
class DniInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
