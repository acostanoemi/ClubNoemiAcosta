# Sube el AGP de 8.6.0 a 8.13.0, que cumple el minimo 8.11.1 que pide
# Flutter y es compatible con Gradle 8.14.
# Se corre una sola vez.

with open("android/settings.gradle", encoding="utf-8") as f:
    content = f.read()

viejo = 'id "com.android.application" version "8.6.0" apply false'
nuevo = 'id "com.android.application" version "8.13.0" apply false'

if viejo in content:
    content = content.replace(viejo, nuevo, 1)
    with open("android/settings.gradle", "w", encoding="utf-8") as f:
        f.write(content)
    print("settings.gradle: AGP actualizado (8.6.0 -> 8.13.0)")
elif nuevo in content:
    print("settings.gradle: AGP ya estaba en 8.13.0, no se toco")
else:
    print("ADVERTENCIA: no se encontro la linea de AGP esperada, revisar a mano")
