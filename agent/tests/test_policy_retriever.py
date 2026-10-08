from pathlib import Path

from app.tools import policy_retriever


def test_retrieve_policy_searches_multiple_markdown_files(tmp_path, monkeypatch):
    (tmp_path / "sla.md").write_text(
        "# Shipping SLA\n\nMarketplace orders should meet the shipping SLA.",
        encoding="utf-8",
    )
    (tmp_path / "changes.md").write_text(
        "# Marketplace process changes\n\nA promotional review step was introduced in July.",
        encoding="utf-8",
    )

    monkeypatch.setattr(policy_retriever.settings, "policy_path", str(tmp_path))

    result = policy_retriever.retrieve_policy(
        "Marketplace promotional review",
        top_k=3,
    )

    assert set(result["sources_searched"]) == {"changes.md", "sla.md"}
    assert result["matches"]
    assert result["matches"][0]["source"] == "changes.md"
    assert "promotional review" in result["matches"][0]["paragraph"]


def test_retrieve_policy_accepts_single_file(tmp_path, monkeypatch):
    source = tmp_path / "policy.md"
    source.write_text(
        "# Collections\n\nPayment performance should be compared with contractual due dates.",
        encoding="utf-8",
    )
    monkeypatch.setattr(policy_retriever.settings, "policy_path", str(source))

    result = policy_retriever.retrieve_policy("payment contractual due dates")

    assert result["sources_searched"] == ["policy.md"]
    assert result["matches"][0]["source"] == "policy.md"


def test_retrieve_policy_reports_missing_path(tmp_path, monkeypatch):
    missing = Path(tmp_path) / "missing"
    monkeypatch.setattr(policy_retriever.settings, "policy_path", str(missing))

    result = policy_retriever.retrieve_policy("Marketplace")

    assert result["matches"] == []
    assert "warning" in result


def test_heading_only_blocks_are_not_returned_as_matches(tmp_path, monkeypatch):
    source = tmp_path / "changes.md"
    source.write_text(
        "# Marketplace promotional review step\n\n"
        "A manual review step was introduced for Marketplace orders on July 1.",
        encoding="utf-8",
    )
    monkeypatch.setattr(policy_retriever.settings, "policy_path", str(source))

    result = policy_retriever.retrieve_policy(
        "Marketplace promotional review",
        top_k=1,
    )

    assert result["matches"][0]["heading"] == "Marketplace promotional review step"
    assert result["matches"][0]["paragraph"].startswith("A manual review step")
    assert not result["matches"][0]["paragraph"].startswith("#")
