# Actualiza toda la cadena de herramientas de compilacion Android a
# versiones modernas y compatibles entre si, ya que Gradle 7.6.3 +
# AGP 7.3.0 son demasiado viejos para Flutter 3.47.1 (agosto 2026).
# Se corre una sola vez.

# 1) Gradle wrapper: 7.6.3 -> 8.9
with open("android/gradle/wrapper/gradle-wrapper.properties", encoding="utf-8") as f:
    wrapper_content = f.read()

viejo_gradle = "distributionUrl=https\\://services.gradle.org/distributions/gradle-7.6.3-all.zip"
nuevo_gradle = "distributionUrl=https\\://services.gradle.org/distributions/gradle-8.9-all.zip"

if viejo_gradle in wrapper_content:
    wrapper_content = wrapper_content.replace(viejo_gradle, nuevo_gradle, 1)
    with open("android/gradle/wrapper/gradle-wrapper.properties", "w", encoding="utf-8") as f:
        f.write(wrapper_content)
    print("gradle-wrapper.properties: Gradle actualizado (7.6.3 -> 8.9)")
elif nuevo_gradle in wrapper_content:
    print("gradle-wrapper.properties: ya estaba en 8.9, no se toco")
else:
    print("ADVERTENCIA: no se encontro la linea de distributionUrl esperada")

# 2) AGP (Android Gradle Plugin): 7.3.0 -> 8.6.0, compatible con Gradle 8.9
with open("android/settings.gradle", encoding="utf-8") as f:
    settings_content = f.read()

viejo_agp = 'id "com.android.application" version "7.3.0" apply false'
nuevo_agp = 'id "com.android.application" version "8.6.0" apply false'

if viejo_agp in settings_content:
    settings_content = settings_content.replace(viejo_agp, nuevo_agp, 1)
    with open("android/settings.gradle", "w", encoding="utf-8") as f:
        f.write(settings_content)
    print("settings.gradle: AGP actualizado (7.3.0 -> 8.6.0)")
elif nuevo_agp in settings_content:
    print("settings.gradle: AGP ya estaba en 8.6.0, no se toco")
else:
    print("ADVERTENCIA: no se encontro la linea de AGP esperada")
