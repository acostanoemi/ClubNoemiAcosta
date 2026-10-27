# Actualiza la version del plugin de Kotlin en android/settings.gradle
# de 1.7.10 (muy vieja, causaba "Language version 1.4 is no longer
# supported" al compilar con JDK 17) a 1.9.24, compatible con Gradle
# 7.6.3 y AGP 7.3.0 sin tocar ninguna otra version.
# Se corre una sola vez.

with open("android/settings.gradle", encoding="utf-8") as f:
    content = f.read()

viejo = 'id "org.jetbrains.kotlin.android" version "1.7.10" apply false'
nuevo = 'id "org.jetbrains.kotlin.android" version "1.9.24" apply false'

if viejo in content:
    content = content.replace(viejo, nuevo, 1)
    with open("android/settings.gradle", "w", encoding="utf-8") as f:
        f.write(content)
    print("settings.gradle: version de Kotlin actualizada (1.7.10 -> 1.9.24)")
elif nuevo in content:
    print("settings.gradle: ya estaba en 1.9.24, no se toco")
else:
    print("ADVERTENCIA: no se encontro la linea esperada, revisar a mano")
