import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL:
    # Render entrega la connection string con distintos prefijos segun
    # la cuenta/version: "postgres://" (formato viejo) o
    # "postgresql+psycopg://" (driver psycopg3, que no instalamos --
    # usamos psycopg2-binary). SQLAlchemy elige el driver por el
    # prefijo, asi que lo normalizamos siempre a "postgresql://" para
    # que use psycopg2 sin importar de que cuenta venga la base.
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
    elif DATABASE_URL.startswith("postgresql+psycopg://"):
        DATABASE_URL = DATABASE_URL.replace("postgresql+psycopg://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
