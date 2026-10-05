from __future__ import annotations

import re
from pathlib import Path

from app.config import settings


def retrieve_policy(query: str, top_k: int = 3) -> dict:
    """
    Lightweight local retrieval for the MVP.

    Paragraphs are ranked by keyword overlap. Replace with embeddings/vector
    retrieval in the memory/context phase.
    """
    path = Path(settings.policy_path)
    if not path.exists():
        return {"query": query, "matches": [], "warning": f"Policy file not found: {path}"}

    text = path.read_text(encoding="utf-8")
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]

    tokens = {
        token.lower()
        for token in re.findall(r"[A-Za-z0-9_-]+", query)
        if len(token) > 2
    }

    scored = []
    for idx, paragraph in enumerate(paragraphs):
        p_tokens = {
            token.lower()
            for token in re.findall(r"[A-Za-z0-9_-]+", paragraph)
        }
        score = len(tokens & p_tokens)
        if score:
            scored.append((score, idx, paragraph))

    scored.sort(reverse=True)
    matches = [
        {"score": score, "paragraph": paragraph}
        for score, _, paragraph in scored[:top_k]
    ]

    return {"query": query, "matches": matches}
