# Agrega PATCH /reservas/{id}: permite modificar espacio (misma sede),
# fecha y horario de una reserva existente, revalidando disponibilidad
# igual que al crear una reserva nueva.
# Se corre una sola vez.

with open("schemas.py", encoding="utf-8") as f:
    schemas_content = f.read()

if "class ReservaUpdate" not in schemas_content:
    anchor = "class ReservaResponse(BaseModel):"
    assert anchor in schemas_content, "no se encontro ReservaResponse en schemas.py"
    nuevo_schema = (
        "class ReservaUpdate(BaseModel):\n"
        "    espacio_id: Optional[UUID] = None\n"
        "    fecha: Optional[date] = None\n"
        "    hora_inicio: Optional[time] = None\n"
        "    hora_fin: Optional[time] = None\n\n"
        + anchor
    )
    schemas_content = schemas_content.replace(anchor, nuevo_schema, 1)
    with open("schemas.py", "w", encoding="utf-8") as f:
        f.write(schemas_content)
    print("schemas.py: ReservaUpdate agregado")
else:
    print("schemas.py: ReservaUpdate ya existia, no se toco")

with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

if '@app.patch("/reservas/{reserva_id}")' not in main_content:
    anchor = '@app.delete("/reservas/{reserva_id}")'
    assert anchor in main_content, "no se encontro el DELETE de reservas para insertar el PATCH antes"
    patch_bloque = '''@app.patch("/reservas/{reserva_id}", response_model=schemas.ReservaResponse)
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

''' + anchor
    main_content = main_content.replace(anchor, patch_bloque, 1)
    with open("main.py", "w", encoding="utf-8") as f:
        f.write(main_content)
    print("main.py: PATCH /reservas/{id} agregado")
else:
    print("main.py: PATCH de reservas ya existia, no se toco")
