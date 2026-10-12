# Agrega historial persistente de notificaciones: tabla Notificacion,
# endpoints para listar y marcar como leida, y guarda una fila cada vez
# que se manda un push (cancelacion normal, forzada, recordatorio 24hs).
# Se corre una sola vez.

from sqlalchemy import text
import database

# --- models.py: agregar clase Notificacion ---
with open("models.py", encoding="utf-8") as f:
    models_content = f.read()

if "class Notificacion(Base):" not in models_content:
    anchor = "class Reserva(Base):"
    assert anchor in models_content, "no se encontro 'class Reserva(Base):' en models.py"
    nueva_clase = '''class Notificacion(Base):
    __tablename__ = "notificaciones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    titulo = Column(String, nullable=False)
    cuerpo = Column(String, nullable=False)
    leida = Column(Boolean, default=False)
    creada_en = Column(DateTime, default=datetime.utcnow)

''' + anchor
    models_content = models_content.replace(anchor, nueva_clase, 1)
    # Asegurar el import de DateTime y datetime
    if "from sqlalchemy import Column, String, Boolean, Float, Date, Time, ForeignKey" in models_content:
        models_content = models_content.replace(
            "from sqlalchemy import Column, String, Boolean, Float, Date, Time, ForeignKey",
            "from sqlalchemy import Column, String, Boolean, Float, Date, Time, ForeignKey, DateTime"
        )
    if "from datetime import" not in models_content:
        models_content = "from datetime import datetime\n" + models_content
    with open("models.py", "w", encoding="utf-8") as f:
        f.write(models_content)
    print("models.py: clase Notificacion agregada")
else:
    print("models.py: Notificacion ya existia, no se toco")

# --- migracion: crear tabla notificaciones en Postgres ---
with database.engine.connect() as conn:
    conn.execute(text('''
        CREATE TABLE IF NOT EXISTS notificaciones (
            id UUID PRIMARY KEY,
            usuario_id UUID NOT NULL REFERENCES usuarios(id),
            titulo VARCHAR NOT NULL,
            cuerpo VARCHAR NOT NULL,
            leida BOOLEAN DEFAULT FALSE,
            creada_en TIMESTAMP DEFAULT NOW()
        )
    '''))
    conn.commit()
print("Base de datos: tabla 'notificaciones' creada (o ya existia)")

# --- schemas.py: agregar NotificacionResponse ---
with open("schemas.py", encoding="utf-8") as f:
    schemas_content = f.read()

if "class NotificacionResponse" not in schemas_content:
    schemas_content += '''
# --- NOTIFICACIONES ---
class NotificacionResponse(BaseModel):
    id: UUID
    usuario_id: UUID
    titulo: str
    cuerpo: str
    leida: bool
    creada_en: datetime

    class Config:
        from_attributes = True
'''
    if "from datetime import date, time" in schemas_content:
        schemas_content = schemas_content.replace(
            "from datetime import date, time",
            "from datetime import date, time, datetime"
        )
    with open("schemas.py", "w", encoding="utf-8") as f:
        f.write(schemas_content)
    print("schemas.py: NotificacionResponse agregado")
else:
    print("schemas.py: NotificacionResponse ya existia, no se toco")

# --- main.py: funcion helper + endpoints + guardar en cada disparador de push ---
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

# 1) Funcion helper para crear una notificacion en la base
if "def crear_notificacion(" not in main_content:
    anchor = "app = FastAPI(title=\"API Club Noemí Acosta\", version=\"1.0.0\")"
    assert anchor in main_content, "no se encontro la linea de FastAPI() para insertar el helper"
    helper = '''def crear_notificacion(db: Session, usuario_id, titulo: str, cuerpo: str):
    """Guarda una notificacion en el historial persistente del usuario."""
    notif = models.Notificacion(usuario_id=usuario_id, titulo=titulo, cuerpo=cuerpo)
    db.add(notif)
    db.commit()

''' + anchor
    main_content = main_content.replace(anchor, helper, 1)
    print("main.py: helper crear_notificacion agregado")
else:
    print("main.py: helper crear_notificacion ya existia, no se toco")

# 2) Endpoints GET listar y PATCH marcar leida, despues del bloque de fcm-token
if '@app.get("/usuarios/{usuario_id}/notificaciones")' not in main_content:
    anchor = '''@app.post("/usuarios/{usuario_id}/fcm-token")
def registrar_fcm_token(usuario_id: UUID, datos: schemas.FcmTokenUpdate, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario.fcm_token = datos.fcm_token
    db.commit()
    return {"message": "Token registrado"}'''
    assert anchor in main_content, "no se encontro el endpoint de fcm-token tal como se esperaba"
    nuevo_bloque = anchor + '''

@app.get("/usuarios/{usuario_id}/notificaciones", response_model=List[schemas.NotificacionResponse])
def obtener_notificaciones(usuario_id: UUID, db: Session = Depends(get_db)):
    return db.query(models.Notificacion).filter(
        models.Notificacion.usuario_id == usuario_id
    ).order_by(models.Notificacion.creada_en.desc()).all()

@app.patch("/notificaciones/{notificacion_id}")
def marcar_notificacion_leida(notificacion_id: UUID, db: Session = Depends(get_db)):
    notif = db.query(models.Notificacion).filter(models.Notificacion.id == notificacion_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    notif.leida = True
    db.commit()
    return {"message": "Notificación marcada como leída"}'''
    main_content = main_content.replace(anchor, nuevo_bloque, 1)
    print("main.py: endpoints de notificaciones agregados")
else:
    print("main.py: endpoints de notificaciones ya existian, no se tocaron")

with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)

# 3) Guardar notificacion en cancelar_reserva (cubre cancelacion normal Y forzada)
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

viejo_cancelar = '''        try:
            mensaje = messaging.Message(
                notification=messaging.Notification(
                    title=titulo,
                    body=cuerpo,
                ),
                token=usuario.fcm_token,
            )
            messaging.send(mensaje)
        except Exception as e:
            print(f"No se pudo enviar la notificacion push: {e}")

    return {"message": "Reserva cancelada exitosamente"}'''

nuevo_cancelar = '''        try:
            mensaje = messaging.Message(
                notification=messaging.Notification(
                    title=titulo,
                    body=cuerpo,
                ),
                token=usuario.fcm_token,
            )
            messaging.send(mensaje)
        except Exception as e:
            print(f"No se pudo enviar la notificacion push: {e}")
        crear_notificacion(db, usuario.id, titulo, cuerpo)

    return {"message": "Reserva cancelada exitosamente"}'''

if viejo_cancelar in main_content:
    main_content = main_content.replace(viejo_cancelar, nuevo_cancelar, 1)
    print("main.py: cancelar_reserva ahora guarda en el historial")
else:
    print("ADVERTENCIA: no se encontro el bloque final de cancelar_reserva tal como se esperaba, revisar a mano")

# 4) Guardar notificacion en revisar_recordatorios_24hs
viejo_recordatorio = '''                    try:
                        mensaje = messaging.Message(
                            notification=messaging.Notification(
                                title="Recordatorio de reserva",
                                body=cuerpo,
                            ),
                            token=usuario.fcm_token,
                        )
                        messaging.send(mensaje)
                    except Exception as e:
                        print(f"No se pudo enviar el recordatorio: {e}")
                reserva.notificado_24hs = True
                db.commit()'''

nuevo_recordatorio = '''                    try:
                        mensaje = messaging.Message(
                            notification=messaging.Notification(
                                title="Recordatorio de reserva",
                                body=cuerpo,
                            ),
                            token=usuario.fcm_token,
                        )
                        messaging.send(mensaje)
                    except Exception as e:
                        print(f"No se pudo enviar el recordatorio: {e}")
                    crear_notificacion(db, usuario.id, "Recordatorio de reserva", cuerpo)
                reserva.notificado_24hs = True
                db.commit()'''

if viejo_recordatorio in main_content:
    main_content = main_content.replace(viejo_recordatorio, nuevo_recordatorio, 1)
    print("main.py: recordatorio 24hs ahora guarda en el historial")
else:
    print("ADVERTENCIA: no se encontro el bloque de recordatorio tal como se esperaba, revisar a mano")

with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)
