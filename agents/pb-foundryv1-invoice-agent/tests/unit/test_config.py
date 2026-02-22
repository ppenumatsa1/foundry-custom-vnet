from foundry_invoice_agent.config import Settings


def test_settings_support_aliases(monkeypatch) -> None:
    monkeypatch.setenv(
        "PROJECT_ENDPOINT", "https://example.services.ai.azure.com/api/projects/demo"
    )
    monkeypatch.setenv("AZURE_AI_AGENT_NAME", "pb-foundryv1-invoice-agent")
    monkeypatch.setenv("MODEL_DEPLOYMENT_NAME", "gpt-4.1-mini")

    settings = Settings()

    assert settings.azure_projects_endpoint.endswith("/api/projects/demo")
    assert settings.foundry_agent_name == "pb-foundryv1-invoice-agent"
    assert settings.azure_openai_model == "gpt-4.1-mini"
