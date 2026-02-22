from __future__ import annotations

from pathlib import Path

from azure.ai.agents.models import FilePurpose

from foundry_invoice_agent.config import get_settings
from foundry_invoice_agent.runtime.cache import (
    load_vector_store_cache,
    save_vector_store_cache,
)
from foundry_invoice_agent.runtime.openai_client import build_agents_client


def index_invoices() -> str:
    settings = get_settings()
    agents_client = build_agents_client(settings)

    cached_vector_store_id = load_vector_store_cache()
    if cached_vector_store_id:
        try:
            agents_client.vector_stores.get(cached_vector_store_id)
            return cached_vector_store_id
        except Exception:
            pass

    invoice_dir = Path(__file__).resolve().parents[3] / "data" / "invoices"
    files = sorted(invoice_dir.glob("*.txt"))
    if not files:
        raise ValueError(f"No invoice files found in {invoice_dir}")

    file_ids: list[str] = []
    for file_path in files:
        uploaded = agents_client.files.upload_and_poll(
            file_path=str(file_path),
            purpose=FilePurpose.AGENTS,
        )
        file_ids.append(uploaded.id)

    vector_store = agents_client.vector_stores.create_and_poll(
        name="InvoiceVectorStore",
        file_ids=file_ids,
    )

    save_vector_store_cache(vector_store.id)
    return vector_store.id
