from __future__ import annotations

import json
from pathlib import Path


def _get_foundry_dir() -> Path:
    project_root = Path(__file__).resolve().parents[3]
    return project_root / ".foundry"


def load_agent_cache() -> dict | None:
    cache_path = _get_foundry_dir() / "agent.json"
    if not cache_path.exists():
        return None
    return json.loads(cache_path.read_text(encoding="utf-8"))


def save_agent_cache(agent_id: str, vector_store_id: str) -> None:
    output_dir = _get_foundry_dir()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "agent.json"
    output_path.write_text(
        json.dumps(
            {
                "agent_id": agent_id,
                "vector_store_id": vector_store_id,
            },
            indent=2,
        ),
        encoding="utf-8",
    )


def load_vector_store_cache() -> str | None:
    cache_path = _get_foundry_dir() / "vector_store.json"
    if not cache_path.exists():
        return None
    data = json.loads(cache_path.read_text(encoding="utf-8"))
    return data.get("vector_store_id")


def save_vector_store_cache(vector_store_id: str) -> None:
    output_dir = _get_foundry_dir()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "vector_store.json"
    output_path.write_text(
        json.dumps({"vector_store_id": vector_store_id}, indent=2),
        encoding="utf-8",
    )
