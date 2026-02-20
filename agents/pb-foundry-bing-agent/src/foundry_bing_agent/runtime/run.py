from __future__ import annotations

from dataclasses import dataclass

from foundry_bing_agent.config import get_settings
from foundry_bing_agent.runtime.agent import get_or_create_agent
from foundry_bing_agent.runtime.openai_client import build_project_client

AGENT_INSTRUCTIONS = (
    'You are a helpful assistant. '
    'Use web search when current or external information is needed. '
    'Provide concise answers and cite uncertainty when needed.'
)


@dataclass(frozen=True)
class AskResult:
    response_text: str
    foundry_conversation_id: str
    response_id: str | None


def _extract_response_text(response: object) -> str:
    output_text = getattr(response, 'output_text', None)
    if isinstance(output_text, str) and output_text.strip():
        return output_text.strip()

    output_items = getattr(response, 'output', None)
    if not output_items:
        return ''

    parts: list[str] = []
    for item in output_items:
        item_type = getattr(item, 'type', None)
        if item_type == 'message':
            content = getattr(item, 'content', None)
            if isinstance(content, list):
                for block in content:
                    if getattr(block, 'type', None) == 'output_text':
                        text = getattr(block, 'text', None)
                        if isinstance(text, str) and text.strip():
                            parts.append(text.strip())
        elif item_type == 'output_text':
            text = getattr(item, 'text', None)
            if isinstance(text, str) and text.strip():
                parts.append(text.strip())

    return '\n'.join(parts).strip()


def ask_question(question: str, conversation_id: str | None = None) -> AskResult:
    settings = get_settings()
    project_client = build_project_client(settings)
    agent_name = get_or_create_agent(project_client, settings, AGENT_INSTRUCTIONS)

    with project_client.get_openai_client() as openai_client:
        if conversation_id:
            openai_client.conversations.items.create(
                conversation_id=conversation_id,
                items=[
                    {
                        'type': 'message',
                        'role': 'user',
                        'content': question,
                    }
                ],
            )
            foundry_conversation_id = conversation_id
        else:
            conversation = openai_client.conversations.create(
                items=[
                    {
                        'type': 'message',
                        'role': 'user',
                        'content': question,
                    }
                ]
            )
            foundry_conversation_id = conversation.id

        response = openai_client.responses.create(
            conversation=foundry_conversation_id,
            input='',
            extra_body={
                'agent': {
                    'name': agent_name,
                    'type': 'agent_reference',
                }
            },
        )

    return AskResult(
        response_text=_extract_response_text(response),
        foundry_conversation_id=foundry_conversation_id,
        response_id=getattr(response, 'id', None),
    )
