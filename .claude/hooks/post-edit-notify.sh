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

TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // ""')

if [ -n "$FILE" ]; then
  printf '[%s] %s %s\n' "$(date -Iseconds)" "$TOOL" "$FILE" >> "$LOG_FILE"
fi

exit 0
