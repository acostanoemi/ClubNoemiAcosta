from datetime import datetime
import uuid
from sqlalchemy import Column, String, Boolean, Float, Date, Time, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from database import Base

class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nombre = Column(String, nullable=False)
    apellido = Column(String, nullable=False)
    dni = Column(String, unique=True, nullable=False)
    fecha_nacimiento = Column(Date, nullable=False)
    email = Column(String, unique=True, nullable=False)
    firebase_uid = Column(String, unique=True, nullable=True)
    activo = Column(Boolean, default=True)
    fcm_token = Column(String, nullable=True)

    reservas = relationship("Reserva", back_populates="usuario")

class Sede(Base):
    __tablename__ = "sedes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nombre = Column(String, nullable=False)
    direccion = Column(String, nullable=False)
    hora_apertura = Column(Time, nullable=False)
    hora_cierre = Column(Time, nullable=False)
    activa = Column(Boolean, default=True)

    espacios = relationship("EspacioDeportivo", back_populates="sede")

class EspacioDeportivo(Base):
    __tablename__ = "espacios_deportivos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sede_id = Column(UUID(as_uuid=True), ForeignKey("sedes.id"), nullable=False)
    nombre = Column(String, nullable=False)  # Formato: Sede_Direccion_Deporte_Numero
    deporte = Column(String, nullable=False)
    precio_por_hora = Column(Float, nullable=False)
    subcategoria = Column(String, nullable=True)  # Ej: Polvo de Ladrillo, Cemento, Indoor Parquet
    ambiente = Column(String, nullable=True)  # Outdoor / Indoor
    iluminada = Column(Boolean, default=False)
    hora_apertura = Column(Time, nullable=True)
    hora_cierre = Column(Time, nullable=True)
    activo = Column(Boolean, default=True)

    sede = relationship("Sede", back_populates="espacios")
    reservas = relationship("Reserva", back_populates="espacio")

class Notificacion(Base):
    __tablename__ = "notificaciones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    titulo = Column(String, nullable=False)
    cuerpo = Column(String, nullable=False)
    leida = Column(Boolean, default=False)
    creada_en = Column(DateTime, default=datetime.utcnow)

class Reserva(Base):
    __tablename__ = "reservas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    espacio_id = Column(UUID(as_uuid=True), ForeignKey("espacios_deportivos.id"), nullable=False)
    fecha = Column(Date, nullable=False)
    hora_inicio = Column(Time, nullable=False)
    hora_fin = Column(Time, nullable=False)
    monto_total = Column(Float, nullable=False)
    estado = Column(String, default="confirmada")  # confirmada / cancelada
    notificado_24hs = Column(Boolean, default=False)

    usuario = relationship("Usuario", back_populates="reservas")
    espacio = relationship("EspacioDeportivo", back_populates="reservas")