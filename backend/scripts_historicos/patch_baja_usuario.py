# Agrega baja logica de usuarios: columna activo en el modelo, login que
# rechaza cuentas inactivas, registro que reactiva cuentas dadas de baja
# en vez de chocar por email/DNI duplicado, y DELETE /usuarios/{id} que
# marca activo=False (no borra fisicamente).
# Se corre una sola vez.

# --- models.py: agregar campo activo a Usuario ---
with open("models.py", encoding="utf-8") as f:
    models_content = f.read()

if "activo = Column(Boolean, default=True)" not in models_content.split("class Sede")[0]:
    anchor = "    password = Column(String, nullable=False)\n\n    reservas = relationship(\"Reserva\", back_populates=\"usuario\")"
    assert anchor in models_content, "no se encontro el bloque esperado en el modelo Usuario"
    nuevo = (
        "    password = Column(String, nullable=False)\n"
        "    activo = Column(Boolean, default=True)\n\n"
        "    reservas = relationship(\"Reserva\", back_populates=\"usuario\")"
    )
    models_content = models_content.replace(anchor, nuevo, 1)
    with open("models.py", "w", encoding="utf-8") as f:
        f.write(models_content)
    print("models.py: campo 'activo' agregado a Usuario")
else:
    print("models.py: 'activo' ya estaba en Usuario, no se toco")

# --- main.py: reemplazar registrar_usuario, login, y agregar DELETE de usuarios ---
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

# 1) Reemplazar el registro para que reactive cuentas dadas de baja
registro_viejo = '''@app.post("/auth/register", response_model=schemas.UsuarioResponse, status_code=status.HTTP_201_CREATED)
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
    return nuevo_usuario'''

registro_nuevo = '''@app.post("/auth/register", response_model=schemas.UsuarioResponse, status_code=status.HTTP_201_CREATED)
def registrar_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    user_email = db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first()
    user_dni = db.query(models.Usuario).filter(models.Usuario.dni == usuario.dni).first()

    # Si el email o el DNI ya pertenecen a una cuenta activa, no se puede registrar.
    if user_email and user_email.activo:
        raise HTTPException(status_code=400, detail="El correo electrónico ya está registrado")
    if user_dni and user_dni.activo:
        raise HTTPException(status_code=400, detail="El DNI ya está registrado")

    # Si coincide con una cuenta dada de baja (mismo email o DNI), se reactiva
    # en vez de crear una fila nueva -- evita choques de unicidad y conserva
    # el historial de reservas de esa cuenta.
    cuenta_inactiva = user_email or user_dni
    if cuenta_inactiva and not cuenta_inactiva.activo:
        cuenta_inactiva.nombre = usuario.nombre
        cuenta_inactiva.apellido = usuario.apellido
        cuenta_inactiva.dni = usuario.dni
        cuenta_inactiva.fecha_nacimiento = usuario.fecha_nacimiento
        cuenta_inactiva.email = usuario.email
        cuenta_inactiva.password = usuario.password
        cuenta_inactiva.activo = True
        db.commit()
        db.refresh(cuenta_inactiva)
        return cuenta_inactiva

    nuevo_usuario = models.Usuario(**usuario.model_dump())
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario'''

assert registro_viejo in main_content, "no se encontro registrar_usuario tal como se esperaba"
main_content = main_content.replace(registro_viejo, registro_nuevo, 1)

# 2) Login: rechazar cuentas inactivas
login_viejo = '''    if not user:
        raise HTTPException(status_code=401, detail="El correo electrónico no existe")
        
    if user.password.strip() != pass_clean:'''

login_nuevo = '''    if not user:
        raise HTTPException(status_code=401, detail="El correo electrónico no existe")

    if not user.activo:
        raise HTTPException(status_code=403, detail="Esta cuenta fue dada de baja")

    if user.password.strip() != pass_clean:'''

assert login_viejo in main_content, "no se encontro el bloque de login esperado"
main_content = main_content.replace(login_viejo, login_nuevo, 1)

# 3) Agregar DELETE /usuarios/{id} (baja logica) despues del PATCH de usuarios
if '@app.delete("/usuarios/{usuario_id}")' not in main_content:
    anchor = "# --- SEDES ---"
    assert anchor in main_content, "no se encontro '# --- SEDES ---' para insertar el DELETE de usuarios"
    delete_bloque = (
        '@app.delete("/usuarios/{usuario_id}")\n'
        'def dar_de_baja_usuario(usuario_id: UUID, db: Session = Depends(get_db)):\n'
        '    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()\n'
        '    if not usuario:\n'
        '        raise HTTPException(status_code=404, detail="Usuario no encontrado")\n'
        '    usuario.activo = False\n'
        '    db.commit()\n'
        '    return {"message": "Cuenta dada de baja"}\n\n'
        + anchor
    )
    main_content = main_content.replace(anchor, delete_bloque, 1)
    print("main.py: DELETE /usuarios/{id} agregado")

with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)

print("main.py: registro y login actualizados")
