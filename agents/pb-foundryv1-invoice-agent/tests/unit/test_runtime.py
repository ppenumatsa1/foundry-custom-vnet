from types import SimpleNamespace

from foundry_invoice_agent.runtime.run import _extract_assistant_text


def test_extract_reads_assistant_message() -> None:
    messages = [
        SimpleNamespace(
            role="assistant",
            content=[SimpleNamespace(text=SimpleNamespace(value="  hello world  "))],
        )
    ]
    assert _extract_assistant_text(messages) == "hello world"


def test_extract_ignores_non_assistant_messages() -> None:
    messages = [
        SimpleNamespace(
            role="user",
            content=[SimpleNamespace(text=SimpleNamespace(value="ignored"))],
        ),
    ]
    assert _extract_assistant_text(messages) == ""
