#!/usr/bin/env bash
# TDD Guard Hook - Claude Code PreToolUse[Edit|Write|MultiEdit]
# Blocks implementation edits when no corresponding test file exists.

set -u

INPUT=$(cat)
if [ -z "$INPUT" ] && [ -n "${CLAUDE_TOOL_INPUT:-}" ]; then
  INPUT="${CLAUDE_TOOL_INPUT}"
fi

if [ -z "$INPUT" ]; then
  exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

run_python() {
  if command -v python >/dev/null 2>&1 && python -c "import sys" >/dev/null 2>&1; then
    python "$@"
    return $?
  fi

  if command -v python3 >/dev/null 2>&1 && python3 -c "import sys" >/dev/null 2>&1; then
    python3 "$@"
    return $?
  fi

  if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
    py -3 "$@"
    return $?
  fi

  echo "TDD Guard requires Python 3." >&2
  return 127
}

deny() {
  local reason="$1"
  run_python - "$reason" <<'PY'
import json
import sys

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": sys.argv[1],
    }
}, ensure_ascii=False))
PY
}

PATHS=$(
  run_python - "$INPUT" <<'PY'
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

tool_input = payload.get("tool_input") or payload
items = []

for key in ("file_path", "path", "filename"):
    value = tool_input.get(key)
    if isinstance(value, str) and value:
        items.append(value)

for edit in tool_input.get("edits") or []:
    if isinstance(edit, dict):
        value = edit.get("file_path") or edit.get("path") or edit.get("filename")
        if isinstance(value, str) and value:
            items.append(value)

seen = set()
for path in items:
    if path in seen:
        continue
    seen.add(path)
    print(path)
PY
)

if [ -z "$PATHS" ]; then
  exit 0
fi

has_test_for() {
  local file_path="$1"
  local dir_name base_name parent_dir ext

  dir_name=$(dirname "$file_path")
  base_name=$(basename "$file_path" | sed -E 's/\.(ts|tsx|js|jsx|mjs|cjs)$//')
  parent_dir=$(dirname "$dir_name")

  for ext in ts tsx js jsx mjs cjs; do
    [ -f "${dir_name}/${base_name}.test.${ext}" ] && return 0
    [ -f "${dir_name}/${base_name}.spec.${ext}" ] && return 0
    [ -f "${dir_name}/__tests__/${base_name}.test.${ext}" ] && return 0
    [ -f "${dir_name}/__tests__/${base_name}.spec.${ext}" ] && return 0
    [ -f "${parent_dir}/__tests__/${base_name}.test.${ext}" ] && return 0
    [ -f "${parent_dir}/__tests__/${base_name}.spec.${ext}" ] && return 0
    [ -f "${PROJECT_ROOT}/tests/${base_name}.test.${ext}" ] && return 0
    [ -f "${PROJECT_ROOT}/tests/${base_name}.spec.${ext}" ] && return 0
    [ -f "${PROJECT_ROOT}/src/__tests__/${base_name}.test.${ext}" ] && return 0
    [ -f "${PROJECT_ROOT}/src/__tests__/${base_name}.spec.${ext}" ] && return 0
  done

  return 1
}

while IFS= read -r file_path; do
  [ -z "$file_path" ] && continue

  case "$file_path" in
    *test*|*spec*|*.test.*|*.spec.*|*__tests__*) continue ;;
  esac

  case "$file_path" in
    *.json|*.css|*.scss|*.md|*.yml|*.yaml|*.env*|*.config.*|*tailwind*|*postcss*|*tsconfig*) continue ;;
  esac

  case "$file_path" in
    */types/*|*/types.ts|*/types.d.ts) continue ;;
  esac

  case "$file_path" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
      if ! has_test_for "$file_path"; then
        base_name=$(basename "$file_path" | sed -E 's/\.(ts|tsx|js|jsx|mjs|cjs)$//')
        deny "TDD GUARD: '${base_name}' implementation file has no matching test file. Write the test first, for example '${base_name}.test.ts'."
        exit 0
      fi
      ;;
  esac
done <<< "$PATHS"

exit 0
