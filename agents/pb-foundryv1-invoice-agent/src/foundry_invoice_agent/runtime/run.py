from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any

from foundry_invoice_agent.config import get_settings
from foundry_invoice_agent.runtime.agent import get_or_create_agent
from foundry_invoice_agent.runtime.cache import load_vector_store_cache
from foundry_invoice_agent.runtime.openai_client import build_agents_client


@dataclass(frozen=True)
class AskResult:
    response_text: str


def _load_schema() -> dict:
    schema_path = Path(__file__).resolve().parents[1] / "schema.json"
    return json.loads(schema_path.read_text(encoding="utf-8"))


def _extract_assistant_text(messages: Any) -> str:
    for message in messages:
        if getattr(message, "role", None) != "assistant":
            continue

        content = getattr(message, "content", None)
        if isinstance(content, list) and content:
            first_block = content[0]
            text_obj = getattr(first_block, "text", None)
            value = getattr(text_obj, "value", None)
            if isinstance(value, str) and value.strip():
                return value.strip()

    return ""


def ask_question(question: str) -> AskResult:
    settings = get_settings()
    vector_store_id = load_vector_store_cache()
    if not vector_store_id:
        raise FileNotFoundError("Vector store id not found. Run: make index")

    schema = _load_schema()
    agents_client = build_agents_client(settings)
    agent_id = get_or_create_agent(agents_client, settings, schema, vector_store_id)

    thread = agents_client.threads.create()
    agents_client.messages.create(
        thread_id=thread.id,
        role="user",
        content=question,
    )

    run = agents_client.runs.create_and_process(
        thread_id=thread.id,
        agent_id=agent_id,
    )

    status_value = getattr(run.status, "value", str(run.status))
    if str(status_value).lower() != "completed":
        last_error = getattr(run, "last_error", None)
        error_message = f"Run did not complete successfully: {run.status}"
        if last_error:
            error_message = f"{error_message} ({last_error})"
        raise RuntimeError(error_message)

    messages = agents_client.messages.list(thread_id=thread.id)
    response_text = _extract_assistant_text(messages)
    if not response_text:
        raise RuntimeError("No assistant response text found in thread messages.")

    return AskResult(response_text=response_text)
