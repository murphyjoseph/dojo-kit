#!/usr/bin/env bash
# Installs git hooks from scripts/ into .git/hooks/
# Runs as the pnpm "prepare" script — safe to call multiple times.
set -euo pipefail

eval "$(mise activate bash --shims)" 2>/dev/null || true

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

# Skip if there's no .git directory (e.g. published package or CI tarball)
if [ ! -d "$REPO_ROOT/.git" ]; then
  echo "No .git directory found — skipping hook installation."
  exit 0
fi

mkdir -p "$GIT_HOOKS_DIR"

cp "$REPO_ROOT/scripts/commit-msg" "$GIT_HOOKS_DIR/commit-msg"
chmod +x "$GIT_HOOKS_DIR/commit-msg"

echo "Git hooks installed."
