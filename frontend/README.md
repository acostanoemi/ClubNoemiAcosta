# Club Noemi Acosta — App móvil (Flutter)

Aplicación móvil para la reserva de espacios deportivos del trabajo
práctico de Electiva General. Construida con **Flutter**, conectada a
un backend propio en FastAPI, con notificaciones push vía **Firebase
Cloud Messaging** y persistencia de sesión/tema con `SharedPreferences`.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47 o superior
- El [backend](../backend/README.md) de este mismo proyecto corriendo (local o desplegado)
- Chrome (para correr en modo web) o un emulador/dispositivo Android

## 1. Clonar e instalar dependencias

```bash
git clone <url-de-este-repo>
cd ClubNoemiAcosta/frontend
flutter pub get
```

## 2. Configurar la URL del backend

La app apunta al backend a través de la constante `apiBaseUrl`, definida
en `lib/main.dart`:

```dart
const String apiBaseUrl = "http://localhost:8000";
```

Si el backend corre local, no hay que tocar nada. Si está desplegado
en la nube, hay que cambiar esta URL por la del servidor real antes de
compilar.

## 3. Firebase (notificaciones push)

El proyecto ya viene configurado contra un proyecto de Firebase propio
(las credenciales públicas de Firebase Web están incluidas directamente
en `lib/main.dart`, ya que no son secretas). No hace falta ninguna
configuración adicional para correr la app tal cual está.

## 4. Levantar la app

Para correr en Chrome (desarrollo rápido, recomendado durante el
desarrollo):

```bash
flutter run -d chrome
```

Para correr en un emulador o dispositivo Android conectado:

```bash
flutter run
```

## 5. Generar un build de producción

Android (genera un `.apk` en `build/app/outputs/flutter-apk/`):

```bash
flutter build apk
```

Web (genera archivos estáticos en `build/web/`):

```bash
flutter build web
```

## Estructura del proyecto

```
frontend/
|-- lib/
|   |-- main.dart              # Punto de entrada, rutas, configuracion de Firebase
|   |-- session.dart           # Manejo de sesion del usuario (persistida)
|   |-- notifications.dart     # Registro de token FCM para push
|   |-- models/                # Modelos de datos (Reserva, Sede, Espacio)
|   |-- screens/                # Pantallas de la app
|   |-- widgets/                # Widgets reutilizables (cards, dropdowns, etc.)
|   `-- theme/                  # Colores, tema claro/oscuro
|-- assets/                     # Imagenes, iconos y fuentes
`-- pubspec.yaml                 # Dependencias del proyecto
```

## Dependencias principales

- `http` — llamadas a la API REST del backend
- `firebase_core` / `firebase_messaging` — notificaciones push
- `shared_preferences` — persistencia local de sesion y preferencia de tema
- `flutter_svg` — iconos vectoriales
