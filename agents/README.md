# Agents

This folder is reserved for agent code and runtime artifacts.

## Phase plan

- Phase 1 (current): deploy private-network infra and Foundry baseline from `../infra`.
- Phase 2 (in progress): add simple Bing-capable Foundry agent with controlled egress policy review.

Suggested future layout:

- `pb-foundry-bing-agent/` Foundry-only runtime (no M365 channel)
- `shared/` for common helpers
- `tests/` for integration and smoke tests
