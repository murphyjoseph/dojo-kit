#!/bin/bash
# PostToolUse hook: auto-lint JS/TS files after Write|Edit

# Read stdin JSON
input=$(cat)

# Extract file path from tool_input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Guard: no file path
if [ -z "$file_path" ]; then
  exit 0
fi

# Guard: only lint JS/TS files
case "$file_path" in
  *.js|*.ts|*.jsx|*.tsx) ;;
  *) exit 0 ;;
esac

# Guard: file must exist
if [ ! -f "$file_path" ]; then
  exit 0
fi

# Resolve project root from the edited file's location
project_dir="${CLAUDE_PROJECT_DIR:-.}"

# Detect package manager from lockfile
if [ -f "$project_dir/pnpm-lock.yaml" ]; then
  runner="pnpm exec"
elif [ -f "$project_dir/bun.lockb" ] || [ -f "$project_dir/bun.lock" ]; then
  runner="bunx"
elif [ -f "$project_dir/yarn.lock" ]; then
  runner="yarn exec"
elif [ -f "$project_dir/package-lock.json" ]; then
  runner="npx"
else
  # Fallback: try npx
  runner="npx"
fi

# Guard: runner command must be available
runner_bin="${runner%% *}"
if ! command -v "$runner_bin" &>/dev/null; then
  exit 0
fi

# Run eslint from project root
output=$(cd "$project_dir" && $runner eslint --no-warn-ignored "$file_path" 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
  # Send lint errors back to Claude as a system message
  escaped=$(echo "$output" | jq -Rs .)
  echo "{\"systemMessage\": \"ESLint errors in ${file_path}:\n\"${escaped}}"
fi

exit 0
