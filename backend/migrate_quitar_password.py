# Borra la columna password de usuarios. Desde la migracion a Firebase Auth
# las contrasenas las guarda Firebase, y los hashes viejos que quedaban
# aca ya no se usan (y podian quedar desactualizados si alguien la cambio).
# Se corre una sola vez, DESPUES de que Render tenga el models.py sin password.

from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    conn.execute(text("ALTER TABLE usuarios DROP COLUMN IF EXISTS password;"))
    conn.commit()

print("usuarios: columna 'password' eliminada.")
