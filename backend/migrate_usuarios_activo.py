# Agrega la columna "activo" a la tabla usuarios en la base real (Render).
# Se corre una sola vez. Usa el mismo DATABASE_URL que ya usa la app
# (via database.py), asi que hay que correrlo desde la carpeta backend/
# con el venv activado.

from sqlalchemy import text
import database

with database.engine.connect() as conn:
    conn.execute(text(
        "ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT TRUE"
    ))
    conn.execute(text(
        "UPDATE usuarios SET activo = TRUE WHERE activo IS NULL"
    ))
    conn.commit()

print("Columna 'activo' agregada (o ya existia) en usuarios.")
