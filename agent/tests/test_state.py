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


def test_preference_lifecycle_is_bounded(tmp_path, monkeypatch):
    db_path = tmp_path / "state.db"
    monkeypatch.setattr(state.settings, "state_db_path", str(db_path))

    assert state.get_preferences("analyst-1") == {}

    stored = state.set_preferences(
        "analyst-1",
        {
            "detail_level": "executive",
            "preferred_breakdown": "channel",
            "include_risks": True,
            "include_scenario_if_relevant": False,
        },
    )
    assert stored == {
        "detail_level": "executive",
        "include_risks": True,
        "include_scenario_if_relevant": False,
        "preferred_breakdown": "channel",
    }

    updated = state.set_preferences(
        "analyst-1",
        {
            "detail_level": "detailed",
            "preferred_breakdown": None,
        },
    )
    assert updated["detail_level"] == "detailed"
    assert "preferred_breakdown" not in updated
    assert updated["include_risks"] is True

    assert state.clear_preferences("analyst-1") is True
    assert state.get_preferences("analyst-1") == {}
    assert state.clear_preferences("analyst-1") is False


def test_preferences_reject_arbitrary_memory_keys(tmp_path, monkeypatch):
    db_path = tmp_path / "state.db"
    monkeypatch.setattr(state.settings, "state_db_path", str(db_path))

    try:
        state.set_preferences(
            "analyst-1",
            {"customer_secret": "do not store arbitrary profile facts"},
        )
    except ValueError as exc:
        assert "Unsupported preference" in str(exc)
    else:
        raise AssertionError("Expected arbitrary preference key to be rejected")
