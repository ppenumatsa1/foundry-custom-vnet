# Product Requirements

## Problem

Users need a CLI-based invoice assistant that can index invoice files and answer invoice questions with grounded retrieval and structured JSON responses.

## Goals

- Index local invoice documents into a Foundry vector store.
- Reuse vector store and agent between runs using local cache files.
- Answer invoice questions through a Foundry v1 assistant with `FileSearchTool`.
- Enforce JSON-schema response format for predictable downstream parsing.
- Support one-shot and interactive chat from CLI.
- Use managed identity authentication via `DefaultAzureCredential`.

## Non-goals

- No web UI; CLI-only interaction.
- No M365/Teams channel integration.
- No external document connectors beyond local `data/invoices/*.txt`.
- No batch evaluation/orchestration pipeline in this project.

## Deferred work (next phase)

- Stale-cache resilience is deferred to a later phase.
- Current cache behavior may fail if remote Foundry objects (agent/vector store) are deleted or changed out-of-band.
- Planned follow-up: add cache preflight validation + auto-heal (recreate/refresh cache) before runtime operations.
