import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// TODO: no existe endpoint de notificaciones en el backend todavía.
// Esta lista es mock para completar el diseño.
class NotificationsDropdown extends StatelessWidget {
  final VoidCallback onClose;

  const NotificationsDropdown({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notis = [
      ('Reserva confirmada – Tenis 19:00', true),
      ('Recordatorio: Fútbol el 20 de agosto', false),
      ('Nueva cancha en Castelar disponible', false),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bottomSheetBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notificaciones', style: TextStyle(color: colors.textPrimary, fontSize: 17, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800)),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close, color: colors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notis.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: n.$2 ? colors.accentText : colors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(n.$1, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Inter')),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
