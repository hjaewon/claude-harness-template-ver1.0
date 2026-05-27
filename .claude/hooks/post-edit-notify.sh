#!/usr/bin/env bash
# PostToolUse + Write|Edit 매처용. 편집된 파일 경로를 로그에 남긴다.
# 어떤 파일을 언제 건드렸는지 추적할 때 유용. 출력은 비-차단(exit 0).
#
# 등록 예시 (.claude/settings.json):
#   {
#     "hooks": {
#       "PostToolUse": [{
#         "matcher": "Write|Edit",
#         "hooks": [{
#           "type": "command",
#           "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/post-edit-notify.sh"
#         }]
#       }]
#     }
#   }

set -euo pipefail

LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/edit.log"
INPUT=$(cat)

PYTHON_BIN=${PYTHON_BIN:-}
if [ -z "$PYTHON_BIN" ]; then
  if command -v python >/dev/null 2>&1; then
    PYTHON_BIN=python
  else
    PYTHON_BIN=python3
  fi
fi

RESULT=$("$PYTHON_BIN" - "$INPUT" <<'PY'
import json, sys
try:
    p = json.loads(sys.argv[1])
    tool = p.get("tool_name") or "unknown"
    fp = (p.get("tool_input") or {}).get("file_path") or (p.get("tool_response") or {}).get("filePath", "")
    print(f"{tool}\t{fp}")
except Exception:
    print("unknown\t")
PY
)

TOOL="${RESULT%%	*}"
FILE="${RESULT#*	}"

if [ -n "$FILE" ]; then
  printf '[%s] %s %s\n' "$(date -Iseconds)" "$TOOL" "$FILE" >> "$LOG_FILE"
fi

exit 0
