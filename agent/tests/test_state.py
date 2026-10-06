from app import state


def test_session_lifecycle(tmp_path, monkeypatch):
    db_path = tmp_path / "state.db"
    monkeypatch.setattr(state.settings, "state_db_path", str(db_path))

    assert state.get_session("case-1") is None

    created = state.upsert_session("case-1", "resp_001")
    assert created["session_id"] == "case-1"
    assert created["previous_response_id"] == "resp_001"
    assert created["created_at"]
    assert created["updated_at"]

    updated = state.upsert_session("case-1", "resp_002")
    assert updated["previous_response_id"] == "resp_002"
    assert updated["created_at"] == created["created_at"]

    assert state.clear_session("case-1") is True
    assert state.get_session("case-1") is None
    assert state.clear_session("case-1") is False


def test_session_id_cannot_be_empty(tmp_path, monkeypatch):
    db_path = tmp_path / "state.db"
    monkeypatch.setattr(state.settings, "state_db_path", str(db_path))

    try:
        state.upsert_session("   ", "resp_001")
    except ValueError as exc:
        assert "cannot be empty" in str(exc)
    else:
        raise AssertionError("Expected ValueError for empty session_id")
