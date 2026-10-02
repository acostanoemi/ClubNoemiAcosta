import os
import re
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL:
    # Forzamos el driver psycopg2 explicitamente en el prefijo, sin
    # importar que formato traiga la connection string de Render
    # ("postgres://", "postgresql://", "postgres+psycopg://", etc.).
    # No alcanza con dejarla en "postgresql://" a secas: a partir de
    # SQLAlchemy 2.1 el driver por defecto para ese prefijo paso a ser
    # psycopg (v3), que no instalamos (usamos psycopg2-binary). Forzar
    # el prefijo evita depender de cual sea el default de turno.
    DATABASE_URL = re.sub(r"^postgres(ql)?(\+\w+)?://", "postgresql+psycopg2://", DATABASE_URL.strip(), count=1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
