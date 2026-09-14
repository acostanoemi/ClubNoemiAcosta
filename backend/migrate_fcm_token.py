# Agrega la columna fcm_token a la tabla usuarios en Postgres.
# SQLAlchemy no migra tablas existentes solo, asi que esto se corre a mano
# una vez, despues de que el modelo ya tenga el campo declarado.

from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    conn.execute(text(
        "ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS fcm_token VARCHAR;"
    ))
    conn.commit()

print("Columna 'fcm_token' agregada (o ya existia) en usuarios.")
