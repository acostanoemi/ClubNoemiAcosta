from pydantic import BaseModel, EmailStr
from datetime import date, time
from uuid import UUID
from typing import Optional

# --- USUARIOS & AUTH ---
class UsuarioCreate(BaseModel):
    nombre: str
    apellido: str
    dni: str
    fecha_nacimiento: date
    email: EmailStr
    password: str

class UsuarioLogin(BaseModel):
    email: EmailStr
    password: str

class RecoverPassword(BaseModel):
    email: EmailStr
    new_password: str

class UsuarioUpdate(BaseModel):
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    dni: Optional[str] = None
    fecha_nacimiento: Optional[date] = None

class UsuarioResponse(BaseModel):
    id: UUID
    nombre: str
    apellido: str
    dni: str
    fecha_nacimiento: date
    email: EmailStr

    class Config:
        from_attributes = True
class ChangePassword(BaseModel):
    email: EmailStr
    current_password: str
    new_password: str
# --- SEDES ---
class SedeCreate(BaseModel):
    nombre: str
    direccion: str
    hora_apertura: time
    hora_cierre: time
    activa: bool = True

class SedeResponse(BaseModel):
    id: UUID
    nombre: Optional[str] = None
    direccion: str
    hora_apertura: time
    hora_cierre: time
    activa: bool

    class Config:
        from_attributes = True

# --- ESPACIOS DEPORTIVOS ---
class EspacioCreate(BaseModel):
    sede_id: UUID
    nombre: str  # Ej: Moron_Rivadavia_19850_Paddle_1
    deporte: str
    precio_por_hora: float
    subcategoria: Optional[str] = None
    ambiente: Optional[str] = None
    iluminada: bool = False
    hora_apertura: Optional[time] = None
    hora_cierre: Optional[time] = None
    activo: bool = True

class EspacioUpdate(BaseModel):
    nombre: Optional[str] = None
    deporte: Optional[str] = None
    precio_por_hora: Optional[float] = None
    subcategoria: Optional[str] = None
    ambiente: Optional[str] = None
    iluminada: Optional[bool] = None
    hora_apertura: Optional[time] = None
    hora_cierre: Optional[time] = None
    activo: Optional[bool] = None

class EspacioResponse(BaseModel):
    id: UUID
    sede_id: UUID
    nombre: str
    deporte: str
    precio_por_hora: float
    subcategoria: Optional[str] = None
    ambiente: Optional[str] = None
    iluminada: bool = False
    hora_apertura: Optional[time] = None
    hora_cierre: Optional[time] = None
    activo: bool

    class Config:
        from_attributes = True

# --- RESERVAS ---
class ReservaCreate(BaseModel):
    usuario_id: UUID
    espacio_id: UUID
    fecha: date
    hora_inicio: time
    hora_fin: time

class ReservaResponse(BaseModel):
    id: UUID
    usuario_id: UUID
    espacio_id: UUID
    fecha: date
    hora_inicio: time
    hora_fin: time
    monto_total: float
    estado: str

    class Config:
        from_attributes = True
class SedeUpdate(BaseModel):
    nombre: Optional[str] = None

