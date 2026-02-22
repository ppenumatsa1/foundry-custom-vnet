# Troubleshooting Log (Private VNet AI Foundry)

Use this file for active, step-by-step troubleshooting notes.

- Keep entries short and time-ordered.
- Capture exact symptoms, what was tested, and the result.
- Move durable takeaways to `issues_learning.md` after resolution.

## Template

### [YYYY-MM-DD] Issue title

- **Symptom**:
- **Scope**:
- **Hypothesis**:
- **Checks run**:
  - Command / test:
  - Result:
- **Decision**:
- **Next action**:

---

## 2026-02-22 — Foundry IQ/Search vector-store 403

- **Symptom**:
  - Foundry IQ failed to fetch knowledge bases for Search connection.
  - `make index` failed on vector-store creation with Search `Forbidden`.
- **Checks run**:
  - Verified Search RBAC on both Foundry Project MI and jumpbox VM MI.
  - Verified embedding deployment existed (`text-embedding-3-large`).
  - Verified private DNS resolution to Search private endpoint.
  - Called Search data-plane with AAD token from VM MI.
- **Result**:
  - RBAC looked correct, but Search data-plane returned `403` before fix.
  - Search auth mode was `apiKeyOnly`.
- **Fix applied**:
  - Updated Search auth mode to `aadOrApiKey` in `infra/modules/data/dependencies.bicep`.
  - Reprovisioned via `azd provision`.
- **Validation**:
  - Search data-plane AAD call returned `200`.
  - `make index` succeeded and produced vector store.
  - `make run` succeeded after deleting stale `.foundry/agent.json` on VM.
