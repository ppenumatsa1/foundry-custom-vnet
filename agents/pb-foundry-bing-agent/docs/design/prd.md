# Product Requirements

## Problem

Users need a CLI-based assistant that can answer current/external-information questions using Azure AI Foundry hosted agents with web grounding.

## Goals

- Support one-shot and interactive chat flows from CLI.
- Use Azure AI Foundry agent references for conversation and response generation.
- Automatically create or refresh agent versions with `WebSearchPreviewTool` when enabled.
- Reuse previously created agent metadata from local cache for faster repeated runs.
- Keep deployment/runtime auth keyless via `DefaultAzureCredential`.
- Provide configurable web-search context and approximate user location hints.

## Non-goals

- No Teams/M365 channel integration.
- No web UI; CLI-only experience.
- No ingestion/vector-store RAG pipeline in this agent.
- No Foundry eval orchestration in this project.
