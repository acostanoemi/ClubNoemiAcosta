# Agrega el parametro opcional incluir_canceladas a GET /reservas
# (default False, no cambia el comportamiento de ninguna pantalla
# existente que ya use este endpoint sin ese parametro).
# Se corre una sola vez.

with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

viejo = '''@app.get("/reservas", response_model=List[schemas.ReservaResponse])
def obtener_reservas(usuario_id: Optional[UUID] = None, espacio_id: Optional[UUID] = None, fecha: Optional[date] = None, db: Session = Depends(get_db)):
    query = db.query(models.Reserva)
    if usuario_id:
        query = query.filter(models.Reserva.usuario_id == usuario_id)
    if espacio_id:
        query = query.filter(models.Reserva.espacio_id == espacio_id)
    if fecha:
        query = query.filter(models.Reserva.fecha == fecha)
    query = query.filter(models.Reserva.estado != "cancelada")
    return query.all()'''

nuevo = '''@app.get("/reservas", response_model=List[schemas.ReservaResponse])
def obtener_reservas(usuario_id: Optional[UUID] = None, espacio_id: Optional[UUID] = None, fecha: Optional[date] = None, incluir_canceladas: bool = False, db: Session = Depends(get_db)):
    query = db.query(models.Reserva)
    if usuario_id:
        query = query.filter(models.Reserva.usuario_id == usuario_id)
    if espacio_id:
        query = query.filter(models.Reserva.espacio_id == espacio_id)
    if fecha:
        query = query.filter(models.Reserva.fecha == fecha)
    if not incluir_canceladas:
        query = query.filter(models.Reserva.estado != "cancelada")
    return query.all()'''

assert viejo in main_content, "no se encontro obtener_reservas tal como se esperaba"
main_content = main_content.replace(viejo, nuevo, 1)
with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)
print("main.py: parametro incluir_canceladas agregado a GET /reservas")
