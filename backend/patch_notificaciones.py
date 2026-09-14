# Agrega notificaciones push (Firebase Cloud Messaging) al cancelar una
# reserva: columna fcm_token en Usuario, endpoint para que el frontend
# registre el token del navegador, inicializacion de Firebase Admin, y
# el envio del push dentro de cancelar_reserva.
# Se corre una sola vez.

# --- models.py: agregar campo fcm_token a Usuario ---
with open("models.py", encoding="utf-8") as f:
    models_content = f.read()

if "fcm_token = Column(String, nullable=True)" not in models_content:
    anchor = (
        "    activo = Column(Boolean, default=True)\n\n"
        "    reservas = relationship(\"Reserva\", back_populates=\"usuario\")"
    )
    assert anchor in models_content, "no se encontro el bloque esperado en el modelo Usuario"
    nuevo = (
        "    activo = Column(Boolean, default=True)\n"
        "    fcm_token = Column(String, nullable=True)\n\n"
        "    reservas = relationship(\"Reserva\", back_populates=\"usuario\")"
    )
    models_content = models_content.replace(anchor, nuevo, 1)
    with open("models.py", "w", encoding="utf-8") as f:
        f.write(models_content)
    print("models.py: campo 'fcm_token' agregado a Usuario")
else:
    print("models.py: 'fcm_token' ya estaba en Usuario, no se toco")

# --- schemas.py: agregar FcmTokenUpdate ---
with open("schemas.py", encoding="utf-8") as f:
    schemas_content = f.read()

if "class FcmTokenUpdate" not in schemas_content:
    anchor = "class UsuarioResponse(BaseModel):"
    assert anchor in schemas_content, "no se encontro UsuarioResponse en schemas.py"
    nuevo_schema = (
        "class FcmTokenUpdate(BaseModel):\n"
        "    fcm_token: str\n\n"
        + anchor
    )
    schemas_content = schemas_content.replace(anchor, nuevo_schema, 1)
    with open("schemas.py", "w", encoding="utf-8") as f:
        f.write(schemas_content)
    print("schemas.py: FcmTokenUpdate agregado")
else:
    print("schemas.py: FcmTokenUpdate ya existia, no se toco")

# --- main.py: inicializar Firebase, endpoint de token, push en cancelar ---
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

# 1) Imports e inicializacion de Firebase Admin, justo despues de los imports existentes
if "import firebase_admin" not in main_content:
    anchor = "import models, schemas, database"
    assert anchor in main_content, "no se encontro el import de models/schemas/database"
    nuevo_import = (
        anchor + "\n\n"
        "import firebase_admin\n"
        "from firebase_admin import credentials, messaging\n\n"
        "if not firebase_admin._apps:\n"
        "    cred = credentials.Certificate(\"firebase-credentials.json\")\n"
        "    firebase_admin.initialize_app(cred)"
    )
    main_content = main_content.replace(anchor, nuevo_import, 1)
    print("main.py: inicializacion de Firebase Admin agregada")
else:
    print("main.py: Firebase Admin ya estaba importado, no se toco")

# 2) Endpoint para que el frontend registre/actualice el token FCM del usuario
if '@app.post("/usuarios/{usuario_id}/fcm-token")' not in main_content:
    anchor = "# --- SEDES ---"
    assert anchor in main_content, "no se encontro '# --- SEDES ---' para insertar el endpoint de fcm-token"
    endpoint_bloque = (
        '@app.post("/usuarios/{usuario_id}/fcm-token")\n'
        'def registrar_fcm_token(usuario_id: UUID, datos: schemas.FcmTokenUpdate, db: Session = Depends(get_db)):\n'
        '    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()\n'
        '    if not usuario:\n'
        '        raise HTTPException(status_code=404, detail="Usuario no encontrado")\n'
        '    usuario.fcm_token = datos.fcm_token\n'
        '    db.commit()\n'
        '    return {"message": "Token registrado"}\n\n'
        + anchor
    )
    main_content = main_content.replace(anchor, endpoint_bloque, 1)
    print("main.py: endpoint POST /usuarios/{id}/fcm-token agregado")
else:
    print("main.py: endpoint de fcm-token ya existia, no se toco")

# 3) cancelar_reserva: mandar push si el usuario tiene token guardado
cancelar_viejo = '''def cancelar_reserva(reserva_id: UUID, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")

    reserva.estado = "cancelada"
    db.commit()
    return {"message": "Reserva cancelada exitosamente"}'''

cancelar_nuevo = '''def cancelar_reserva(reserva_id: UUID, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")

    reserva.estado = "cancelada"
    db.commit()

    # Notificar al usuario por push, si tiene un token FCM registrado.
    # Si el envio falla (token vencido, sin conexion con Firebase, etc.)
    # no debe romper la cancelacion en si -- solo se loguea el error.
    usuario = db.query(models.Usuario).filter(models.Usuario.id == reserva.usuario_id).first()
    if usuario and usuario.fcm_token:
        espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        nombre_cancha = espacio.nombre if espacio else "tu cancha"
        try:
            mensaje = messaging.Message(
                notification=messaging.Notification(
                    title="Reserva cancelada",
                    body=f"Tu reserva en {nombre_cancha} del {reserva.fecha} fue cancelada.",
                ),
                token=usuario.fcm_token,
            )
            messaging.send(mensaje)
        except Exception as e:
            print(f"No se pudo enviar la notificacion push: {e}")

    return {"message": "Reserva cancelada exitosamente"}'''

if cancelar_viejo in main_content:
    main_content = main_content.replace(cancelar_viejo, cancelar_nuevo, 1)
    with open("main.py", "w", encoding="utf-8") as f:
        f.write(main_content)
    print("main.py: push de notificacion agregado a cancelar_reserva")
else:
    if "messaging.send(mensaje)" in main_content:
        print("main.py: cancelar_reserva ya tenia el push agregado, no se toco")
        with open("main.py", "w", encoding="utf-8") as f:
            f.write(main_content)
    else:
        print("ADVERTENCIA: no se encontro cancelar_reserva tal como se esperaba, revisar a mano")
        with open("main.py", "w", encoding="utf-8") as f:
            f.write(main_content)
