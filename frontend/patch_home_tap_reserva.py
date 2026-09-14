# Hace tocable la tarjeta de "Proxima reserva" en Home: al tocarla, navega
# al detalle de esa reserva (DetalleReservaScreen), reutilizando la clase
# ReservaConDetalle ya definida en mis_reservas_screen.dart.
# Se corre una sola vez.

with open("lib/screens/home_screen.dart", encoding="utf-8") as f:
    content = f.read()

# 1) Agregar los imports necesarios, justo despues del import de session.dart
if "import 'mis_reservas_screen.dart';" not in content:
    anchor_import = "import '../session.dart';"
    assert anchor_import in content, "no se encontro el import de session.dart"
    nuevo_import = (
        anchor_import + "\n"
        "import 'mis_reservas_screen.dart';\n"
        "import 'detalle_reserva_screen.dart';"
    )
    content = content.replace(anchor_import, nuevo_import, 1)
    print("home_screen.dart: imports agregados")
else:
    print("home_screen.dart: imports ya estaban, no se toco")

# 2) Envolver el Container de la reserva real con un GestureDetector que navega al detalle
anchor_inicio = "                        final espacio = _espacioPorId(reserva.espacioId);"
anchor_fin = '''                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Entrada a Consultar Canchas'''

if "DetalleReservaScreen(item: ReservaConDetalle(" not in content:
    assert anchor_inicio in content, "no se encontro el inicio del bloque de proxima reserva"
    assert anchor_fin in content, "no se encontro el final del bloque de proxima reserva"

    idx_inicio = content.index(anchor_inicio)
    idx_fin = content.index(anchor_fin) + len(anchor_fin)
    bloque_viejo = content[idx_inicio:idx_fin]

    # Dentro del bloque viejo, encontramos donde arranca el "return Container(" real
    # (el segundo, el de la reserva real, no el de "no hay reservas")
    marcador_return = "\n                        return Container("
    assert marcador_return in bloque_viejo, "no se encontro el return Container de la reserva real"

    antes_del_return, despues_del_return = bloque_viejo.split(marcador_return, 1)

    # despues_del_return empieza en "\n  width: double.infinity, ... );\n  }),\n  const SizedBox..."
    # Separamos el "});\n  const SizedBox..." final del contenido del Container en si
    cierre_builder = "\n                      }),\n                      const SizedBox(height: 16),\n                      // Entrada a Consultar Canchas"
    assert cierre_builder in despues_del_return, "no se encontro el cierre del Builder"
    contenido_container, resto_final = despues_del_return.split(cierre_builder, 1)

    nuevo_bloque = (
        antes_del_return
        + "\n                        return GestureDetector(\n"
        + "                          onTap: () async {\n"
        + "                            final cancelada = await Navigator.of(context).push<bool>(MaterialPageRoute(\n"
        + "                              builder: (_) => DetalleReservaScreen(\n"
        + "                                item: ReservaConDetalle(reserva: reserva, espacio: espacio, sede: sede),\n"
        + "                              ),\n"
        + "                            ));\n"
        + "                            if (cancelada == true) _cargarDatos();\n"
        + "                          },\n"
        + "                          child: Container("
        + contenido_container
        + "\n                        );\n                      }),\n                      const SizedBox(height: 16),\n                      // Entrada a Consultar Canchas"
    )

    content = content[:idx_inicio] + nuevo_bloque + content[idx_fin:]
    with open("lib/screens/home_screen.dart", "w", encoding="utf-8") as f:
        f.write(content)
    print("home_screen.dart: tarjeta de proxima reserva ahora navega al detalle")
else:
    print("home_screen.dart: la tarjeta ya navegaba al detalle, no se toco")
