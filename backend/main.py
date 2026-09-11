from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime, time, timedelta

import models, schemas, database

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
    user_exist = db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first()
    if user_exist:
        raise HTTPException(status_code=400, detail="El correo electrónico ya está registrado")
    
    dni_exist = db.query(models.Usuario).filter(models.Usuario.dni == usuario.dni).first()
    if dni_exist:
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")

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
def obtener_reservas(usuario_id: Optional[UUID] = None, db: Session = Depends(get_db)):
    query = db.query(models.Reserva)
    if usuario_id:
        query = query.filter(models.Reserva.usuario_id == usuario_id)
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

@app.delete("/reservas/{reserva_id}")
def cancelar_reserva(reserva_id: UUID, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")

    reserva.estado = "cancelada"
    db.commit()
    return {"message": "Reserva cancelada exitosamente"}

@app.delete("/espacios/{espacio_id}")
def eliminar_espacio(espacio_id: UUID, db: Session = Depends(get_db)):
    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    db.delete(espacio)
    db.commit()
    return {"message": "Espacio eliminado"}