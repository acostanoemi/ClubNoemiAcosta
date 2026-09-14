# Mejora el texto de la notificacion push al cancelar una reserva:
# usa deporte + nombre de sede en vez del slug tecnico del espacio.
# Se corre una sola vez.

with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

viejo = '''    usuario = db.query(models.Usuario).filter(models.Usuario.id == reserva.usuario_id).first()
    if usuario and usuario.fcm_token:
        espacio = db.query(models.EspacioDeportivo).filter(models.EspacioDeportivo.id == reserva.espacio_id).first()
        nombre_cancha = espacio.nombre if espacio else "tu cancha"
        try:
            mensaje = messaging.Message(
                notification=messaging.Notification(
                    title="Reserva cancelada",
                    body=f"Tu reserva en {nombre_cancha} del {reserva.fecha} fue cancelada.",
                ),
                token=usuario.fcm_token,
            )
            messaging.send(mensaje)
        except Exception as e:
            print(f"No se pudo enviar la notificacion push: {e}")'''

nuevo = '''    usuario = db.query(models.Usuario).filter(models.Usuario.id == reserva.usuario_id).first()
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
            print(f"No se pudo enviar la notificacion push: {e}")'''

assert viejo in main_content, "no se encontro el bloque de notificacion tal como se esperaba"
main_content = main_content.replace(viejo, nuevo, 1)
with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)
print("main.py: mensaje de notificacion mejorado (deporte + sede en vez de slug)")
