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
/// aplica solo a la parte logueada de la app. El Figma nunca mostró una
/// versión clara de estas pantallas: la foto + overlay oscuro es fijo.
///
/// IMPORTANTE: este widget NO fuerza el tema vía Theme() — Theme.of(context)
/// solo mira hacia arriba en el árbol, así que un override puesto acá adentro
/// nunca lo ven las pantallas que llaman a context.colors con SU PROPIO
/// contexto (el de más arriba). Por eso Login/Register/ForgotPassword usan
/// directamente la constante AppColors.dark (o el parámetro colorsOverride
/// de buildInputDecoration/FieldLabel) en vez de context.colors.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
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
    );
  }
}

/// Decoración compartida para TextFields. `hasError` pinta el borde rojo.
/// `colorsOverride` fuerza una paleta puntual (ej. AppColors.dark en las
/// pantallas de auth) en vez de leer el tema ambiente vía context.colors —
/// necesario porque esas pantallas deben verse siempre oscuras sin importar
/// el modo claro/oscuro elegido en el resto de la app.
InputDecoration buildInputDecoration(BuildContext context, String label, {bool hasError = false, AppColors? colorsOverride}) {
  final colors = colorsOverride ?? context.colors;
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
/// `colorsOverride`: mismo motivo que en buildInputDecoration.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool hasError;
  final AppColors? colorsOverride;

  const FieldLabel(this.text, {super.key, this.hasError = false, this.colorsOverride});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOverride ?? context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: hasError ? Colors.red[300] : colors.textSecondary,
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

/// Colores distintos por deporte, usados en los tags de las tarjetas de
/// sede (Home, Sedes) -- no confundir con `accent`, que es el color de
/// marca general de la app.
const Map<String, Color> coloresDeporte = {
  'Fútbol': Color(0xFF2ECC71),
  'Tenis': Color(0xFFE67E22),
  'Hockey': Color(0xFF9B59B6),
  'Golf': Color(0xFFD4AC0D),
  'Vóley': Color(0xFF1F618D),
};

Color colorDeporte(String deporte) => coloresDeporte[deporte] ?? kAccentColor;

/// Diálogo de confirmación compartido (Cancelar / acción destructiva),
/// usado en "Eliminar cuenta" y "Cerrar sesión" -- mismo estilo visual,
/// theme-aware (a diferencia de las pantallas de auth, que van siempre
/// oscuras). Devuelve true si confirmó, false/null si canceló o cerró
/// el diálogo tocando afuera.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Color? titleColor,
  Color confirmColor = Colors.red,
  IconData? icon,
}) {
  final colors = context.colors;
  return showDialog<bool>(
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
                if (icon != null) ...[
                  Icon(icon, color: titleColor ?? colors.textPrimary, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: titleColor ?? colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(color: colors.textSecondary, fontSize: 14, fontFamily: 'Inter')),
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
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fotos reales por sede/cancha, cargadas de a poco (frontend/assets/images/canchas/).
/// Identificadas por ID (no por nombre) -- los IDs de sede/espacio no cambian
/// nunca, aunque se le edite el nombre a la cancha después. Si un ID todavía
/// no tiene foto propia, se usa `fotoGenerica`.
const String fotoGenerica = 'assets/images/cancha_hero.png';

const Map<String, String> _fotosPorId = {
  // Sedes
  '8db98ffe-f15a-414f-b202-c23408e3dce1': 'assets/images/canchas/castelar.png', // Sede Castelar
  '378b6dec-bc98-4664-8ef2-ed6952a14d7d': 'assets/images/canchas/moron.png', // Sede Morón

  // Canchas
  '7cc9db12-1c8a-4415-afdd-8cdd26c5ee76': 'assets/images/canchas/castelar_voley_playa.png', // Castelar Vóley Playa
  '22eba30a-d991-40d5-800b-78228ac99544': 'assets/images/canchas/castelar_voley_indoor.png', // Castelar Vóley Indoor Parquet
  '530c9230-86d3-4531-851f-3f8863f41489': 'assets/images/canchas/castelar_hockey.png', // Castelar Hockey H11
  'da451a98-80a4-472d-bd8a-419110e86fca': 'assets/images/canchas/castelar_tenis_cemento.png', // Castelar Tenis Cemento
  'da1b9af1-dbf9-495e-8778-4c12a2b95876': 'assets/images/canchas/castelar_tenis_polvo.png', // Castelar Tenis Polvo de Ladrillo
  '7597aeb6-65fb-4f7f-b038-f76e0c68086e': 'assets/images/canchas/sanjusto_f5.png', // San Justo Fútbol F5 Cancha 1
  'b60609a4-f2ef-41f2-87a2-4dd9c9944dc4': 'assets/images/canchas/sanjusto_golf.png', // San Justo Golf Driving Range
  '2b50a486-4872-496b-a74d-ef313220df56': 'assets/images/canchas/sanjusto_golf.png', // San Justo Golf 9 Hoyos (misma foto)
  '28eb3938-ad0e-4fa8-92fb-c62950951672': 'assets/images/canchas/sanjusto_tenis.png', // San Justo Tenis Sintético

  // Reusadas de Castelar (misma subcategoria/deporte, foto real pendiente)
  'af12bc3f-952d-4adf-824b-9a69ee56b735': 'assets/images/canchas/castelar_tenis_polvo.png', // Morón Tenis Polvo Cancha 1
  'a058eb59-689b-429e-a5dd-dc5781d70b95': 'assets/images/canchas/castelar_tenis_polvo.png', // Morón Tenis Polvo Cancha 2
  'ebc97c56-eb9d-44eb-9ac9-3cc92eb1788a': 'assets/images/canchas/castelar_tenis_cemento.png', // Morón Tenis Cemento Cancha 1
  'bfe09c02-0953-4231-b8ab-273ca03a23b1': 'assets/images/canchas/castelar_hockey.png', // Ramos Mejía Hockey H7
  'b594bdbc-c65b-4490-bd10-1b2d6f95e982': 'assets/images/canchas/castelar_voley_indoor.png', // Ramos Mejía Vóley Indoor
};

/// Foto de una sede (para tarjetas de Sedes y el hero de SedeDetalle). Recibe el ID.
String fotoParaSede(String sedeId) => _fotosPorId[sedeId] ?? fotoGenerica;

/// Foto de una cancha puntual (para las tarjetas dentro de SedeDetalle). Recibe el ID.
String fotoParaCancha(String espacioId) => _fotosPorId[espacioId] ?? fotoGenerica;

/// Envuelve cualquier widget tocable y lo achica levemente al presionar
/// (imita el "whileTap" de Framer Motion del diseño original). [scale]
/// es el factor final al presionar -- ej. 0.91 para chips, 0.82 para el
/// bottom nav. [onTap] se dispara al soltar el dedo, como un GestureDetector normal.
class TapScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final VoidCallback? onTap;

  const TapScale({super.key, required this.child, this.scale = 0.95, this.onTap});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) => setState(() => _presionado = false),
      onTapCancel: () => setState(() => _presionado = false),
      child: AnimatedScale(
        scale: _presionado ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Orden visual de las pestanas del bottom nav -- usado para calcular
/// la direccion de la transicion entre pantallas (ver irATab).
const List<String> ordenTabs = ['/home', '/sedes', '/reservas', '/perfil'];

/// Navega entre pestanas del bottom nav, siempre reemplazando toda la
/// pila (nunca apila pantallas), con la direccion de animacion correcta
/// segun el orden de ordenTabs -- hacia adelante desliza desde la derecha,
/// hacia atras desde la izquierda.
void irATab(BuildContext context, {required String actual, required String destino}) {
  if (actual == destino) return;
  final iActual = ordenTabs.indexOf(actual);
  final iDestino = ordenTabs.indexOf(destino);
  final direccion = (iDestino > iActual) ? 1 : -1;
  Navigator.of(context).pushNamedAndRemoveUntil(destino, (route) => false, arguments: direccion);
}
