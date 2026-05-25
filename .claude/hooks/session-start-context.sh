#!/usr/bin/env bash
# SessionStart용. 현재 git 브랜치와 변경 파일 목록을 Claude 컨텍스트에 주입한다.
# 세션 시작 시 매번 같은 정보를 사람이 붙여넣지 않아도 되게 함.
#
# 등록 예시 (.claude/settings.json):
#   {
#     "hooks": {
#       "SessionStart": [{
#         "matcher": "startup|resume",
#         "hooks": [{
#           "type": "command",
#           "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start-context.sh"
#         }]
#       }]
#     }
#   }

set -euo pipefail

# stdin은 무시하되 파이프 깨짐 방지를 위해 비워둔다
cat > /dev/null || true

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  jq -n '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: "(git 저장소 아님)"}}'
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
STATUS=$(git status --short 2>/dev/null | head -n 20)
RECENT=$(git log --oneline -n 5 2>/dev/null)

CONTEXT=$(printf "현재 브랜치: %s\n\n변경 사항 (top 20):\n%s\n\n최근 커밋:\n%s" \
  "$BRANCH" "${STATUS:-(없음)}" "${RECENT:-(없음)}")

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
