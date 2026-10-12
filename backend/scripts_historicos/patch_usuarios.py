# Agrega GET /usuarios/{id} y PATCH /usuarios/{id} (editar perfil, menos email)
# a schemas.py y main.py. Se corre una sola vez.

import re

# --- schemas.py: agregar UsuarioUpdate ---
with open("schemas.py", encoding="utf-8") as f:
    schemas_content = f.read()

if "class UsuarioUpdate" not in schemas_content:
    anchor = "class UsuarioResponse(BaseModel):"
    assert anchor in schemas_content, "no se encontro UsuarioResponse en schemas.py"
    nuevo_schema = (
        "class UsuarioUpdate(BaseModel):\n"
        "    nombre: Optional[str] = None\n"
        "    apellido: Optional[str] = None\n"
        "    dni: Optional[str] = None\n"
        "    fecha_nacimiento: Optional[date] = None\n\n"
        + anchor
    )
    schemas_content = schemas_content.replace(anchor, nuevo_schema, 1)
    with open("schemas.py", "w", encoding="utf-8") as f:
        f.write(schemas_content)
    print("schemas.py: UsuarioUpdate agregado")
else:
    print("schemas.py: UsuarioUpdate ya existia, no se toco")

# --- main.py: agregar GET y PATCH de usuarios ---
with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

if "/usuarios/{usuario_id}" not in main_content:
    anchor = "# --- SEDES ---"
    assert anchor in main_content, "no se encontro el comentario '# --- SEDES ---' en main.py"
    nuevo_bloque = (
        "# --- USUARIOS ---\n\n"
        "@app.get(\"/usuarios/{usuario_id}\", response_model=schemas.UsuarioResponse)\n"
        "def obtener_usuario(usuario_id: UUID, db: Session = Depends(get_db)):\n"
        "    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()\n"
        "    if not usuario:\n"
        "        raise HTTPException(status_code=404, detail=\"Usuario no encontrado\")\n"
        "    return usuario\n\n"
        "@app.patch(\"/usuarios/{usuario_id}\", response_model=schemas.UsuarioResponse)\n"
        "def actualizar_usuario(usuario_id: UUID, datos: schemas.UsuarioUpdate, db: Session = Depends(get_db)):\n"
        "    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()\n"
        "    if not usuario:\n"
        "        raise HTTPException(status_code=404, detail=\"Usuario no encontrado\")\n\n"
        "    actualizaciones = datos.model_dump(exclude_unset=True)\n\n"
        "    if \"dni\" in actualizaciones:\n"
        "        dni_exist = db.query(models.Usuario).filter(\n"
        "            models.Usuario.dni == actualizaciones[\"dni\"],\n"
        "            models.Usuario.id != usuario_id\n"
        "        ).first()\n"
        "        if dni_exist:\n"
        "            raise HTTPException(status_code=400, detail=\"El DNI ya esta registrado\")\n\n"
        "    for campo, valor in actualizaciones.items():\n"
        "        setattr(usuario, campo, valor)\n\n"
        "    db.commit()\n"
        "    db.refresh(usuario)\n"
        "    return usuario\n\n"
        + anchor
    )
    main_content = main_content.replace(anchor, nuevo_bloque, 1)
    with open("main.py", "w", encoding="utf-8") as f:
        f.write(main_content)
    print("main.py: GET y PATCH de usuarios agregados")
else:
    print("main.py: endpoints de usuarios ya existian, no se toco")
