"""
Corre una sola vez para agregar las columnas nuevas a espacios_deportivos.
Usa la misma DATABASE_URL del .env que ya usa el backend.
"""
from database import engine
from sqlalchemy import text

comandos = [
    "ALTER TABLE espacios_deportivos ADD COLUMN IF NOT EXISTS subcategoria VARCHAR",
    "ALTER TABLE espacios_deportivos ADD COLUMN IF NOT EXISTS ambiente VARCHAR",
    "ALTER TABLE espacios_deportivos ADD COLUMN IF NOT EXISTS iluminada BOOLEAN DEFAULT false",
    "ALTER TABLE espacios_deportivos ADD COLUMN IF NOT EXISTS hora_apertura TIME",
    "ALTER TABLE espacios_deportivos ADD COLUMN IF NOT EXISTS hora_cierre TIME",
]

with engine.connect() as conn:
    for cmd in comandos:
        print(f"Ejecutando: {cmd}")
        conn.execute(text(cmd))
    conn.commit()

print("Listo, columnas agregadas.")