#!/usr/bin/env bash
set -euo pipefail

tasklab_script_require_command() {
  local cmd="$1"
  local message="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing dependency: $cmd" >&2
    echo "$message" >&2
    exit 1
  fi
  echo "Found dependency: $cmd ($(command -v "$cmd"))"
}

tasklab_script_default_env_file() {
  local project_root="$1"
  local env_file="$2"
  if [[ -n "$env_file" ]]; then
    printf '%s' "$env_file"
    return 0
  fi
  printf '%s/.env' "$project_root"
}

tasklab_core_env_precheck() {
  local env_file="$1"
  [[ -f "$env_file" ]] || return 0

  local checker="grep"
  if command -v rg >/dev/null 2>&1; then
    checker="rg"
  fi

  local matches=""
  if [[ "$checker" == "rg" ]]; then
    matches="$(rg -n '^[A-Z0-9_]+=([^"'\''#][^#]*[[:space:]][^#]*)$' "$env_file" || true)"
  else
    matches="$(grep -nE '^[A-Z0-9_]+=([^"'\''#][^#]*[[:space:]][^#]*)$' "$env_file" || true)"
  fi

  if [[ -n "$matches" ]]; then
    echo "Invalid $env_file: unquoted value contains spaces:" >&2
    echo "$matches" >&2
    echo "Fix: wrap values with spaces in quotes." >&2
    exit 1
  fi
}

tasklab_env_source_file() {
  local env_file="$1"
  if [[ ! -f "$env_file" ]]; then
    echo "Missing env file: $env_file" >&2
    exit 1
  fi
  tasklab_core_env_precheck "$env_file"
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

tasklab_env_need() {
  local env_file="$1"
  local key="$2"
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required env var: $key (in $env_file)" >&2
    exit 1
  fi
}
