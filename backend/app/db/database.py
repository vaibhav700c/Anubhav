"""Database connection and session handling using SQLAlchemy."""

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.config import settings

# Render's managed Postgres hands out connection strings starting with
# "postgres://" (the old libpq-style scheme) - SQLAlchemy 1.4+ only
# recognizes "postgresql://" and raises on the old one, so this would
# otherwise fail to even start once DATABASE_URL points at Postgres instead
# of the default SQLite file.
database_url = settings.DATABASE_URL
if database_url.startswith("postgres://"):
    database_url = database_url.replace("postgres://", "postgresql://", 1)

# For SQLite, check_same_thread needs to be False for multithreaded FastAPI requests
connect_args = {}
if database_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(database_url, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependency for obtaining database sessions."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Create all tables defined in Base."""
    import app.db.models  # noqa: F401
    Base.metadata.create_all(bind=engine)

# Auto-initialize database schema
init_db()

