# Hashea las contraseñas con bcrypt (via passlib): agrega helpers de
# hash/verify, los aplica en registro, login, cambio y recuperacion de
# contrasena, y migra las cuentas existentes que todavia tienen la
# contrasena en texto plano.
# Se corre una sola vez.

from passlib.context import CryptContext
import models, database

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --- main.py: agregar helper de hash, justo despues de get_db() ---
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

if "pwd_context = CryptContext" not in main_content:
    anchor = '''def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()'''
    assert anchor in main_content, "no se encontro get_db() tal como se esperaba"
    nuevo_bloque = anchor + '''

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(password_plano: str, password_hash: str) -> bool:
    try:
        return pwd_context.verify(password_plano, password_hash)
    except Exception:
        return False'''
    main_content = main_content.replace(anchor, nuevo_bloque, 1)
    print("main.py: helpers hash_password / verify_password agregados")
else:
    print("main.py: helpers de password ya existian, no se tocaron")

# --- registrar_usuario: hashear antes de guardar (cuenta nueva) ---
viejo_registro_nuevo = '''    nuevo_usuario = models.Usuario(**usuario.model_dump())
    db.add(nuevo_usuario)'''
nuevo_registro_nuevo = '''    datos_usuario = usuario.model_dump()
    datos_usuario["password"] = hash_password(datos_usuario["password"])
    nuevo_usuario = models.Usuario(**datos_usuario)
    db.add(nuevo_usuario)'''
if viejo_registro_nuevo in main_content:
    main_content = main_content.replace(viejo_registro_nuevo, nuevo_registro_nuevo, 1)
    print("main.py: registro (cuenta nueva) ahora hashea la contrasena")
else:
    print("main.py: bloque de registro (cuenta nueva) no encontrado o ya modificado")

# --- registrar_usuario: hashear antes de guardar (reactivacion de cuenta dada de baja) ---
viejo_reactivar = "        cuenta_inactiva.password = usuario.password"
nuevo_reactivar = "        cuenta_inactiva.password = hash_password(usuario.password)"
if viejo_reactivar in main_content:
    main_content = main_content.replace(viejo_reactivar, nuevo_reactivar, 1)
    print("main.py: reactivacion de cuenta ahora hashea la contrasena")
else:
    print("main.py: bloque de reactivacion no encontrado o ya modificado")

# --- login: verificar con hash en vez de comparar texto plano ---
viejo_login = '''    if user.password.strip() != pass_clean:
        raise HTTPException(status_code=401, detail="Contraseña incorrecta")'''
nuevo_login = '''    if not verify_password(pass_clean, user.password):
        raise HTTPException(status_code=401, detail="Contraseña incorrecta")'''
if viejo_login in main_content:
    main_content = main_content.replace(viejo_login, nuevo_login, 1)
    print("main.py: login ahora verifica con hash")
else:
    print("main.py: bloque de login no encontrado o ya modificado")

# --- change_password: verificar actual con hash, hashear la nueva ---
viejo_change = '''    if user.password.strip() != data.current_password.strip():
        raise HTTPException(status_code=401, detail="La contraseña actual no es correcta")

    user.password = data.new_password'''
nuevo_change = '''    if not verify_password(data.current_password.strip(), user.password):
        raise HTTPException(status_code=401, detail="La contraseña actual no es correcta")

    user.password = hash_password(data.new_password)'''
if viejo_change in main_content:
    main_content = main_content.replace(viejo_change, nuevo_change, 1)
    print("main.py: change_password ahora hashea la contrasena nueva")
else:
    print("main.py: bloque de change_password no encontrado o ya modificado")

# --- recover_password: hashear la nueva contrasena ---
viejo_recover = '''    user.password = data.new_password
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}

@app.put("/auth/change-password")'''
nuevo_recover = '''    user.password = hash_password(data.new_password)
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}

@app.put("/auth/change-password")'''
if viejo_recover in main_content:
    main_content = main_content.replace(viejo_recover, nuevo_recover, 1)
    print("main.py: recover_password ahora hashea la contrasena nueva")
else:
    print("main.py: bloque de recover_password no encontrado o ya modificado")

with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)

# --- migracion: hashear contrasenas existentes que todavia estan en texto plano ---
# Un hash bcrypt siempre arranca con $2 (ej. $2b$12$...) -- si el valor
# guardado no arranca asi, asumimos que es texto plano y lo hasheamos.
db = database.SessionLocal()
try:
    usuarios = db.query(models.Usuario).all()
    migrados = 0
    for u in usuarios:
        if u.password and not u.password.startswith("$2"):
            u.password = pwd_context.hash(u.password)
            migrados += 1
    db.commit()
    print(f"Base de datos: {migrados} contrasena(s) existentes migradas a bcrypt (de {len(usuarios)} usuarios totales)")
finally:
    db.close()
