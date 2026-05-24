# 프로젝트: {프로젝트명}

> 매 작업 전 Claude가 자동으로 읽는 행동 지침이다. 사람이 직접 편집하지 말고,
> "이걸 CLAUDE.md에 반영해줘"라고 Claude에게 시켜 누적시킨다.
>
> **이 파일을 편집할 때는 반드시 먼저 `.claude/CLAUDE-EDITING-RULES.md`를 Read한 뒤 시작하라.**

## 기술 스택
- {프레임워크 (예: Next.js 15)}
- {언어 (예: TypeScript strict mode)}
- {스타일링 (예: Tailwind CSS)}

## 아키텍처 규칙
- CRITICAL: {절대 지켜야 할 규칙 1 (예: 모든 API 로직은 app/api/ 라우트 핸들러에서만 처리)}
- CRITICAL: {절대 지켜야 할 규칙 2 (예: 클라이언트 컴포넌트에서 직접 외부 API를 호출하지 말 것)}
- {일반 규칙 (예: 컴포넌트는 components/ 폴더에, 타입은 types/ 폴더에 분리)}

## 개발 프로세스
- CRITICAL: 새 기능 구현 시 반드시 테스트를 먼저 작성하고, 테스트가 통과하는 구현을 작성할 것 (TDD)
- 커밋 메시지는 conventional commits 형식을 따를 것 (feat:, fix:, docs:, refactor:)

## 명령어

```bash
npm run dev      # 개발 서버
npm run build    # 프로덕션 빌드
npm run lint     # ESLint
npm test         # 테스트
```

## 함정 (Claude가 자주 빠지는 곳)

<!-- 형식: "X 하지 마라. 이유: Y". Claude 실수 발생 시 사용자 지시로 누적된다. -->

(아직 없음)

## 도메인 메모

<!-- 코드만 봐선 모를 비즈니스 룰, 외부 시스템 계약, 약속된 인터페이스. -->

(아직 없음)
