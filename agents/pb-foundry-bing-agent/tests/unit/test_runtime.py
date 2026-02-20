from types import SimpleNamespace

from foundry_bing_agent.runtime.run import _extract_response_text


def test_extract_prefers_output_text() -> None:
    response = SimpleNamespace(output_text="  hello world  ", output=[])
    assert _extract_response_text(response) == "hello world"


def test_extract_reads_message_content_blocks() -> None:
    response = SimpleNamespace(
        output_text=None,
        output=[
            SimpleNamespace(
                type="message",
                content=[
                    SimpleNamespace(type="output_text", text="first"),
                    SimpleNamespace(type="output_text", text="second"),
                ],
            )
        ],
    )
    assert _extract_response_text(response) == "first\nsecond"
