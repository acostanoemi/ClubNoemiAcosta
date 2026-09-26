import os
from fastapi import FastAPI, HTTPException, Depends, status, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime, time, timedelta, date

import models, schemas, database

import firebase_admin
from firebase_admin import credentials, messaging, auth as firebase_auth

if not firebase_admin._apps:
    ruta_credenciales = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
    cred = credentials.Certificate(ruta_credenciales)
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

@app.get("/")
def estado():
    """No consulta la base a proposito: la usa el workflow de GitHub
    Actions (.github/workflows/keep-alive.yml) para pinguear el
    servicio cada 10 minutos y que Render no lo duerma por
    inactividad. Si durmiera, el scheduler de recordatorios de
    reserva se corta con el, y se pierden avisos."""
    return {"status": "ok"}

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

def _extraer_bearer(authorization: Optional[str]) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No autenticado")
    return authorization[len("Bearer "):].strip()

def obtener_claims_firebase(authorization: str = Header(None)) -> dict:
    """Verifica un ID token de Firebase y devuelve sus datos (uid, email).
    No busca el usuario en la base: se usa solo en /auth/perfil, que es
    justamente donde el usuario todavia no tiene fila en 'usuarios'."""
    token = _extraer_bearer(authorization)
    try:
        return firebase_auth.verify_id_token(token)
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="La sesion expiro, iniciá sesion de nuevo")
    except Exception:
        raise HTTPException(status_code=401, detail="Token invalido")

def obtener_usuario_actual(authorization: str = Header(None), db: Session = Depends(get_db)) -> models.Usuario:
    """Dependencia que exige un ID token de Firebase valido en el header
    Authorization (formato 'Bearer <token>') y devuelve el usuario del club
    atado a ese uid. Se usa en todos los endpoints que operan sobre
    usuarios o reservas."""
    claims = obtener_claims_firebase(authorization)
    usuario = db.query(models.Usuario).filter(models.Usuario.firebase_uid == claims["uid"]).first()
    if not usuario or not usuario.activo:
        raise HTTPException(status_code=401, detail="Usuario no encontrado o inactivo")
    return usuario

import secrets

def requiere_admin(x_admin_key: str = Header(None)):
    """Protege los endpoints que modifican sedes y espacios. La app no los
    usa: se cargan datos a mano (curl, scripts), mandando el header
    X-Admin-Key con el valor de ADMIN_API_KEY. Si la variable no esta
    configurada, se rechaza todo."""
    esperada = os.getenv("ADMIN_API_KEY")
    if not esperada or not x_admin_key or not secrets.compare_digest(x_admin_key, esperada):
        raise HTTPException(status_code=403, detail="No autorizado")

# --- AUTENTICACIÓN ---

@app.post("/auth/perfil", response_model=schemas.UsuarioResponse, status_code=status.HTTP_201_CREATED)
def completar_perfil(datos: schemas.PerfilCreate, claims: dict = Depends(obtener_claims_firebase), db: Session = Depends(get_db)):
    """Registro con Firebase: la cuenta (email + contraseña) ya la creo
    Firebase desde la app. Aca solo se guardan los datos del club
    (nombre, apellido, DNI, fecha de nacimiento) atados a ese uid.
    El email sale del token verificado, no del body."""
    uid = claims["uid"]
    email = (claims.get("email") or "").strip().lower()
    if not email:
        raise HTTPException(status_code=400, detail="La cuenta de Firebase no tiene email")

    por_uid = db.query(models.Usuario).filter(models.Usuario.firebase_uid == uid).first()
    if por_uid and por_uid.activo:
        raise HTTPException(status_code=400, detail="El perfil ya existe")

    por_email = db.query(models.Usuario).filter(models.Usuario.email.ilike(email)).first()
    por_dni = db.query(models.Usuario).filter(models.Usuario.dni == datos.dni).first()

    if por_email and por_email.activo and por_email.firebase_uid != uid:
        raise HTTPException(status_code=400, detail="El correo electrónico ya está registrado")
    if por_dni and por_dni.activo and por_dni.firebase_uid != uid:
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")

    # Igual que en el registro viejo: si coincide con una cuenta dada de
    # baja, se reactiva esa fila y se conserva su historial de reservas.
    cuenta = por_uid or por_email or por_dni
    if cuenta and por_dni and por_dni.id != cuenta.id:
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")

    if cuenta:
        cuenta.nombre = datos.nombre
        cuenta.apellido = datos.apellido
        cuenta.dni = datos.dni
        cuenta.fecha_nacimiento = datos.fecha_nacimiento
        cuenta.email = email
        cuenta.firebase_uid = uid
        cuenta.activo = True
    else:
        cuenta = models.Usuario(**datos.model_dump(), email=email, firebase_uid=uid)
        db.add(cuenta)

    db.commit()
    db.refresh(cuenta)
    return cuenta

@app.get("/auth/me", response_model=schemas.UsuarioResponse)
def usuario_logueado(usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    """Devuelve los datos del usuario dueño del token. La app lo llama
    justo despues de loguearse con Firebase, para saber su id y nombre."""
    return usuario_actual

# --- USUARIOS ---

@app.get("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
def obtener_usuario(usuario_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    return usuario_actual

@app.patch("/usuarios/{usuario_id}", response_model=schemas.UsuarioResponse)
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
    return usuario_actual

@app.delete("/usuarios/{usuario_id}")
def dar_de_baja_usuario(usuario_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    usuario_actual.activo = False
    # Se borra la cuenta de Firebase para que el email quede libre: si la
    # persona se vuelve a registrar, Firebase le crea una cuenta nueva y
    # /auth/perfil reactiva esta misma fila (con su historial).
    if usuario_actual.firebase_uid:
        try:
            firebase_auth.delete_user(usuario_actual.firebase_uid)
        except firebase_auth.UserNotFoundError:
            pass
        usuario_actual.firebase_uid = None
    db.commit()
    return {"message": "Cuenta dada de baja"}

@app.post("/usuarios/{usuario_id}/fcm-token")
def registrar_fcm_token(usuario_id: UUID, datos: schemas.FcmTokenUpdate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    usuario_actual.fcm_token = datos.fcm_token
    db.commit()
    return {"message": "Token registrado"}

@app.get("/usuarios/{usuario_id}/notificaciones", response_model=List[schemas.NotificacionResponse])
def obtener_notificaciones(usuario_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_actual.id != usuario_id:
        raise HTTPException(status_code=403, detail="No autorizado")
    return db.query(models.Notificacion).filter(
        models.Notificacion.usuario_id == usuario_id
    ).order_by(models.Notificacion.creada_en.desc()).all()

@app.patch("/notificaciones/{notificacion_id}")
def marcar_notificacion_leida(notificacion_id: UUID, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    notif = db.query(models.Notificacion).filter(models.Notificacion.id == notificacion_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    if notif.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")
    notif.leida = True
    db.commit()
    return {"message": "Notificación marcada como leída"}

# --- SEDES ---

@app.get("/sedes", response_model=List[schemas.SedeResponse])
def obtener_sedes(db: Session = Depends(get_db)):
    return db.query(models.Sede).filter(models.Sede.activa == True).all()

@app.post("/sedes", response_model=schemas.SedeResponse, status_code=status.HTTP_201_CREATED)
def crear_sede(sede: schemas.SedeCreate, db: Session = Depends(get_db), _: None = Depends(requiere_admin)):
    nueva_sede = models.Sede(**sede.model_dump())
    db.add(nueva_sede)
    db.commit()
    db.refresh(nueva_sede)
    return nueva_sede

@app.patch("/sedes/{sede_id}")
def actualizar_sede(sede_id: UUID, datos: schemas.SedeUpdate, db: Session = Depends(get_db), _: None = Depends(requiere_admin)):
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
def crear_espacio(espacio: schemas.EspacioCreate, db: Session = Depends(get_db), _: None = Depends(requiere_admin)):
    nuevo_espacio = models.EspacioDeportivo(**espacio.model_dump())
    db.add(nuevo_espacio)
    db.commit()
    db.refresh(nuevo_espacio)
    return nuevo_espacio

# --- RESERVAS ---

@app.get("/reservas", response_model=List[schemas.ReservaResponse])
def obtener_reservas(usuario_id: Optional[UUID] = None, espacio_id: Optional[UUID] = None, fecha: Optional[date] = None, incluir_canceladas: bool = False, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if usuario_id is not None and usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")
    query = db.query(models.Reserva)
    if usuario_id:
        query = query.filter(models.Reserva.usuario_id == usuario_id)
    if espacio_id:
        query = query.filter(models.Reserva.espacio_id == espacio_id)
    if fecha:
        query = query.filter(models.Reserva.fecha == fecha)
    if not incluir_canceladas:
        query = query.filter(models.Reserva.estado != "cancelada")
    return query.all()

@app.post("/reservas", response_model=schemas.ReservaResponse, status_code=status.HTTP_201_CREATED)
def crear_reserva(reserva: schemas.ReservaCreate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    if reserva.hora_inicio.minute != 0 or reserva.hora_fin.minute != 0:
        raise HTTPException(status_code=400, detail="Las reservas deben hacerse en horarios en punto (minuto 00)")

    duracion = (datetime.combine(datetime.min, reserva.hora_fin) - datetime.combine(datetime.min, reserva.hora_inicio)).total_seconds() / 3600
    if duracion < 1:
        raise HTTPException(status_code=400, detail="La reserva debe durar como mínimo 1 hora")

    if datetime.combine(reserva.fecha, reserva.hora_inicio) < datetime.now() + timedelta(hours=2):
        raise HTTPException(status_code=400, detail="La reserva debe hacerse con al menos 2 horas de anticipacion")

    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    sede = db.query(models.Sede).filter(models.Sede.id == espacio.sede_id).first()
    if sede and reserva.hora_inicio < sede.hora_apertura:
        raise HTTPException(status_code=400, detail=f"La reserva no puede empezar antes del horario de apertura de la sede ({sede.hora_apertura.strftime('%H:%M')})")

    if sede and reserva.hora_fin > sede.hora_cierre:
        raise HTTPException(status_code=400, detail=f"La reserva no puede finalizar despues del horario de cierre de la sede ({sede.hora_cierre.strftime('%H:%M')})")

    solapada = db.query(models.Reserva).filter(
        models.Reserva.espacio_id == reserva.espacio_id,
        models.Reserva.fecha == reserva.fecha,
        models.Reserva.estado == "confirmada",
        models.Reserva.hora_inicio < reserva.hora_fin,
        models.Reserva.hora_fin > reserva.hora_inicio
    ).first()

    if solapada:
        raise HTTPException(status_code=409, detail="El espacio deportivo no está disponible en ese horario")

    monto_total = espacio.precio_por_hora * duracion

    nueva_reserva = models.Reserva(
        usuario_id=usuario_actual.id,
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
def modificar_reserva(reserva_id: UUID, datos: schemas.ReservaUpdate, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reserva.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")
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

    if datetime.combine(nueva_fecha, nueva_hora_inicio) < datetime.now() + timedelta(hours=2):
        raise HTTPException(status_code=400, detail="La reserva debe hacerse con al menos 2 horas de anticipacion")

    espacio_nuevo = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == nuevo_espacio_id).first()
    if not espacio_nuevo:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    sede_nueva = db.query(models.Sede).filter(models.Sede.id == espacio_nuevo.sede_id).first()
    if sede_nueva and nueva_hora_inicio < sede_nueva.hora_apertura:
        raise HTTPException(status_code=400, detail=f"La reserva no puede empezar antes del horario de apertura de la sede ({sede_nueva.hora_apertura.strftime('%H:%M')})")

    if sede_nueva and nueva_hora_fin > sede_nueva.hora_cierre:
        raise HTTPException(status_code=400, detail=f"La reserva no puede finalizar despues del horario de cierre de la sede ({sede_nueva.hora_cierre.strftime('%H:%M')})")

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
def cancelar_reserva(reserva_id: UUID, forzada: bool = False, usuario_actual: models.Usuario = Depends(obtener_usuario_actual), db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reserva.usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No autorizado")

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
def eliminar_espacio(espacio_id: UUID, db: Session = Depends(get_db), _: None = Depends(requiere_admin)):
    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    db.delete(espacio)
    db.commit()
    return {"message": "Espacio eliminado"}
@app.patch("/espacios/{espacio_id}")
def actualizar_espacio(espacio_id: UUID, datos: schemas.EspacioUpdate, db: Session = Depends(get_db), _: None = Depends(requiere_admin)):
    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(espacio, campo, valor)
    db.commit()
    return {"message": "Espacio actualizado"}
