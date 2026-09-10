import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kAccentColor = Color(0xFFD4FF00);

/// Fondo compartido: foto de fondo + gradiente oscuro, usado en Login y Register.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  Colors.black.withValues(alpha: 0.88),
                  Colors.black.withValues(alpha: 0.88),
                  Colors.black.withValues(alpha: 0.84),
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
    );
  }
}

/// Decoración compartida para TextFields. `hasError` pinta el borde rojo
/// (usado en validación de campos vacíos y en el caso "usuario ya registrado").
InputDecoration buildInputDecoration(String label, {bool hasError = false}) {
  final errorColor = Colors.red[400]!;
  return InputDecoration(
    hintText: label,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.30), fontSize: 14, fontFamily: 'Inter'),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.08),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: hasError ? errorColor : Colors.white.withValues(alpha: 0.14),
        width: hasError ? 1.3 : 1.13,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: hasError ? errorColor : kAccentColor, width: 1.5),
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
          color: hasError ? Colors.red[300] : Colors.white.withValues(alpha: 0.45),
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