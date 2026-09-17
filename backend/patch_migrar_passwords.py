# Migra a bcrypt las contrasenas que todavia estan en texto plano.
# Se corre una sola vez.

import bcrypt
import models, database

db = database.SessionLocal()
try:
    usuarios = db.query(models.Usuario).all()
    migrados = 0
    for u in usuarios:
        if u.password and not u.password.startswith("$2"):
            password_bytes = u.password.encode("utf-8")[:72]
            u.password = bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")
            migrados += 1
    db.commit()
    print(f"Base de datos: {migrados} contrasena(s) existentes migradas a bcrypt (de {len(usuarios)} usuarios totales)")
finally:
    db.close()
