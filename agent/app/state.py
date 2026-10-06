from __future__ import annotations

import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.config import settings


def _connect() -> sqlite3.Connection:
    path = Path(settings.state_db_path)
    if path.parent != Path("."):
        path.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_state_store() -> None:
    with _connect() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS agent_sessions (
                session_id TEXT PRIMARY KEY,
                previous_response_id TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """
        )
        conn.commit()


def get_session(session_id: str) -> dict[str, Any] | None:
    init_state_store()
    with _connect() as conn:
        row = conn.execute(
            """
            SELECT session_id, previous_response_id, created_at, updated_at
            FROM agent_sessions
            WHERE session_id = ?
            """,
            (session_id,),
        ).fetchone()

    return dict(row) if row else None


def upsert_session(session_id: str, previous_response_id: str | None) -> dict[str, Any]:
    if not session_id.strip():
        raise ValueError("session_id cannot be empty")

    init_state_store()
    now = datetime.now(timezone.utc).isoformat()

    with _connect() as conn:
        existing = conn.execute(
            "SELECT created_at FROM agent_sessions WHERE session_id = ?",
            (session_id,),
        ).fetchone()
        created_at = existing["created_at"] if existing else now

        conn.execute(
            """
            INSERT INTO agent_sessions (
                session_id,
                previous_response_id,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?)
            ON CONFLICT(session_id) DO UPDATE SET
                previous_response_id = excluded.previous_response_id,
                updated_at = excluded.updated_at
            """,
            (session_id, previous_response_id, created_at, now),
        )
        conn.commit()

    session = get_session(session_id)
    if session is None:  # defensive; should be impossible after successful insert
        raise RuntimeError("Failed to persist session state")
    return session


def clear_session(session_id: str) -> bool:
    init_state_store()
    with _connect() as conn:
        cursor = conn.execute(
            "DELETE FROM agent_sessions WHERE session_id = ?",
            (session_id,),
        )
        conn.commit()
        return cursor.rowcount > 0
