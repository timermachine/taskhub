#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="."
ENV_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  99-run-tests.sh --project-root <dir> [--env-file <path>]

Smoke tests for paypal/setup-and-integrate.
Requires the service to be configured and accessible.
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

tasklab_script_require_command "npm" "Install npm with Node.js: https://nodejs.org"

if [[ ! -f "$PROJECT_ROOT/paypal-integration/package.json" ]]; then
  echo "Missing generated npm project: $PROJECT_ROOT/paypal-integration/package.json" >&2
  echo "Run tasklab run paypal/setup-and-integrate so 02-scaffold-node-paypal.sh creates it." >&2
  exit 1
fi

echo ""
echo "Running npm test for paypal/setup-and-integrate..."
echo ""
echo "Command: npm test --prefix $PROJECT_ROOT/paypal-integration"
echo ""
TASKLAB_ENV_FILE="$ENV_FILE" npm test --prefix "$PROJECT_ROOT/paypal-integration"

# Write a brief results record (no secrets) and checkpoint.
TASK_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_FILE="$TASK_DIR/tasklab-test-results.txt"
{
  echo "task: paypal/setup-and-integrate"
  echo "ran: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "command: npm test --prefix paypal-integration"
  echo "outcome: pass"
} > "$RESULTS_FILE"
tasklab_git_checkpoint "$TASK_DIR" "tasklab(paypal/setup-and-integrate): integration tests pass"
