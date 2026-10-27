# Corre el modal de perfil (ProfileDropdown) un poco hacia la izquierda --
# estaba casi pegado al borde derecho (0.95).
# Se corre una sola vez.

with open("lib/screens/home_screen.dart", encoding="utf-8") as f:
    content = f.read()

viejo = "                  alignment: const Alignment(0.95, -0.72),"
nuevo = "                  alignment: const Alignment(0.7, -0.72),"

if viejo in content:
    content = content.replace(viejo, nuevo, 1)
    with open("lib/screens/home_screen.dart", "w", encoding="utf-8") as f:
        f.write(content)
    print("home_screen.dart: modal de perfil corrido hacia la izquierda (0.95 -> 0.7)")
elif "Alignment(0.7, -0.72)" in content:
    print("home_screen.dart: ya estaba en 0.7, no se toco")
else:
    print("ADVERTENCIA: no se encontro el patron esperado, revisar a mano")
