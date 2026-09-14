import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'session.dart';

/// Clave VAPID generada en Firebase Console > Cloud Messaging > Web Push certificates.
const String _vapidKey =
    'BL4G53FsPWjG7WVofTwm-Gkq1avLKpYHOsRErylXPPoCfQ7-KDVaNKRtXAW6ce7648PjXshzgxTcq9e0kUP5TBc';

class Notifications {
  /// Pide permiso de notificaciones, obtiene el token FCM del navegador
  /// y lo registra contra el backend para el usuario logueado actual.
  /// Si algo falla (permiso denegado, sin conexión, etc.) no rompe nada
  /// más -- las notificaciones son un extra, no un requisito para usar la app.
  static Future<void> registrarToken(String apiBaseUrl) async {
    if (Session.id == null) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      final permitido =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!permitido) return;

      final token = await messaging.getToken(vapidKey: _vapidKey);
      if (token == null) return;

      await http.post(
        Uri.parse('$apiBaseUrl/usuarios/${Session.id}/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (e) {
      // Silencioso a propósito: un fallo acá no debe interrumpir el login.
      // ignore: avoid_print
      print('No se pudo registrar el token de notificaciones: $e');
    }
  }
}
