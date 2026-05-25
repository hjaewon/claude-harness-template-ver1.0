# .claude/hooks

Claude Code 훅 스크립트 모음. 훅은 Claude Code의 라이프사이클 시점(도구 실행 전/후, 세션 시작, 사용자 입력 등)에 자동 실행되는 명령이다.

> 공식 문서: <https://code.claude.com/docs/en/hooks>

## 구조

훅 정의는 `.claude/settings.json`의 `hooks` 필드에 등록하고, 실제 실행 스크립트는 이 폴더에 둔다. `${CLAUDE_PROJECT_DIR}`로 프로젝트 루트를 참조한다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-dangerous-bash.sh"
          }
        ]
      }
    ]
  }
}
```

## 주요 이벤트

| 이벤트 | 발화 시점 | 차단 가능 |
|---|---|---|
| `SessionStart` | 세션 시작/재개 | X |
| `UserPromptSubmit` | 사용자 입력 제출 | O |
| `PreToolUse` | 도구 실행 직전 | O |
| `PostToolUse` | 도구 실행 성공 후 | X |
| `PostToolUseFailure` | 도구 실행 실패 후 | X |
| `Stop` | Claude 응답 종료 | O |
| `PreCompact` / `PostCompact` | 컨텍스트 압축 전/후 | 일부 O |

## 입출력 규약

훅 스크립트는 **stdin으로 JSON을 받고**, 종료 코드와 stdout으로 응답한다.

- **종료 코드 0**: 성공. stdout이 JSON이면 결과로 해석.
- **종료 코드 2**: 차단 에러. stderr 메시지가 Claude에게 전달되어 행동을 막음.
- **그 외**: 비차단 에러. stderr 첫 줄만 트랜스크립트에 표시.

차단/허용 결정을 내릴 때는 JSON으로 출력한다:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "위험 명령 감지"
  }
}
```

## 이 폴더의 예제

- `block-dangerous-bash.sh` — `PreToolUse` + Bash 매처. `rm -rf`, `git push --force` 등 파괴적 명령 차단.
- `session-start-context.sh` — `SessionStart`. 현재 브랜치/변경 파일을 Claude 컨텍스트에 주입.
- `post-edit-notify.sh` — `PostToolUse` + `Write|Edit` 매처. 편집된 파일 경로를 로그에 남김.

## 디버깅 팁

훅이 안 도는 것 같을 때:

1. `claude --debug`로 훅 실행 로그 확인
2. 스크립트를 직접 파이프해 테스트 (예: `echo '{"tool_input":{"command":"rm -rf /"}}' | ./block-dangerous-bash.sh`)
3. `jq -e '.hooks' .claude/settings.json`로 JSON 유효성 확인 — settings.json이 깨지면 해당 파일의 모든 설정이 무시된다.
