# Corrige un parentesis de mas que quedo al envolver la tarjeta de
# "proxima reserva" en un GestureDetector (patch_home_tap_reserva.py).
# Se corre una sola vez.

with open("lib/screens/home_screen.dart", encoding="utf-8") as f:
    content = f.read()

viejo = '''                          ),
                        );
                        );
                      }),'''

nuevo = '''                          ),
                        ),
                        );
                      }),'''

if viejo in content:
    content = content.replace(viejo, nuevo, 1)
    with open("lib/screens/home_screen.dart", "w", encoding="utf-8") as f:
        f.write(content)
    print("home_screen.dart: parentesis de mas corregido")
elif nuevo in content:
    print("home_screen.dart: ya estaba corregido, no se toco")
else:
    print("ADVERTENCIA: no se encontro el patron esperado, revisar a mano")
