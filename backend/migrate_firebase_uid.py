# Prepara la tabla usuarios para Firebase Auth.
# - Agrega firebase_uid (unico, nullable mientras migramos).
# - password pasa a aceptar NULL: las cuentas nuevas no guardan contrasena aca.
# Se corre una sola vez, como migrate_fcm_token.py.

from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    conn.execute(text(
        "ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR UNIQUE;"
    ))
    conn.execute(text(
        "ALTER TABLE usuarios ALTER COLUMN password DROP NOT NULL;"
    ))
    conn.commit()

print("usuarios: columna 'firebase_uid' lista y 'password' ahora acepta NULL.")
