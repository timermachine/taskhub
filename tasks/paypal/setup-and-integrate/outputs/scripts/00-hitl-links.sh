#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="."
ENV_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  00-hitl-links.sh --project-root <dir> [--env-file <path>]

Prints paypal deep links and copy-once guidance for manual steps.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root) PROJECT_ROOT="${2:-}"; shift 2 ;;
    --env-file)     ENV_FILE="${2:-}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Unexpected argument: $1" >&2; usage; exit 2 ;;
  esac
done

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_lib/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_lib/git.sh"
ENV_FILE="$(tasklab_script_default_env_file "$PROJECT_ROOT" "$ENV_FILE")"

# Init the project root git repo on first touch so every subsequent run
# is checkpointed and diffs are available from the start.
TASK_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
tasklab_git_init_task_dir "$TASK_DIR"

echo ""
echo "━━━  paypal setup — manual steps  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Env file:  $ENV_FILE"
echo "  Template:  $PROJECT_ROOT/.env.example"
echo "  (Copy the template to .env if needed; keep .env gitignored)"
echo ""

echo "  ── Step 1: PayPal Developer Dashboard ───────────────────────────────"
echo "  URL:   https://developer.paypal.com/dashboard/applications/sandbox"
echo "  Docs:  https://developer.paypal.com/api/rest/"
echo ""
echo "  In the dashboard:"
echo "    1. Log in and keep the environment set to Sandbox."
echo "    2. Open Apps & Credentials."
echo "    3. Select an existing REST API app or create a new app."
echo "    4. Copy the sandbox Client ID and reveal/copy the sandbox Secret."
echo ""
echo "  Start from $PROJECT_ROOT/.env.example, then paste these values into $ENV_FILE:"
echo "    PAYPAL_ENVIRONMENT=sandbox"
echo "    PAYPAL_CLIENT_ID=<sandbox-client-id>"
echo "    PAYPAL_CLIENT_SECRET=<sandbox-client-secret>"
echo ""
echo "  Optional app defaults for generated examples:"
echo "    PAYPAL_CURRENCY=USD"
echo "    PAYPAL_TEST_AMOUNT=1.00"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

missing=0
if [[ ! -f "$ENV_FILE" ]]; then
  missing=1
else
  for key in PAYPAL_ENVIRONMENT PAYPAL_CLIENT_ID PAYPAL_CLIENT_SECRET; do
    if ! grep -Eq "^${key}=" "$ENV_FILE"; then
      missing=1
    fi
  done
fi

if [[ "$missing" -ne 0 ]]; then
  echo "  HITL pending: copy $PROJECT_ROOT/.env.example to $ENV_FILE,"
  echo "  fill in the sandbox values above,"
  echo "  then re-run: tasklab run paypal/setup-and-integrate --project-root \"$PROJECT_ROOT\""
  echo ""
  exit 1
fi

echo "  Required PayPal env variable names are present."
echo "  Run next: 01-preflight.sh --project-root \"$PROJECT_ROOT\""
echo ""
