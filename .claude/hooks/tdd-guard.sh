#!/usr/bin/env bash

# TDD Guard Hook — Claude Code PreToolUse[Edit|Write]
# 구현 파일(.ts/.tsx/.js/.jsx) 편집 직전, 짝이 되는 테스트 파일이 없으면 차단한다.
#
# 원본(Codex apply_patch 지원판) 기반으로 Claude Code 입력 규약에 맞게 단순화:
#   - 입력 키는 tool_input.file_path 하나만 사용 (Edit/Write 공통)
#   - Codex apply_patch의 "*** Add/Update/Delete File:" 텍스트 파싱 제거
#   - delete / Move to 분기 제거 (Claude의 Edit/Write는 항상 update/create)

set -u

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PYTHON_BIN=${PYTHON_BIN:-}
if [ -z "$PYTHON_BIN" ]; then
  if command -v python >/dev/null 2>&1; then
    PYTHON_BIN=python
  else
    PYTHON_BIN=python3
  fi
fi

deny() {
  local reason="$1"
  "$PYTHON_BIN" - "$reason" <<'PY'
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

FILE_PATH=$(
  "$PYTHON_BIN" - "$INPUT" <<'PY'
import json
import sys

try:
  payload = json.loads(sys.argv[1])
except Exception:
  sys.exit(0)

tool_input = payload.get("tool_input") or {}
value = tool_input.get("file_path")
if isinstance(value, str) and value:
  print(value)
PY
)

[ -z "$FILE_PATH" ] && exit 0

# 테스트 파일 자체는 통과
case "$FILE_PATH" in
  *test*|*spec*|*.test.*|*.spec.*|*__tests__*) exit 0 ;;
esac

# 설정/스타일/마크다운/타입 선언 등은 통과
case "$FILE_PATH" in
  *.json|*.css|*.scss|*.md|*.yml|*.yaml|*.env*|*.config.*|*tailwind*|*postcss*|*next.config*|*tsconfig*) exit 0 ;;
  */types/*|*/types.ts|*/types.d.ts) exit 0 ;;
  */layout.tsx|*/layout.ts|*/page.tsx|*/page.ts|*/loading.tsx|*/error.tsx|*/not-found.tsx|*/globals.css) exit 0 ;;
esac

has_test_for() {
  local file_path="$1"
  local dir_name base_name parent_dir ext

  dir_name=$(dirname "$file_path")
  base_name=$(basename "$file_path" | sed -E 's/\.(ts|tsx|js|jsx)$//')
  parent_dir=$(dirname "$dir_name")

  for ext in ts tsx js jsx; do
    [ -f "${dir_name}/${base_name}.test.${ext}" ] && return 0
    [ -f "${dir_name}/${base_name}.spec.${ext}" ] && return 0
    [ -f "${dir_name}/__tests__/${base_name}.test.${ext}" ] && return 0
    [ -f "${dir_name}/__tests__/${base_name}.spec.${ext}" ] && return 0
    [ -f "${parent_dir}/__tests__/${base_name}.test.${ext}" ] && return 0
    [ -f "${parent_dir}/__tests__/${base_name}.spec.${ext}" ] && return 0
    [ -f "${PROJECT_ROOT}/src/__tests__/${base_name}.test.${ext}" ] && return 0
    [ -f "${PROJECT_ROOT}/src/__tests__/${base_name}.spec.${ext}" ] && return 0
  done

  return 1
}

case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    if ! has_test_for "$FILE_PATH"; then
      base_name=$(basename "$FILE_PATH" | sed -E 's/\.(ts|tsx|js|jsx)$//')
      deny "TDD GUARD: '${base_name}'에 대한 테스트 파일이 존재하지 않습니다. 구현 코드를 작성하기 전에 테스트를 먼저 작성하세요. (테스트 파일 예: ${base_name}.test.ts)"
      exit 0
    fi
    ;;
esac

exit 0
