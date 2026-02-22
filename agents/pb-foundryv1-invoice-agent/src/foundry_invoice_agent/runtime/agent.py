from __future__ import annotations

import json

from azure.ai.agents import AgentsClient
from azure.ai.agents.models import (
    FileSearchTool,
    ResponseFormatJsonSchema,
    ResponseFormatJsonSchemaType,
)

from foundry_invoice_agent.config import Settings
from foundry_invoice_agent.runtime.cache import load_agent_cache, save_agent_cache


def _cached_agent_exists(agents_client: AgentsClient, agent_id: str) -> bool:
    try:
        agents_client.get_agent(agent_id)
        return True
    except Exception:
        return False


def get_or_create_agent(
    agents_client: AgentsClient,
    settings: Settings,
    schema: dict,
    vector_store_id: str,
) -> str:
    instructions = (
        "You are an invoice assistant. Use the File Search tool to answer questions. "
        f"Always return your response as valid JSON matching this schema: {json.dumps(schema)}. "
        "Include answer and top_documents array with doc_id, file_name, and snippet for each document."
    )

    file_search = FileSearchTool(vector_store_ids=[vector_store_id])
    cache = load_agent_cache()

    if cache and cache.get("vector_store_id") == vector_store_id:
        cached_agent_id = cache.get("agent_id")
        if isinstance(cached_agent_id, str) and _cached_agent_exists(
            agents_client, cached_agent_id
        ):
            return cached_agent_id

    agent = agents_client.create_agent(
        model=settings.azure_openai_model,
        name=settings.foundry_agent_name,
        instructions=instructions,
        tools=file_search.definitions,
        tool_resources=file_search.resources,
        response_format=ResponseFormatJsonSchemaType(
            json_schema=ResponseFormatJsonSchema(
                name="InvoiceAnswer",
                schema=schema,
                description="Answer invoice questions with citations.",
            )
        ),
    )

    save_agent_cache(agent.id, vector_store_id)
    return agent.id
