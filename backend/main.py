from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime, time, timedelta, date

import models, schemas, database

import firebase_admin
from firebase_admin import credentials, messaging

if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-credentials.json")
    firebase_admin.initialize_app(cred)

from apscheduler.schedulers.background import BackgroundScheduler

def revisar_recordatorios_24hs():
    """Busca reservas confirmadas que arrancan dentro de las proximas 24hs
    y que todavia no fueron notificadas, y les manda un push recordatorio."""
    db = database.SessionLocal()
    try:
        ahora = datetime.now()
        limite = ahora + timedelta(hours=24)
        reservas = db.query(models.Reserva).filter(
            models.Reserva.estado == "confirmada",
            models.Reserva.notificado_24hs == False
        ).all()
        for reserva in reservas:
            momento_reserva = datetime.combine(reserva.fecha, reserva.hora_inicio)
            if ahora <= momento_reserva <= limite:
                usuario = db.query(models.Usuario).filter(models.Usuario.id == reserva.usuario_id).first()
                if usuario and usuario.fcm_token:
                    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
                    sede = db.query(models.Sede).filter(models.Sede.id == espacio.sede_id).first() if espacio else None
                    deporte = espacio.deporte if espacio else "tu cancha"
                    nombre_sede = sede.nombre if sede else ""
                    lugar = f" en {nombre_sede}" if nombre_sede else ""
                    hora = reserva.hora_inicio.strftime("%H:%M")
                    cuerpo = f"Tenés una reserva de {deporte}{lugar} mañana a las {hora}."
                    try:
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
                db.commit()
    finally:
        db.close()

scheduler = BackgroundScheduler()
scheduler.add_job(revisar_recordatorios_24hs, "interval", hours=1)
scheduler.start()

def crear_notificacion(db: Session, usuario_id, titulo: str, cuerpo: str):
    """Guarda una notificacion en el historial persistente del usuario."""
    notif = models.Notificacion(usuario_id=usuario_id, titulo=titulo, cuerpo=cuerpo)
    db.add(notif)
    db.commit()

app = FastAPI(title="API Club Noemí Acosta", version="1.0.0")

# Permitir peticiones desde el Frontend en Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependencia para obtener sesión de DB
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- AUTENTICACIÓN ---

@app.post("/auth/register", response_model=schemas.UsuarioResponse, status_code=status.HTTP_201_CREATED)
def registrar_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    user_email = db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first()
    user_dni = db.query(models.Usuario).filter(models.Usuario.dni == usuario.dni).first()

    # Si el email o el DNI ya pertenecen a una cuenta activa, no se puede registrar.
    if user_email and user_email.activo:
        raise HTTPException(status_code=400, detail="El correo electrónico ya está registrado")
    if user_dni and user_dni.activo:
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")

    # Si coincide con una cuenta dada de baja (mismo email o DNI), se reactiva
    # en vez de crear una fila nueva -- evita choques de unicidad y conserva
    # el historial de reservas de esa cuenta.
    cuenta_inactiva = user_email or user_dni
    if cuenta_inactiva and not cuenta_inactiva.activo:
        cuenta_inactiva.nombre = usuario.nombre
        cuenta_inactiva.apellido = usuario.apellido
        cuenta_inactiva.dni = usuario.dni
        cuenta_inactiva.fecha_nacimiento = usuario.fecha_nacimiento
        cuenta_inactiva.email = usuario.email
        cuenta_inactiva.password = usuario.password
        cuenta_inactiva.activo = True
        db.commit()
        db.refresh(cuenta_inactiva)
        return cuenta_inactiva

    nuevo_usuario = models.Usuario(**usuario.model_dump())
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario

@app.post("/auth/login")
def login(credenciales: schemas.UsuarioLogin, db: Session = Depends(get_db)):
    # Limpiamos espacios en blanco accidentales de ambos lados
    email_clean = credenciales.email.strip().lower()
    pass_clean = credenciales.password.strip()

    # Buscamos el usuario comparando emails en minúscula
    user = db.query(models.Usuario).filter(models.Usuario.email.ilike(email_clean)).first()
    
    if not user:
        raise HTTPException(status_code=401, detail="El correo electrónico no existe")

    if not user.activo:
        raise HTTPException(status_code=403, detail="Esta cuenta fue dada de baja")

    if user.password.strip() != pass_clean:
        raise HTTPException(status_code=401, detail="Contraseña incorrecta")
    
    return {
        "message": "Login exitoso",
        "id": str(user.id),
        "email": user.email,
        "nombre": user.nombre,
        "apellido": user.apellido
    }

@app.post("/auth/recover-password")
def recover_password(data: schemas.RecoverPassword, db: Session = Depends(get_db)):
    user = db.query(models.Usuario).filter(models.Usuario.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.password = data.new_password
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}

@app.put("/auth/change-password")
def change_password(data: schemas.ChangePassword, db: Session = Depends(get_db)):
    user = db.query(models.Usuario).filter(models.Usuario.email.ilike(data.email.strip().lower())).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if user.password.strip() != data.current_password.strip():
        raise HTTPException(status_code=401, detail="La contraseña actual no es correcta")

    user.password = data.new_password
    db.commit()
    return {"message": "Contraseña actualizada exitosamente"}

# --- USUARIOS ---

@app.get("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
def obtener_usuario(usuario_id: UUID, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return usuario

@app.patch("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
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
    return usuario

@app.delete("/usuarios/{usuario_id}")
def dar_de_baja_usuario(usuario_id: UUID, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario.activo = False
    db.commit()
    return {"message": "Cuenta dada de baja"}

@app.post("/usuarios/{usuario_id}/fcm-token")
def registrar_fcm_token(usuario_id: UUID, datos: schemas.FcmTokenUpdate, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario.fcm_token = datos.fcm_token
    db.commit()
    return {"message": "Token registrado"}

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
    return {"message": "Notificación marcada como leída"}

# --- SEDES ---

@app.get("/sedes", response_model=List[schemas.SedeResponse])
def obtener_sedes(db: Session = Depends(get_db)):
    return db.query(models.Sede).filter(models.Sede.activa == True).all()

@app.post("/sedes", response_model=schemas.SedeResponse, status_code=status.HTTP_201_CREATED)
def crear_sede(sede: schemas.SedeCreate, db: Session = Depends(get_db)):
    nueva_sede = models.Sede(**sede.model_dump())
    db.add(nueva_sede)
    db.commit()
    db.refresh(nueva_sede)
    return nueva_sede

@app.patch("/sedes/{sede_id}")
def actualizar_sede(sede_id: UUID, datos: schemas.SedeUpdate, db: Session = Depends(get_db)):
    sede = db.query(models.Sede).filter(models.Sede.id == sede_id).first()
    if not sede:
        raise HTTPException(status_code=404, detail="Sede no encontrada")
    if datos.nombre is not None:
        sede.nombre = datos.nombre
    db.commit()
    return {"message": "Sede actualizada"}

# --- ESPACIOS DEPORTIVOS ---

@app.get("/espacios", response_model=List[schemas.EspacioResponse])
def obtener_espacios(sede_id: Optional[UUID] = None, deporte: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.activo == True)
    if sede_id:
        query = query.filter(models.EspacioDeportivo.sede_id == sede_id)
    if deporte:
        query = query.filter(models.EspacioDeportivo.deporte.ilike(f"%{deporte}%"))
    return query.all()

@app.post("/espacios", response_model=schemas.EspacioResponse, status_code=status.HTTP_201_CREATED)
def crear_espacio(espacio: schemas.EspacioCreate, db: Session = Depends(get_db)):
    nuevo_espacio = models.EspacioDeportivo(**espacio.model_dump())
    db.add(nuevo_espacio)
    db.commit()
    db.refresh(nuevo_espacio)
    return nuevo_espacio

# --- RESERVAS ---

@app.get("/reservas", response_model=List[schemas.ReservaResponse])
def obtener_reservas(usuario_id: Optional[UUID] = None, espacio_id: Optional[UUID] = None, fecha: Optional[date] = None, db: Session = Depends(get_db)):
    query = db.query(models.Reserva)
    if usuario_id:
        query = query.filter(models.Reserva.usuario_id == usuario_id)
    if espacio_id:
        query = query.filter(models.Reserva.espacio_id == espacio_id)
    if fecha:
        query = query.filter(models.Reserva.fecha == fecha)
    query = query.filter(models.Reserva.estado != "cancelada")
    return query.all()

@app.post("/reservas", response_model=schemas.ReservaResponse, status_code=status.HTTP_201_CREATED)
def crear_reserva(reserva: schemas.ReservaCreate, db: Session = Depends(get_db)):
    if reserva.hora_inicio.minute != 0 or reserva.hora_fin.minute != 0:
        raise HTTPException(status_code=400, detail="Las reservas deben hacerse en horarios en punto (minuto 00)")

    duracion = (datetime.combine(datetime.min, reserva.hora_fin) - datetime.combine(datetime.min, reserva.hora_inicio)).total_seconds() / 3600
    if duracion < 1:
        raise HTTPException(status_code=400, detail="La reserva debe durar como mínimo 1 hora")

    solapada = db.query(models.Reserva).filter(
        models.Reserva.espacio_id == reserva.espacio_id,
        models.Reserva.fecha == reserva.fecha,
        models.Reserva.estado == "confirmada",
        models.Reserva.hora_inicio < reserva.hora_fin,
        models.Reserva.hora_fin > reserva.hora_inicio
    ).first()

    if solapada:
        raise HTTPException(status_code=409, detail="El espacio deportivo no está disponible en ese horario")

    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    monto_total = espacio.precio_por_hora * duracion

    nueva_reserva = models.Reserva(
        usuario_id=reserva.usuario_id,
        espacio_id=reserva.espacio_id,
        fecha=reserva.fecha,
        hora_inicio=reserva.hora_inicio,
        hora_fin=reserva.hora_fin,
        monto_total=monto_total,
        estado="confirmada"
    )

    db.add(nueva_reserva)
    db.commit()
    db.refresh(nueva_reserva)
    return nueva_reserva

@app.patch("/reservas/{reserva_id}", response_model=schemas.ReservaResponse)
def modificar_reserva(reserva_id: UUID, datos: schemas.ReservaUpdate, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reserva.estado == "cancelada":
        raise HTTPException(status_code=400, detail="No se puede modificar una reserva cancelada")

    nuevo_espacio_id = datos.espacio_id if datos.espacio_id is not None else reserva.espacio_id
    nueva_fecha = datos.fecha if datos.fecha is not None else reserva.fecha
    nueva_hora_inicio = datos.hora_inicio if datos.hora_inicio is not None else reserva.hora_inicio
    nueva_hora_fin = datos.hora_fin if datos.hora_fin is not None else reserva.hora_fin

    if nueva_hora_inicio.minute != 0 or nueva_hora_fin.minute != 0:
        raise HTTPException(status_code=400, detail="Las reservas deben hacerse en horarios en punto (minuto 00)")

    duracion = (datetime.combine(datetime.min, nueva_hora_fin) - datetime.combine(datetime.min, nueva_hora_inicio)).total_seconds() / 3600
    if duracion < 1:
        raise HTTPException(status_code=400, detail="La reserva debe durar como minimo 1 hora")

    espacio_nuevo = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == nuevo_espacio_id).first()
    if not espacio_nuevo:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    # Si cambia de cancha, solo se permite dentro de la misma sede.
    if datos.espacio_id is not None:
        espacio_actual = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        if espacio_actual and espacio_nuevo.sede_id != espacio_actual.sede_id:
            raise HTTPException(status_code=400, detail="Solo se puede cambiar a otra cancha de la misma sede")

    solapada = db.query(models.Reserva).filter(
        models.Reserva.id != reserva_id,
        models.Reserva.espacio_id == nuevo_espacio_id,
        models.Reserva.fecha == nueva_fecha,
        models.Reserva.estado == "confirmada",
        models.Reserva.hora_inicio < nueva_hora_fin,
        models.Reserva.hora_fin > nueva_hora_inicio
    ).first()

    if solapada:
        raise HTTPException(status_code=409, detail="El espacio deportivo no esta disponible en ese horario")

    reserva.espacio_id = nuevo_espacio_id
    reserva.fecha = nueva_fecha
    reserva.hora_inicio = nueva_hora_inicio
    reserva.hora_fin = nueva_hora_fin
    reserva.monto_total = espacio_nuevo.precio_por_hora * duracion

    db.commit()
    db.refresh(reserva)
    return reserva

@app.delete("/reservas/{reserva_id}")
def cancelar_reserva(reserva_id: UUID, forzada: bool = False, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")

    reserva.estado = "cancelada"
    db.commit()

    # Notificar al usuario por push, si tiene un token FCM registrado.
    # Si el envio falla (token vencido, sin conexion con Firebase, etc.)
    # no debe romper la cancelacion en si -- solo se loguea el error.
    # 'forzada' distingue si cancelo el propio usuario o la administracion.
    usuario = db.query(models.Usuario).filter(models.Usuario.id == reserva.usuario_id).first()
    if usuario and usuario.fcm_token:
        espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        sede = db.query(models.Sede).filter(models.Sede.id == espacio.sede_id).first() if espacio else None
        deporte = espacio.deporte if espacio else "tu cancha"
        nombre_sede = sede.nombre if sede else ""
        lugar = f" en {nombre_sede}" if nombre_sede else ""
        if forzada:
            titulo = "Reserva cancelada por administración"
            cuerpo = f"Tu reserva de {deporte}{lugar} fue cancelada por la administración."
        else:
            titulo = "Reserva cancelada"
            cuerpo = f"Se canceló tu reserva de {deporte}{lugar}."
        try:
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

    return {"message": "Reserva cancelada exitosamente"}

@app.delete("/espacios/{espacio_id}")
def eliminar_espacio(espacio_id: UUID, db: Session = Depends(get_db)):
    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    db.delete(espacio)
    db.commit()
    return {"message": "Espacio eliminado"}
@app.patch("/espacios/{espacio_id}")
def actualizar_espacio(espacio_id: UUID, datos: schemas.EspacioUpdate, db: Session = Depends(get_db)):
    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(espacio, campo, valor)
    db.commit()
    return {"message": "Espacio actualizado"}
