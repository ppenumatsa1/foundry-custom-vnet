from __future__ import annotations

from pathlib import Path

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    _env_path = Path(__file__).resolve().parents[2] / ".env"
    model_config = SettingsConfigDict(
        env_file=_env_path,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    azure_projects_endpoint: str = Field(
        validation_alias=AliasChoices(
            "AZURE_AI_PROJECT_ENDPOINT", "PROJECT_ENDPOINT", "FOUNDRY_PROJECT_ENDPOINT"
        )
    )
    foundry_agent_name: str = Field(
        default="pb-foundryv1-invoice-agent",
        validation_alias=AliasChoices(
            "AZURE_AI_AGENT_NAME", "FOUNDRY_AGENT_ID", "foundry_agent_name"
        ),
    )
    azure_openai_model: str = Field(
        validation_alias=AliasChoices(
            "AZURE_AI_MODEL_DEPLOYMENT_NAME", "MODEL_DEPLOYMENT_NAME"
        )
    )


def get_settings() -> Settings:
    return Settings()
