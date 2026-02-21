#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}"
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}"
ENABLE_CAPABILITY_HOST_CLEANUP="${ENABLE_CAPABILITY_HOST_CLEANUP:-false}"
ACCOUNT_CAP_HOST_NAME="${ACCOUNT_CAP_HOST_NAME:-caphostacct}"
PROJECT_CAP_HOST_NAME="${PROJECT_CAP_HOST_NAME:-caphostproj}"
PROJECT_NAME="${FOUNDRY_PROJECT_NAME:-private-project}"

if [[ "${ENABLE_CAPABILITY_HOST_CLEANUP,,}" != "true" ]]; then
  echo "Skipping capability host cleanup: ENABLE_CAPABILITY_HOST_CLEANUP is not true."
  exit 0
fi

if [[ -z "$RESOURCE_GROUP" || -z "$SUBSCRIPTION_ID" ]]; then
  echo "Skipping capability host cleanup: AZURE_RESOURCE_GROUP or AZURE_SUBSCRIPTION_ID is not set."
  exit 0
fi

ACCOUNT_NAME="${FOUNDRY_ACCOUNT_NAME:-}"
if [[ -z "$ACCOUNT_NAME" ]]; then
  ACCOUNT_NAME="$(az cognitiveservices account list -g "$RESOURCE_GROUP" --query "[?kind=='AIServices'].name | [0]" -o tsv 2>/dev/null || true)"
fi

if [[ -z "$ACCOUNT_NAME" ]]; then
  echo "Skipping capability host cleanup: no AIServices account found in $RESOURCE_GROUP."
  exit 0
fi

ACCOUNT_CAP_HOST_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.CognitiveServices/accounts/${ACCOUNT_NAME}/capabilityHosts/${ACCOUNT_CAP_HOST_NAME}?api-version=2025-04-01-preview"
PROJECT_CAP_HOST_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.CognitiveServices/accounts/${ACCOUNT_NAME}/projects/${PROJECT_NAME}/capabilityHosts/${PROJECT_CAP_HOST_NAME}?api-version=2025-04-01-preview"

az rest --method DELETE --url "$PROJECT_CAP_HOST_URL" >/dev/null 2>&1 || true
az rest --method DELETE --url "$ACCOUNT_CAP_HOST_URL" >/dev/null 2>&1 || true

echo "Capability host cleanup completed (project/account)."
