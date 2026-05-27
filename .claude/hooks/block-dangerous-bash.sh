#!/usr/bin/env bash
# PreToolUse + Bash 매처용. stdin으로 받은 JSON에서 명령어를 읽어
# 파괴적/되돌리기 어려운 패턴이 포함되면 deny 응답을 출력한다.
#
# 등록 예시 (.claude/settings.json):
#   {
#     "hooks": {
#       "PreToolUse": [{
#         "matcher": "Bash",
#         "hooks": [{
#           "type": "command",
#           "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-dangerous-bash.sh"
#         }]
#       }]
#     }
#   }

set -euo pipefail

INPUT=$(cat)

PYTHON_BIN=${PYTHON_BIN:-}
if [ -z "$PYTHON_BIN" ]; then
  if command -v python >/dev/null 2>&1; then
    PYTHON_BIN=python
  else
    PYTHON_BIN=python3
  fi
fi

COMMAND=$("$PYTHON_BIN" - "$INPUT" <<'PY'
import json, sys
try:
    payload = json.loads(sys.argv[1])
    print(payload.get("tool_input", {}).get("command", ""))
except Exception:
    pass
PY
)

[ -z "$COMMAND" ] && exit 0

DANGEROUS_PATTERN='rm[[:space:]]+-rf|git[[:space:]]+push[[:space:]]+--force|git[[:space:]]+reset[[:space:]]+--hard|DROP[[:space:]]+TABLE|mkfs|:\(\)\{'

if echo "$COMMAND" | grep -qE "$DANGEROUS_PATTERN"; then
  "$PYTHON_BIN" - "$COMMAND" <<'PY'
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "위험 명령 차단: " + sys.argv[1]
    }
}, ensure_ascii=False))
PY
  exit 0
fi

exit 0
