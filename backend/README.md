# Club Noemi Acosta — Backend

API REST para la gestión de espacios deportivos (sedes, canchas, reservas,
usuarios y notificaciones push) del trabajo práctico de Electiva General.

Construida con **FastAPI** + **SQLAlchemy** + **PostgreSQL**, con
notificaciones push vía **Firebase Cloud Messaging**.

## Requisitos

- Python 3.10 o superior
- Una base de datos PostgreSQL (local o en la nube, por ejemplo [Render](https://render.com))
- Credenciales de un proyecto de Firebase con Cloud Messaging habilitado

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

*(Pendiente — ver sección de despliegue una vez configurado en Render u otro proveedor.)*
