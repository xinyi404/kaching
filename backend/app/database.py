"""SQLAlchemy engine and session configuration."""

import os
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


raw_db_url = os.getenv("DATABASE_URL")
if raw_db_url:
    # Handle Postgres or MySQL URLs provided by cloud providers like Render / Supabase / Railway
    if raw_db_url.startswith("postgres://"):
        raw_db_url = raw_db_url.replace("postgres://", "postgresql+psycopg2://", 1)
    elif raw_db_url.startswith("postgresql://"):
        raw_db_url = raw_db_url.replace("postgresql://", "postgresql+psycopg2://", 1)
    url_obj = make_url(raw_db_url)
    db_name = os.getenv("DATABASE_NAME")
    if db_name:
        url_obj = url_obj.set(database=db_name)
    DATABASE_URL = url_obj
else:
    # Default to local MySQL, or fallback cleanly
    fallback_url = "mysql+pymysql://root:password@127.0.0.1:3306/kaching?charset=utf8mb4"
    url_obj = make_url(fallback_url)
    db_name = os.getenv("DATABASE_NAME", "kaching")
    DATABASE_URL = url_obj.set(database=db_name)

DEFAULT_USER_ID = int(os.getenv("DEFAULT_USER_ID", "1"))
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    """Base class for ORM models."""


def get_db() -> Generator[Session, None, None]:
    """Yield one database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
