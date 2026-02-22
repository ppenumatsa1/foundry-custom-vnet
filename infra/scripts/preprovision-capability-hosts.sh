#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}"
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}"
ENABLE_CAPABILITY_HOST_CLEANUP="${ENABLE_CAPABILITY_HOST_CLEANUP:-false}"
ACCOUNT_CAP_HOST_NAME="${ACCOUNT_CAP_HOST_NAME:-caphostacct}"
PROJECT_CAP_HOST_NAME="${PROJECT_CAP_HOST_NAME:-caphostproj}"
PROJECT_NAME="${FOUNDRY_PROJECT_NAME:-private-project}"

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

wait_for_account_cap_host_unlock() {
  local max_attempts="${CAPHOST_WAIT_ATTEMPTS:-30}"
  local sleep_seconds="${CAPHOST_WAIT_SECONDS:-10}"
  local attempt=1

  while (( attempt <= max_attempts )); do
    local state
    state="$(az rest --method GET --url "$ACCOUNT_CAP_HOST_URL" --query "properties.provisioningState" -o tsv 2>/dev/null || true)"

    if [[ -z "$state" ]]; then
      echo "Capability host lock check: account capability host not found (unlocked)."
      return 0
    fi

    if [[ "$state" != "Deleting" ]]; then
      echo "Capability host lock check: account capability host state is '$state' (unlocked)."
      return 0
    fi

    echo "Capability host lock check: state is Deleting, waiting ${sleep_seconds}s (attempt ${attempt}/${max_attempts})..."
    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done

  echo "Timed out waiting for account capability host to leave Deleting state."
  return 1
}

wait_for_account_cap_host_deleted() {
  local max_attempts="${CAPHOST_WAIT_ATTEMPTS:-30}"
  local sleep_seconds="${CAPHOST_WAIT_SECONDS:-10}"
  local attempt=1

  while (( attempt <= max_attempts )); do
    local state
    state="$(az rest --method GET --url "$ACCOUNT_CAP_HOST_URL" --query "properties.provisioningState" -o tsv 2>/dev/null || true)"

    if [[ -z "$state" ]]; then
      echo "Account capability host deletion confirmed."
      return 0
    fi

    echo "Waiting for account capability host deletion (current state: ${state}) ${sleep_seconds}s (attempt ${attempt}/${max_attempts})..."
    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done

  echo "Timed out waiting for account capability host deletion."
  return 1
}

reconcile_account_cap_host_state() {
  local state
  state="$(az rest --method GET --url "$ACCOUNT_CAP_HOST_URL" --query "properties.provisioningState" -o tsv 2>/dev/null || true)"

  if [[ -z "$state" ]]; then
    echo "Account capability host does not exist."
    return 0
  fi

  case "$state" in
    Succeeded)
      echo "Account capability host state is Succeeded."
      return 0
      ;;
    Deleting)
      echo "Account capability host is Deleting; waiting for unlock."
      wait_for_account_cap_host_unlock
      return 0
      ;;
    Failed|Canceled)
      echo "Account capability host state is ${state}; deleting to avoid update conflicts."
      az rest --method DELETE --url "$ACCOUNT_CAP_HOST_URL" >/dev/null 2>&1 || true
      wait_for_account_cap_host_deleted
      return 0
      ;;
    *)
      echo "Account capability host is in transitional state '${state}'; waiting for unlock."
      wait_for_account_cap_host_unlock
      return 0
      ;;
  esac
}

if [[ "${ENABLE_CAPABILITY_HOST_CLEANUP,,}" == "true" ]]; then
  az rest --method DELETE --url "$PROJECT_CAP_HOST_URL" >/dev/null 2>&1 || true
  az rest --method DELETE --url "$ACCOUNT_CAP_HOST_URL" >/dev/null 2>&1 || true
  echo "Capability host cleanup completed (project/account)."
  wait_for_account_cap_host_unlock
  reconcile_account_cap_host_state
else
  state="$(az rest --method GET --url "$ACCOUNT_CAP_HOST_URL" --query "properties.provisioningState" -o tsv 2>/dev/null || true)"
  if [[ -z "$state" ]]; then
    echo "Skipping capability host cleanup: account capability host not found."
  else
    echo "Skipping capability host cleanup: ENABLE_CAPABILITY_HOST_CLEANUP is not true (current account caphost state: ${state})."
    if [[ "$state" == "Deleting" ]]; then
      echo "Note: state is Deleting. Sample-aligned mode does not block provision; if deployment fails, wait and retry or run cleanup explicitly."
    fi
  fi
fi
