from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from app.config import settings


TOKEN_PATTERN = re.compile(r"[A-Za-z0-9_-]+")


def _tokens(text: str) -> set[str]:
    return {
        token.lower()
        for token in TOKEN_PATTERN.findall(text)
        if len(token) > 2
    }


def _source_files(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    if path.is_dir():
        return sorted(file for file in path.glob("*.md") if file.is_file())
    return []


def _paragraphs(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    blocks = [block.strip() for block in re.split(r"\n\s*\n", text) if block.strip()]

    current_heading = ""
    results: list[dict[str, str]] = []
    for block in blocks:
        lines = block.splitlines()
        first_line = lines[0].strip()
        paragraph = block

        if first_line.startswith("#"):
            current_heading = first_line.lstrip("#").strip()
            paragraph = "\n".join(lines[1:]).strip()
            # Markdown headings are metadata for ranking/context, not useful
            # standalone retrieval results. The next paragraph inherits them.
            if not paragraph:
                continue

        results.append(
            {
                "source": path.name,
                "heading": current_heading,
                "paragraph": paragraph,
            }
        )
    return results


def retrieve_policy(query: str, top_k: int = 3) -> dict[str, Any]:
    """Retrieve local O2C business context using lightweight keyword ranking.

    `POLICY_PATH` may point to either one Markdown file or a directory containing
    multiple Markdown documents. The MVP intentionally keeps retrieval local and
    inspectable; embeddings/vector retrieval can replace this scorer later.
    """
    path = Path(settings.policy_path)
    files = _source_files(path)
    if not files:
        return {
            "query": query,
            "matches": [],
            "warning": f"No policy/context Markdown files found at: {path}",
        }

    query_tokens = _tokens(query)
    scored: list[tuple[int, str, str, str]] = []

    for file in files:
        for item in _paragraphs(file):
            paragraph_tokens = _tokens(item["paragraph"])
            heading_tokens = _tokens(item["heading"])

            # Heading overlap receives a small boost because section labels such as
            # "Marketplace process changes" often carry strong business context.
            body_overlap = len(query_tokens & paragraph_tokens)
            heading_overlap = len(query_tokens & heading_tokens)
            score = body_overlap + heading_overlap

            if score:
                scored.append(
                    (
                        score,
                        item["source"],
                        item["heading"],
                        item["paragraph"],
                    )
                )

    scored.sort(key=lambda item: (item[0], item[1], item[2]), reverse=True)
    matches = [
        {
            "score": score,
            "source": source,
            "heading": heading,
            "paragraph": paragraph,
        }
        for score, source, heading, paragraph in scored[:top_k]
    ]

    return {
        "query": query,
        "search_path": str(path),
        "sources_searched": [file.name for file in files],
        "matches": matches,
    }
