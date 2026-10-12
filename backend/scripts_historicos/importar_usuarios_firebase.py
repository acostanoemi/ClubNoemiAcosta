# Importa a Firebase Auth los usuarios activos que ya existen en la base.
# Usa el id de cada usuario como uid de Firebase y le pasa el hash bcrypt
# tal cual, asi nadie tiene que resetear su contrasena.
# Se corre una sola vez. Si se vuelve a correr, solo toma los que todavia
# no tienen firebase_uid.
#
# Uso: python importar_usuarios_firebase.py          (muestra que haria)
#      python importar_usuarios_firebase.py --dale   (importa de verdad)

import os
import sys

import firebase_admin
from firebase_admin import credentials, auth

import models, database

APLICAR = "--dale" in sys.argv

if not firebase_admin._apps:
    ruta = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
    firebase_admin.initialize_app(credentials.Certificate(ruta))

db = database.SessionLocal()
try:
    pendientes = db.query(models.Usuario).filter(models.Usuario.firebase_uid.is_(None)).all()

    registros = []
    usuarios_a_importar = []
    for u in pendientes:
        if not u.activo:
            # Las cuentas dadas de baja no se importan: si la persona se
            # vuelve a registrar, /auth/perfil reactiva su fila por email/DNI.
            print(f"  salteado (inactivo): {u.email}")
            continue
        if not u.password or not u.password.startswith("$2"):
            print(f"  salteado (sin hash bcrypt): {u.email}")
            continue
        registros.append(auth.ImportUserRecord(
            uid=str(u.id),
            email=u.email.strip().lower(),
            display_name=f"{u.nombre} {u.apellido}",
            password_hash=u.password.encode("utf-8"),
        ))
        usuarios_a_importar.append(u)
        print(f"  a importar: {u.email}")

    print(f"\n{len(registros)} usuario(s) para importar, de {len(pendientes)} sin firebase_uid.")

    if not APLICAR:
        print("Modo prueba. Para importar de verdad: python importar_usuarios_firebase.py --dale")
        sys.exit(0)

    if not registros:
        sys.exit(0)

    resultado = auth.import_users(registros, hash_alg=auth.UserImportHash.bcrypt())

    fallidos = {e.index for e in resultado.errors}
    for e in resultado.errors:
        print(f"  ERROR {usuarios_a_importar[e.index].email}: {e.reason}")

    for i, u in enumerate(usuarios_a_importar):
        if i not in fallidos:
            u.firebase_uid = str(u.id)
    db.commit()

    print(f"\nImportados: {resultado.success_count}. Fallidos: {resultado.failure_count}.")
finally:
    db.close()
