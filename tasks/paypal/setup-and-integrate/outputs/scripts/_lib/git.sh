#!/usr/bin/env bash
# Tasklab git checkpoint helpers — sourced by task scripts.
# All functions gracefully no-op when git is not installed or the
# directory is not (yet) a git repository.

tasklab_git_available() {
  command -v git >/dev/null 2>&1
}

# Ensure common secret/generated paths are present in .gitignore.
tasklab_git_ensure_gitignore() {
  local dir="$1"
  local gitignore="$dir/.gitignore"
  local entries=(".env" "*.env" "node_modules/")
  local added=0
  for entry in "${entries[@]}"; do
    if ! grep -qxF "$entry" "$gitignore" 2>/dev/null; then
      echo "$entry" >> "$gitignore"
      added=1
    fi
  done
  [[ "$added" -eq 1 ]] && echo "Updated .gitignore ($gitignore)"
  return 0
}

# Init a git repo inside the task directory itself — not the project root.
# Each task gets its own isolated history, safe to use inside live projects.
tasklab_git_init_task_dir() {
  local task_dir="$1"

  tasklab_git_available || { echo "git not found — skipping git init"; return 0; }

  tasklab_git_ensure_gitignore "$task_dir"

  if [[ ! -d "$task_dir/.git" ]]; then
    git -C "$task_dir" init --quiet
    echo "Initialized git repository: $task_dir"
    tasklab_git_checkpoint "$task_dir" "tasklab: init task"
  fi
}

# Stage all non-gitignored changes and commit. No-ops cleanly if there is
# nothing new to commit, or if git / a repo are not available.
tasklab_git_checkpoint() {
  local repo_dir="$1"
  local message="$2"

  tasklab_git_available || return 0
  [[ -d "$repo_dir/.git" ]] || return 0

  # Fall back to a local identity when none is configured globally.
  local email
  email="$(git -C "$repo_dir" config user.email 2>/dev/null || true)"
  if [[ -z "$email" ]]; then
    git -C "$repo_dir" config user.email "tasklab@local"
    git -C "$repo_dir" config user.name "TaskLab"
  fi

  git -C "$repo_dir" add -A

  if git -C "$repo_dir" diff --cached --quiet 2>/dev/null; then
    echo "git checkpoint: nothing new to commit"
    return 0
  fi

  git -C "$repo_dir" commit --quiet -m "$message"
  local short_hash
  short_hash="$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo '?')"
  echo "git checkpoint [$short_hash]: $message"
}
