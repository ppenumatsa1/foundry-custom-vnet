from __future__ import annotations

from azure.ai.agents import AgentsClient
from azure.identity import DefaultAzureCredential

from foundry_invoice_agent.config import Settings


def build_agents_client(settings: Settings) -> AgentsClient:
    credential = DefaultAzureCredential()
    return AgentsClient(
        endpoint=settings.azure_projects_endpoint, credential=credential
    )
