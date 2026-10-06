from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.config import settings


ALLOWED_PREFERENCE_KEYS = {
    "detail_level",
    "preferred_breakdown",
    "include_risks",
    "include_scenario_if_relevant",
}


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
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS analyst_preferences (
                profile_id TEXT NOT NULL,
                preference_key TEXT NOT NULL,
                preference_value TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                PRIMARY KEY (profile_id, preference_key)
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
    if session is None:
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


def get_preferences(profile_id: str) -> dict[str, Any]:
    """Return bounded, explicit analyst/reporting preferences for a profile."""
    if not profile_id.strip():
        raise ValueError("profile_id cannot be empty")

    init_state_store()
    with _connect() as conn:
        rows = conn.execute(
            """
            SELECT preference_key, preference_value
            FROM analyst_preferences
            WHERE profile_id = ?
            ORDER BY preference_key
            """,
            (profile_id,),
        ).fetchall()

    return {
        row["preference_key"]: json.loads(row["preference_value"])
        for row in rows
    }


def set_preferences(profile_id: str, preferences: dict[str, Any]) -> dict[str, Any]:
    """Persist only whitelisted non-sensitive reporting preferences.

    Unknown keys are rejected instead of silently storing arbitrary memory.
    A value of None removes the existing preference.
    """
    normalized = profile_id.strip()
    if not normalized:
        raise ValueError("profile_id cannot be empty")

    unknown = set(preferences) - ALLOWED_PREFERENCE_KEYS
    if unknown:
        raise ValueError(f"Unsupported preference key(s): {sorted(unknown)}")

    init_state_store()
    now = datetime.now(timezone.utc).isoformat()

    with _connect() as conn:
        for key, value in preferences.items():
            if value is None:
                conn.execute(
                    """
                    DELETE FROM analyst_preferences
                    WHERE profile_id = ? AND preference_key = ?
                    """,
                    (normalized, key),
                )
                continue

            conn.execute(
                """
                INSERT INTO analyst_preferences (
                    profile_id,
                    preference_key,
                    preference_value,
                    updated_at
                )
                VALUES (?, ?, ?, ?)
                ON CONFLICT(profile_id, preference_key) DO UPDATE SET
                    preference_value = excluded.preference_value,
                    updated_at = excluded.updated_at
                """,
                (normalized, key, json.dumps(value), now),
            )
        conn.commit()

    return get_preferences(normalized)


def clear_preferences(profile_id: str) -> bool:
    init_state_store()
    with _connect() as conn:
        cursor = conn.execute(
            "DELETE FROM analyst_preferences WHERE profile_id = ?",
            (profile_id.strip(),),
        )
        conn.commit()
        return cursor.rowcount > 0
