# Agrega dos validaciones que pedia la consigna y faltaban:
# 1) La reserva debe ser para un horario futuro (fecha+hora_inicio > ahora).
# 2) La hora de fin no puede superar el horario de cierre de la sede.
# Se aplican tanto en crear_reserva como en modificar_reserva.
# Se corre una sola vez.

with open("main.py", encoding="utf-8") as f:
    content = f.read()

# --- crear_reserva ---
viejo_crear = '''    solapada = db.query(models.Reserva).filter(
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

    monto_total = espacio.precio_por_hora * duracion'''

nuevo_crear = '''    if datetime.combine(reserva.fecha, reserva.hora_inicio) <= datetime.now():
        raise HTTPException(status_code=400, detail="La reserva debe ser para un horario futuro")

    espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
    if not espacio:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    sede = db.query(models.Sede).filter(models.Sede.id == espacio.sede_id).first()
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

    monto_total = espacio.precio_por_hora * duracion'''

assert viejo_crear in content, "no se encontro el bloque de crear_reserva tal como se esperaba"
content = content.replace(viejo_crear, nuevo_crear, 1)

# --- modificar_reserva ---
viejo_modificar = '''    espacio_nuevo = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == nuevo_espacio_id).first()
    if not espacio_nuevo:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    # Si cambia de cancha, solo se permite dentro de la misma sede.
    if datos.espacio_id is not None:
        espacio_actual = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        if espacio_actual and espacio_nuevo.sede_id != espacio_actual.sede_id:
            raise HTTPException(status_code=400, detail="Solo se puede cambiar a otra cancha de la misma sede")

    solapada = db.query(models.Reserva).filter('''

nuevo_modificar = '''    if datetime.combine(nueva_fecha, nueva_hora_inicio) <= datetime.now():
        raise HTTPException(status_code=400, detail="La reserva debe ser para un horario futuro")

    espacio_nuevo = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == nuevo_espacio_id).first()
    if not espacio_nuevo:
        raise HTTPException(status_code=404, detail="El espacio deportivo especificado no existe")

    sede_nueva = db.query(models.Sede).filter(models.Sede.id == espacio_nuevo.sede_id).first()
    if sede_nueva and nueva_hora_fin > sede_nueva.hora_cierre:
        raise HTTPException(status_code=400, detail=f"La reserva no puede finalizar despues del horario de cierre de la sede ({sede_nueva.hora_cierre.strftime('%H:%M')})")

    # Si cambia de cancha, solo se permite dentro de la misma sede.
    if datos.espacio_id is not None:
        espacio_actual = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        if espacio_actual and espacio_nuevo.sede_id != espacio_actual.sede_id:
            raise HTTPException(status_code=400, detail="Solo se puede cambiar a otra cancha de la misma sede")

    solapada = db.query(models.Reserva).filter('''

assert viejo_modificar in content, "no se encontro el bloque de modificar_reserva tal como se esperaba"
content = content.replace(viejo_modificar, nuevo_modificar, 1)

with open("main.py", "w", encoding="utf-8") as f:
    f.write(content)
print("Validaciones de horario futuro y cierre de sede agregadas a crear_reserva y modificar_reserva")
