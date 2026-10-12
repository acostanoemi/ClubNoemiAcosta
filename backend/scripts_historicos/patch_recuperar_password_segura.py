# Cambia el flujo de "olvide mi contrasena" a uno con verificacion real:
# 1) POST /auth/recover-password recibe solo el email, genera un token
#    de reseteo (JWT de corta duracion) y lo devuelve en la respuesta
#    -- por ahora, hasta que haya un servicio de email configurado para
#    mandarlo de verdad por correo.
# 2) POST /auth/reset-password recibe ese token + la nueva contrasena,
#    valida el token y recien ahi cambia la contrasena.
# Se corre una sola vez.

with open("schemas.py", encoding="utf-8") as f:
    content = f.read()

viejo = """class RecoverPassword(BaseModel):
    email: EmailStr
    new_password: str"""

nuevo = """class RecoverPassword(BaseModel):
    email: EmailStr

class ConfirmarRecuperacion(BaseModel):
    token: str
    new_password: str"""

assert viejo in content, "no se encontro RecoverPassword tal como se esperaba"
content = content.replace(viejo, nuevo, 1)

with open("schemas.py", "w", encoding="utf-8") as f:
    f.write(content)
print("schemas.py: RecoverPassword simplificado, ConfirmarRecuperacion agregado")

with open("main.py", encoding="utf-8") as f:
    content = f.read()

viejo = '''@app.post("/auth/recover-password")
def recover_password(data: schemas.RecoverPassword, db: Session = Depends(get_db)):
    user = db.query(models.Usuario).filter(models.Usuario.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.password = hash_password(data.new_password)
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}'''

nuevo = '''RESET_PASSWORD_EXPIRACION_MINUTOS = 30

def crear_token_reset(usuario_id) -> str:
    payload = {
        "sub": str(usuario_id),
        "proposito": "reset_password",
        "exp": datetime.utcnow() + timedelta(minutes=RESET_PASSWORD_EXPIRACION_MINUTOS),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

@app.post("/auth/recover-password")
def recover_password(data: schemas.RecoverPassword, db: Session = Depends(get_db)):
    user = db.query(models.Usuario).filter(models.Usuario.email.ilike(data.email.strip().lower())).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    token_reset = crear_token_reset(user.id)

    # TODO: mandar este enlace por email de verdad cuando haya un servicio
    # de correo configurado (ej. SMTP/SendGrid). Por ahora se devuelve
    # directo en la respuesta para poder probar el flujo completo.
    return {
        "message": "Se genero un enlace de recuperacion",
        "reset_token": token_reset,
    }

@app.post("/auth/reset-password")
def reset_password(data: schemas.ConfirmarRecuperacion, db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(data.token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="El enlace expiro, solicita uno nuevo")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=400, detail="Enlace invalido")

    if payload.get("proposito") != "reset_password":
        raise HTTPException(status_code=400, detail="Enlace invalido")

    user = db.query(models.Usuario).filter(models.Usuario.id == payload["sub"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.password = hash_password(data.new_password)
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}'''

assert viejo in content, "no se encontro recover_password tal como se esperaba"
content = content.replace(viejo, nuevo, 1)

with open("main.py", "w", encoding="utf-8") as f:
    f.write(content)
print("main.py: flujo de recuperacion con token de verificacion agregado")
