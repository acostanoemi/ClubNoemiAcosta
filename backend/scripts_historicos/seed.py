import uuid
from datetime import time
from database import SessionLocal, engine, Base
import models

# Recrear tablas
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    print("🧹 Limpiando y creando tablas...")

    # 1. Crear Sedes de prueba
    sedes_data = [
        {"nombre": "Moron", "direccion": "Rivadavia 19850", "hora_apertura": time(8, 0), "hora_cierre": time(23, 0)},
        {"nombre": "Castelar", "direccion": "Arias 2340", "hora_apertura": time(9, 0), "hora_cierre": time(22, 0)},
        {"nombre": "Ramos Mejia", "direccion": "Avenida de Mayo 1120", "hora_apertura": time(8, 0), "hora_cierre": time(23, 0)},
        {"nombre": "Haedo", "direccion": "Gaona 3500", "hora_apertura": time(9, 0), "hora_cierre": time(21, 0)},
    ]

    sedes_creadas = []
    for s in sedes_data:
        nueva_sede = models.Sede(
            id=uuid.uuid4(),
            nombre=s["nombre"],
            direccion=s["direccion"],
            hora_apertura=s["hora_apertura"],
            hora_cierre=s["hora_cierre"],
            activa=True
        )
        db.add(nueva_sede)
        sedes_creadas.append(nueva_sede)
    
    db.commit()

    # 2. Crear Espacios Deportivos con nomenclatura compuesta
    # Formato: Sede_Direccion_Deporte_Numero
    deportes = [("Paddle", 8000.0), ("Futbol 5", 15000.0), ("Tenis", 10000.0)]

    for sede in sedes_creadas:
        dir_clean = sede.direccion.replace(" ", "_")
        sede_clean = sede.nombre.replace(" ", "_")

        for deporte, precio in deportes:
            for i in range(1, 3):  # 2 canchas por deporte por sede
                nombre_compuesto = f"{sede_clean}_{dir_clean}_{deporte}_{i}"
                
                nuevo_espacio = models.EspacioDeportivo(
                    id=uuid.uuid4(),
                    sede_id=sede.id,
                    nombre=nombre_compuesto,
                    deporte=deporte,
                    precio_por_hora=precio,
                    activo=True
                )
                db.add(nuevo_espacio)

    db.commit()
    print("✅ Base de datos poblada exitosamente con el formato de nombres compuestos.")

except Exception as e:
    print(f"❌ Error al poblar la base de datos: {e}")
    db.rollback()
finally:
    db.close()