# Agrega recordatorio automatico 24hs antes de una reserva: columna
# notificado_24hs en Reserva, migracion de la tabla, y un scheduler
# (APScheduler) que corre cada 1 hora buscando reservas confirmadas
# que arrancan dentro de las proximas 24hs y todavia no fueron avisadas.
# Se corre una sola vez.

from sqlalchemy import text
import database

# --- models.py: agregar campo notificado_24hs a Reserva ---
with open("models.py", encoding="utf-8") as f:
    models_content = f.read()

if "notificado_24hs = Column(Boolean, default=False)" not in models_content:
    anchor = (
        '    estado = Column(String, default="confirmada")  # confirmada / cancelada\n\n'
        '    usuario = relationship("Usuario", back_populates="reservas")'
    )
    assert anchor in models_content, "no se encontro el bloque esperado en el modelo Reserva"
    nuevo = (
        '    estado = Column(String, default="confirmada")  # confirmada / cancelada\n'
        '    notificado_24hs = Column(Boolean, default=False)\n\n'
        '    usuario = relationship("Usuario", back_populates="reservas")'
    )
    models_content = models_content.replace(anchor, nuevo, 1)
    with open("models.py", "w", encoding="utf-8") as f:
        f.write(models_content)
    print("models.py: campo 'notificado_24hs' agregado a Reserva")
else:
    print("models.py: 'notificado_24hs' ya estaba en Reserva, no se toco")

# --- migracion de la tabla en Postgres (ALTER TABLE) ---
with database.engine.connect() as conn:
    conn.execute(text("ALTER TABLE reservas ADD COLUMN IF NOT EXISTS notificado_24hs BOOLEAN DEFAULT FALSE"))
    conn.commit()
print("Base de datos: columna 'notificado_24hs' migrada en reservas")

# --- main.py: import de APScheduler, job de recordatorio, arranque del scheduler ---
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

if "BackgroundScheduler" not in main_content:
    anchor = (
        'if not firebase_admin._apps:\n'
        '    cred = credentials.Certificate("firebase-credentials.json")\n'
        '    firebase_admin.initialize_app(cred)\n\n'
        'app = FastAPI(title="API Club Noemí Acosta", version="1.0.0")'
    )
    assert anchor in main_content, "no se encontro el bloque de inicializacion de Firebase en main.py"
    nuevo_bloque = '''if not firebase_admin._apps:
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
                reserva.notificado_24hs = True
                db.commit()
    finally:
        db.close()

scheduler = BackgroundScheduler()
scheduler.add_job(revisar_recordatorios_24hs, "interval", hours=1)
scheduler.start()

app = FastAPI(title="API Club Noemí Acosta", version="1.0.0")'''
    main_content = main_content.replace(anchor, nuevo_bloque, 1)
    with open("main.py", "w", encoding="utf-8") as f:
        f.write(main_content)
    print("main.py: scheduler de recordatorio 24hs agregado")
else:
    print("main.py: scheduler ya estaba agregado, no se toco")
