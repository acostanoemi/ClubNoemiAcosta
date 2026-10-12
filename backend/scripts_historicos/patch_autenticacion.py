# Agrega autenticacion real con JWT: el login genera un token firmado,
# y los endpoints de usuarios/reservas exigen ese token y verifican que
# el usuario_id de la operacion coincida con el dueño del token.
# Se corre una sola vez.

with open("main.py", encoding="utf-8") as f:
    content = f.read()

# --- 1) Imports: Header + jwt ---
viejo = 'from fastapi import FastAPI, HTTPException, Depends, status'
nuevo = 'from fastapi import FastAPI, HTTPException, Depends, status, Header'
assert viejo in content, "no se encontro el import de fastapi"
content = content.replace(viejo, nuevo, 1)

viejo = 'import bcrypt\n\ndef hash_password'
nuevo = 'import bcrypt\nimport jwt\n\ndef hash_password'
assert viejo in content, "no se encontro el import de bcrypt"
content = content.replace(viejo, nuevo, 1)

# --- 2) Helpers de JWT, justo despues de verify_password ---
viejo = '''def verify_password(password_plano: str, password_hash: str) -> bool:
    try:
        password_bytes = password_plano.encode("utf-8")[:72]
        return bcrypt.checkpw(password_bytes, password_hash.encode("utf-8"))
    except Exception:
        return False

# --- AUTENTICACIÓN ---'''

nuevo = '''def verify_password(password_plano: str, password_hash: str) -> bool:
    try:
        password_bytes = password_plano.encode("utf-8")[:72]
        return bcrypt.checkpw(password_bytes, password_hash.encode("utf-8"))
    except Exception:
        return False

# --- JWT: identificacion del usuario autenticado ---
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = "HS256"
JWT_EXPIRACION_DIAS = 30

def crear_token(usuario_id) -> str:
    payload = {
        "sub": str(usuario_id),
        "exp": datetime.utcnow() + timedelta(days=JWT_EXPIRACION_DIAS),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

def obtener_usuario_actual(authorization: str = Header(None), db: Session = Depends(get_db)) -> models.Usuario:
    """Dependencia que exige un token valido en el header Authorization
    (formato 'Bearer <token>') y devuelve el usuario autenticado.
    Se usa en todos los endpoints que operan sobre usuarios o reservas,
    segun lo pedido por la consigna."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No autenticado")
    token = authorization[len("Bearer "):].strip()
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="La sesion expiro, iniciá sesion de nuevo")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Token invalido")
    usuario = db.query(models.Usuario).filter(models.Usuario.id == payload["sub"]).first()
    if not usuario or not usuario.activo:
        raise HTTPException(status_code=401, detail="Usuario no encontrado o inactivo")
    return usuario

# --- AUTENTICACIÓN ---'''

assert viejo in content, "no se encontro el bloque previo a AUTENTICACION"
content = content.replace(viejo, nuevo, 1)

# --- 3) Login: incluir el token en la respuesta ---
viejo = '''    return {
        "message": "Login exitoso",
        "id": str(user.id),
        "email": user.email,
        "nombre": user.nombre,
        "apellido": user.apellido
    }'''

nuevo = '''    return {
        "message": "Login exitoso",
        "id": str(user.id),
        "email": user.email,
        "nombre": user.nombre,
        "apellido": user.apellido,
        "token": crear_token(user.id)
    }'''

assert viejo in content, "no se encontro el return del login"
content = content.replace(viejo, nuevo, 1)

# --- 4) GET /usuarios/{id}: usa usuario_actual directo, sin re-consultar ---
viejo = '''@app.get("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
def obtener_usuario(usuario_id: UUID, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return usuario'''

nuevo = '''@app.get("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
def obtener_usuario(usuario_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    return usuario_actual'''

assert viejo in content, "no se encontro obtener_usuario"
content = content.replace(viejo, nuevo, 1)

# --- 5) PATCH /usuarios/{id} ---
viejo = '''@app.patch("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
def actualizar_usuario(usuario_id: UUID, datos: schemas.UsuarioUpdate, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    actualizaciones = datos.model_dump(exclude_unset=True)

    if "dni" in actualizaciones:
        dni_exist = db.query(models.Usuario).filter(
            models.Usuario.dni == actualizaciones["dni"],
            models.Usuario.id != usuario_id
        ).first()
        if dni_exist:
            raise HTTPException(status_code=400, detail="El DNI ya esta registrado")

    for campo, valor in actualizaciones.items():
        setattr(usuario, campo, valor)

    db.commit()
    db.refresh(usuario)
    return usuario'''

nuevo = '''@app.patch("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
def actualizar_usuario(usuario_id: UUID, datos: schemas.UsuarioUpdate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")

    actualizaciones = datos.model_dump(exclude_unset=True)

    if "dni" in actualizaciones:
        dni_exist = db.query(models.Usuario).filter(
            models.Usuario.dni == actualizaciones["dni"],
            models.Usuario.id != usuario_id
        ).first()
        if dni_exist:
            raise HTTPException(status_code=400, detail="El DNI ya esta registrado")

    for campo, valor in actualizaciones.items():
        setattr(usuario_actual, campo, valor)

    db.commit()
    db.refresh(usuario_actual)
    return usuario_actual'''

assert viejo in content, "no se encontro actualizar_usuario"
content = content.replace(viejo, nuevo, 1)

# --- 6) DELETE /usuarios/{id} (baja) ---
viejo = '''@app.delete("/usuarios/{usuario_id}")
def dar_de_baja_usuario(usuario_id: UUID, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario.activo = False
    db.commit()
    return {"message": "Cuenta dada de baja"}'''

nuevo = '''@app.delete("/usuarios/{usuario_id}")
def dar_de_baja_usuario(usuario_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    usuario_actual.activo = False
    db.commit()
    return {"message": "Cuenta dada de baja"}'''

assert viejo in content, "no se encontro dar_de_baja_usuario"
content = content.replace(viejo, nuevo, 1)

# --- 7) POST fcm-token ---
viejo = '''@app.post("/usuarios/{usuario_id}/fcm-token")
def registrar_fcm_token(usuario_id: UUID, datos: schemas.FcmTokenUpdate, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario.fcm_token = datos.fcm_token
    db.commit()
    return {"message": "Token registrado"}'''

nuevo = '''@app.post("/usuarios/{usuario_id}/fcm-token")
def registrar_fcm_token(usuario_id: UUID, datos: schemas.FcmTokenUpdate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    usuario_actual.fcm_token = datos.fcm_token
    db.commit()
    return {"message": "Token registrado"}'''

assert viejo in content, "no se encontro registrar_fcm_token"
content = content.replace(viejo, nuevo, 1)

# --- 8) GET notificaciones ---
viejo = '''@app.get("/usuarios/{usuario_id}/notificaciones", response_model=List[schemas.NotificacionResponse])
def obtener_notificaciones(usuario_id: UUID, db: Session = Depends(get_db)):
    return db.query(models.Notificacion).filter(
        models.Notificacion.usuario_id == usuario_id
    ).order_by(models.Notificacion.creada_en.desc()).all()'''

nuevo = '''@app.get("/usuarios/{usuario_id}/notificaciones", response_model=List[schemas.NotificacionResponse])
def obtener_notificaciones(usuario_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    return db.query(models.Notificacion).filter(
        models.Notificacion.usuario_id == usuario_id
    ).order_by(models.Notificacion.creada_en.desc()).all()'''

assert viejo in content, "no se encontro obtener_notificaciones"
content = content.replace(viejo, nuevo, 1)

# --- 9) PATCH notificaciones/{id} ---
viejo = '''@app.patch("/notificaciones/{notificacion_id}")
def marcar_notificacion_leida(notificacion_id: UUID, db: Session = Depends(get_db)):
    notif = db.query(models.Notificacion).filter(models.Notificacion.id == notificacion_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    notif.leida = True
    db.commit()
    return {"message": "Notificación marcada como leída"}'''

nuevo = '''@app.patch("/notificaciones/{notificacion_id}")
def marcar_notificacion_leida(notificacion_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    notif = db.query(models.Notificacion).filter(models.Notificacion.id == notificacion_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    if notif.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")
    notif.leida = True
    db.commit()
    return {"message": "Notificación marcada como leída"}'''

assert viejo in content, "no se encontro marcar_notificacion_leida"
content = content.replace(viejo, nuevo, 1)

# --- 10) GET /reservas ---
viejo = '''@app.get("/reservas", response_model=List[schemas.ReservaResponse])
def obtener_reservas(usuario_id: Optional[UUID] = None, espacio_id: Optional[UUID] = None, fecha: Optional[date] = None, incluir_canceladas: bool = False, db: Session = Depends(get_db)):
    query = db.query(models.Reserva)'''

nuevo = '''@app.get("/reservas", response_model=List[schemas.ReservaResponse])
def obtener_reservas(usuario_id: Optional[UUID] = None, espacio_id: Optional[UUID] = None, fecha: Optional[date] = None, incluir_canceladas: bool = False, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_id is not None and usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")
    query = db.query(models.Reserva)'''

assert viejo in content, "no se encontro obtener_reservas"
content = content.replace(viejo, nuevo, 1)

# --- 11) POST /reservas: usuario_id sale del token, no del body ---
viejo = '''def crear_reserva(reserva: schemas.ReservaCreate, db: Session = Depends(get_db)):'''
nuevo = '''def crear_reserva(reserva: schemas.ReservaCreate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):'''
assert viejo in content, "no se encontro la firma de crear_reserva"
content = content.replace(viejo, nuevo, 1)

viejo = '''    nueva_reserva = models.Reserva(
        usuario_id=reserva.usuario_id,
        espacio_id=reserva.espacio_id,'''
nuevo = '''    nueva_reserva = models.Reserva(
        usuario_id=usuario_actual.id,
        espacio_id=reserva.espacio_id,'''
assert viejo in content, "no se encontro la construccion de nueva_reserva"
content = content.replace(viejo, nuevo, 1)

# --- 12) PATCH /reservas/{id}: solo el dueño puede modificar ---
viejo = '''def modificar_reserva(reserva_id: UUID, datos: schemas.ReservaUpdate, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reserva.estado == "cancelada":'''

nuevo = '''def modificar_reserva(reserva_id: UUID, datos: schemas.ReservaUpdate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reserva.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")
    if reserva.estado == "cancelada":'''

assert viejo in content, "no se encontro modificar_reserva"
content = content.replace(viejo, nuevo, 1)

# --- 13) DELETE /reservas/{id}: solo el dueño puede cancelar ---
viejo = '''def cancelar_reserva(reserva_id: UUID, forzada: bool = False, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")

    reserva.estado = "cancelada"'''

nuevo = '''def cancelar_reserva(reserva_id: UUID, forzada: bool = False, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reserva.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")

    reserva.estado = "cancelada"'''

assert viejo in content, "no se encontro cancelar_reserva"
content = content.replace(viejo, nuevo, 1)

with open("main.py", "w", encoding="utf-8") as f:
    f.write(content)

print("main.py: autenticacion con JWT aplicada en los 13 puntos")

# --- schemas.py: sacar usuario_id de ReservaCreate (ahora viene del token) ---
with open("schemas.py", encoding="utf-8") as f:
    s = f.read()

viejo_s = '''class ReservaCreate(BaseModel):
    usuario_id: UUID
    espacio_id: UUID'''
nuevo_s = '''class ReservaCreate(BaseModel):
    espacio_id: UUID'''
assert viejo_s in s, "no se encontro ReservaCreate"
s = s.replace(viejo_s, nuevo_s, 1)

with open("schemas.py", "w", encoding="utf-8") as f:
    f.write(s)
print("schemas.py: usuario_id sacado de ReservaCreate (ahora viene del token)")
