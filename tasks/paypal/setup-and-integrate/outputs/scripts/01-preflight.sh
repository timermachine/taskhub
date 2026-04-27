#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="."
ENV_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  01-preflight.sh --project-root <dir> [--env-file <path>]

Validates:
  - Required tools are available
  - .env exists and contains required variables
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
ENV_FILE="$(tasklab_script_default_env_file "$PROJECT_ROOT" "$ENV_FILE")"

# ── Tool checks ───────────────────────────────────────────────────────────────
echo "Checking required tools..."

tasklab_script_require_command "node" "Install Node.js 18 or newer: https://nodejs.org"
tasklab_script_require_command "npm" "Install npm with Node.js: https://nodejs.org"
tasklab_script_require_command "curl" "Install curl"

NODE_MAJOR="$(node -p "Number(process.versions.node.split('.')[0])")"
if [[ "$NODE_MAJOR" -lt 18 ]]; then
  echo "Node.js 18 or newer is required; found $(node --version)." >&2
  exit 1
fi
echo "Node.js version OK: $(node --version)"
echo "npm version OK: $(npm --version)"
echo "curl version OK: $(curl --version | head -n 1)"

echo ""

# ── Env file check ────────────────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  echo "Run 00-hitl-links.sh first to create it." >&2
  exit 1
fi

tasklab_env_source_file "$ENV_FILE"

# ── Required variable checks ──────────────────────────────────────────────────
tasklab_env_need "$ENV_FILE" "PAYPAL_ENVIRONMENT"
tasklab_env_need "$ENV_FILE" "PAYPAL_CLIENT_ID"
tasklab_env_need "$ENV_FILE" "PAYPAL_CLIENT_SECRET"

case "${PAYPAL_ENVIRONMENT:-}" in
  sandbox) ;;
  live)
    echo "This task is sandbox-first and refuses live credentials." >&2
    exit 1
    ;;
  *)
    echo "PAYPAL_ENVIRONMENT must be sandbox for this task." >&2
    exit 1
    ;;
esac

echo "Preflight OK"
