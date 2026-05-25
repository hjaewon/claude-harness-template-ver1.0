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
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

DANGEROUS_PATTERN='rm[[:space:]]+-rf|git[[:space:]]+push[[:space:]]+--force|git[[:space:]]+reset[[:space:]]+--hard|DROP[[:space:]]+TABLE|mkfs|:\(\)\{'

if echo "$COMMAND" | grep -qE "$DANGEROUS_PATTERN"; then
  jq -n --arg cmd "$COMMAND" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("위험 명령 차단: " + $cmd)
    }
  }'
  exit 0
fi

exit 0
