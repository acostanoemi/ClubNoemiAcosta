# Club Noemi Acosta — Backend

API REST para la gestión de espacios deportivos (sedes, canchas, reservas,
usuarios y notificaciones push) del trabajo práctico de Electiva General.

Construida con **FastAPI** + **SQLAlchemy** + **PostgreSQL**. La
autenticación la hace **Firebase Authentication**: la app se loguea contra
Firebase y manda el ID token en el header `Authorization: Bearer <token>`,
que el backend verifica con el Firebase Admin SDK. Las notificaciones push
van por **Firebase Cloud Messaging**.

## Requisitos

- Python 3.10 o superior
- Una base de datos PostgreSQL (local o en la nube, por ejemplo [Render](https://render.com))
- Credenciales de un proyecto de Firebase con Cloud Messaging y Authentication (proveedor Email/Password) habilitados

## 1. Clonar e instalar dependencias

```bash
git clone <url-de-este-repo>
cd ClubNoemiAcosta/backend
python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## 2. Variables de entorno

Copiar `.env.example` a `.env` y completar con los datos reales:

```bash
cp .env.example .env
```

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | Connection string de PostgreSQL, formato `postgresql://usuario:password@host/nombre_base` |

## 3. Credenciales de Firebase

Descargar el archivo de credenciales de servicio desde Firebase Console
(**⚙️ Configuración del proyecto → Cuentas de servicio → Generar nueva
clave privada**) y guardarlo en la raíz de `backend/` con el nombre
`firebase-credentials.json`. Este archivo no se sube al repositorio
(está en `.gitignore`) porque contiene credenciales privadas.

## 4. Crear las tablas de la base de datos

Con `DATABASE_URL` ya configurado en `.env`, correr una sola vez:

```bash
python crear_tablas.py
```

Esto crea todas las tablas (usuarios, sedes, espacios_deportivos,
reservas, notificaciones) a partir de los modelos definidos en
`models.py`. Si las tablas ya existen, no hace nada.

## 5. Levantar el servidor

```bash
uvicorn main:app --reload
```

La API queda disponible en `http://127.0.0.1:8000`, y la documentación
interactiva (Swagger) en `http://127.0.0.1:8000/docs`.

## Estructura del proyecto

```
backend/
|-- main.py                    # Endpoints de la API (FastAPI)
|-- models.py                  # Modelos de SQLAlchemy (tablas)
|-- schemas.py                 # Esquemas de Pydantic (validacion de datos)
|-- database.py                # Configuracion de conexion a PostgreSQL
|-- crear_tablas.py            # Script para crear las tablas desde cero
|-- firebase-credentials.json  # Credenciales de Firebase (no versionado)
`-- requirements.txt           # Dependencias de Python
```

Los archivos `patch_*.py`, `migrate_*.py`, `fix_*.py/.sh/.ps1` y
`seed.py` son scripts puntuales usados durante el desarrollo para
migrar la base de datos o corregir datos ya cargados; no son necesarios
para levantar el proyecto desde cero y quedan documentados acá solo
como registro histórico del desarrollo.

## Despliegue en la nube

El backend está desplegado en [Render](https://render.com) como Web
Service, conectado a la misma base de datos PostgreSQL usada en
desarrollo. URL pública:

https://https-club-noemi-acosta-backend-onrender.onrender.com

Documentación interactiva (Swagger):
https://https-club-noemi-acosta-backend-onrender.onrender.com/docs

### Configuración usada en Render

- **Root Directory:** `backend`
- **Build Command:** `pip install -r requirements.txt && python crear_tablas.py`
- **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Variables de entorno:**
  - `DATABASE_URL` — Internal Database URL de la base PostgreSQL en Render
  - `FIREBASE_CREDENTIALS_PATH` — `/etc/secrets/firebase-credentials.json`
- **Secret File:** `firebase-credentials.json`, con el contenido del
  archivo de credenciales de Firebase (el mismo usado en desarrollo
  local)

El plan usado es el gratuito (Free), que "duerme" el servicio tras 15
minutos de inactividad — el primer pedido después de eso puede tardar
30-60 segundos en responder mientras el servicio se reactiva.
