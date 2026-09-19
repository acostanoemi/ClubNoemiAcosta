"""
Crea todas las tablas de la base de datos a partir de los modelos
definidos en models.py. Es el paso inicial para levantar el backend
contra una base de datos nueva y vacia (por ejemplo, una recien creada
en Render).

Uso:
    python crear_tablas.py

Requiere que el archivo .env ya tenga DATABASE_URL configurado
(ver README.md para el resto de las variables necesarias).
"""
from database import Base, engine
import models  # noqa: F401 -- el import registra los modelos en Base.metadata

Base.metadata.create_all(bind=engine)
print("Tablas creadas correctamente.")
