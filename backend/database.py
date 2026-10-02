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
    # Render entrega la connection string con distintos formatos segun
    # la cuenta: "postgres://" (viejo), "postgres+psycopg://" o
    # "postgresql+psycopg://" (apuntando al driver psycopg3, que no
    # instalamos -- usamos psycopg2-binary). SQLAlchemy elige el driver
    # por el prefijo, asi que normalizamos cualquier variante a
    # "postgresql://" a secas, para que siempre use psycopg2 sin
    # importar de que cuenta/version venga la base.
    DATABASE_URL = re.sub(r"^postgres(ql)?(\+\w+)?://", "postgresql://", DATABASE_URL.strip(), count=1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
