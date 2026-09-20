# Club Noemi Acosta

Aplicación móvil para la gestión y reserva de espacios deportivos -
Trabajo Práctico de Electiva General, Universidad de Morón.

Los usuarios pueden registrarse, consultar la disponibilidad de
canchas en distintas sedes, reservar un espacio deportivo, y recibir
notificaciones push sobre sus próximas reservas.

## Stack

| Capa | Tecnología |
|---|---|
| App móvil | Flutter |
| Backend / API REST | Python + FastAPI |
| Base de datos | PostgreSQL |
| Autenticación | JWT + bcrypt |
| Notificaciones push | Firebase Cloud Messaging |
| Hosting | Render (API + base de datos) |
| Documentación de la API | Swagger / OpenAPI (automática) |

## Funcionalidades

- Registro, login y recuperación de contraseña (con token de verificación)
- Perfil de usuario: ver, editar (menos el email), dar de baja
- Consultar sedes, sus horarios, y sus espacios deportivos
- Filtrar espacios deportivos por tipo (Fútbol, Tenis, Hockey, Vóley, Golf)
- Consultar disponibilidad de una cancha por fecha y horario
- Reservar un espacio deportivo (con todas las validaciones que exige la consigna: horario en punto, duración mínima, dentro del horario de la sede, sin superposición, solo a futuro)
- Modificar o cancelar una reserva
- Historial completo de reservas (incluidas las finalizadas y las canceladas)
- Notificaciones push: cancelación de reserva, y recordatorio 24hs antes de una reserva próxima
- Historial de notificaciones dentro de la app
- Modo claro / oscuro, con la preferencia guardada

## Estructura del repositorio

```
ClubNoemiAcosta/
|-- backend/    # API REST en FastAPI -- ver backend/README.md
|-- frontend/   # App en Flutter -- ver frontend/README.md
`-- MODELO_DE_DATOS.md   # Entidades, atributos y relaciones (diagrama incluido)
```

## Cómo correr el proyecto

Cada parte tiene su propio README con los pasos detallados de
instalación:

- **[backend/README.md](backend/README.md)** — cómo levantar la API localmente, variables de entorno necesarias, y cómo está desplegada en Render
- **[frontend/README.md](frontend/README.md)** — cómo correr la app en Chrome o en un emulador/dispositivo Android

## API desplegada

La API corre en Render y está documentada con Swagger:

- **Base URL:** https://https-club-noemi-acosta-backend-onrender.onrender.com
- **Documentación interactiva:** https://https-club-noemi-acosta-backend-onrender.onrender.com/docs

> El plan gratuito de Render "duerme" el servicio tras 15 minutos sin
> uso — el primer pedido después de eso puede tardar 30-60 segundos
> en responder mientras se reactiva.

## Modelo de datos

Ver **[MODELO_DE_DATOS.md](MODELO_DE_DATOS.md)** para el detalle
completo de entidades, atributos y relaciones, con diagrama
entidad-relación.

## Contexto académico

Trabajo Práctico de la materia Electiva General, Universidad de
Morón. Entrega individual, defendida individualmente.
