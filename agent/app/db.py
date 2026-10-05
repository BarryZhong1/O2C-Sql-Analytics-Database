from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from app.config import settings


engine: Engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    future=True,
)
