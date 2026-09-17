# Agrega el caso de "cancelacion forzada": el endpoint de cancelar reserva
# ahora acepta un query param opcional 'forzada' para distinguir cuando
# la cancela el propio usuario vs. cuando la cancela la administracion
# (ej. se rompio la cancha), y ajusta el texto del push en consecuencia.
# Se corre una sola vez.

with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

viejo = '''@app.delete("/reservas/{reserva_id}")
def cancelar_reserva(reserva_id: UUID, db: Session = Depends(get_db)):
    reserva = db.query(models.Reserva).filter(models.Reserva.id == reserva_id).first()
    if not reserva:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")

    reserva.estado = "cancelada"
    db.commit()

    # Notificar al usuario por push, si tiene un token FCM registrado.
    # Si el envio falla (token vencido, sin conexion con Firebase, etc.)
    # no debe romper la cancelacion en si -- solo se loguea el error.
    usuario = db.query(models.Usuario).filter(models.Usuario.id == reserva.usuario_id).first()
    if usuario and usuario.fcm_token:
        espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        sede = db.query(models.Sede).filter(models.Sede.id == espacio.sede_id).first() if espacio else None
        deporte = espacio.deporte if espacio else "tu cancha"
        nombre_sede = sede.nombre if sede else ""
        cuerpo = f"Se canceló tu reserva de {deporte} en {nombre_sede}." if nombre_sede else f"Se canceló tu reserva de {deporte}."
        try:
            mensaje = messaging.Message(
                notification=messaging.Notification(
                    title="Reserva cancelada",
                    body=cuerpo,
                ),
                token=usuario.fcm_token,
            )
            messaging.send(mensaje)
        except Exception as e:
            print(f"No se pudo enviar la notificacion push: {e}")

    return {"message": "Reserva cancelada exitosamente"}'''

nuevo = '''@app.delete("/reservas/{reserva_id}")
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

    return {"message": "Reserva cancelada exitosamente"}'''

assert viejo in main_content, "no se encontro cancelar_reserva tal como se esperaba"
main_content = main_content.replace(viejo, nuevo, 1)
with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)
print("main.py: parametro 'forzada' agregado a cancelar_reserva")
