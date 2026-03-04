# Claude Code 종합 스킬 가이드

> 이 문서는 현재 설치된 모든 스킬, 슬래시 커맨드, 에이전트, 플러그인, 훅, 키바인딩을 정리한 종합 레퍼런스입니다.

---

## 목차

1. [일일 루틴 워크플로우](#1-일일-루틴-워크플로우)
2. [스킬 (Skills)](#2-스킬-skills)
3. [슬래시 커맨드 (Commands)](#3-슬래시-커맨드-commands)
4. [커스텀 에이전트 (Agents)](#4-커스텀-에이전트-agents)
5. [플러그인 스킬 (Plugin Skills)](#5-플러그인-스킬-plugin-skills)
6. [훅 (Hooks)](#6-훅-hooks)
7. [키바인딩 (Keybindings)](#7-키바인딩-keybindings)
8. [환경변수 레퍼런스](#8-환경변수-레퍼런스)

---

## 1. 일일 루틴 워크플로우

스킬과 커맨드를 조합한 추천 일일 루틴:

### 아침 루틴 (업무 시작 전 30분)

```
1. /daily-work-logger          → 어제 작업 내역 자동 정리
2. /obsidian:summarize-youtube  → 학습 영상 Obsidian 정리
3. /obsidian:summarize-article  → 기술 아티클 읽기 + 정리
```

### 업무 중

```
4. /commit                     → Conventional Commits 자동 생성
5. /check-security             → 코드 보안 취약점 검사
6. /augmented:cast-wide        → 설계 결정 시 대안 탐색
7. @spring-expert              → Spring 관련 질문
8. @code-review-expert         → 코드 리뷰 요청
```

### 퇴근 전

```
9. /wrap-up                    → 오늘 세션 작업 요약 저장
10. /update-claude-md           → CLAUDE.md 개선사항 반영
```

### 주간 (금요일)

```
11. /weekly-claude-analytics    → 주간 Claude 사용 통계
12. /weekly-newsletter          → 주간 뉴스레터 생성
```

---

## 2. 스킬 (Skills)

스킬은 Claude Code가 **자동으로 감지하여 적용**하는 전문 지식 모듈입니다. 별도 호출 없이 관련 키워드를 언급하면 활성화됩니다.

### 일상 생산성

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `daily-work-logger` | "어제 작업 정리해줘", "daily log" | 5개 서브에이전트(haiku)가 병렬로 어제 활동 분석 후 Daily Note 자동 반영 |
| `weekly-claude-analytics` | "주간 분석", "Claude 사용 통계" | 주간 세션 로그 분석 → 프로젝트별 시간/작업유형/Jira 이슈 리포트 |
| `weekly-newsletter` | "뉴스레터 만들어줘" | 이번 주 작성/수정 글을 모아 뉴스레터 생성 |
| `project-time-tracker` | "시간 추적", "time tracking" | 프로젝트별 Claude 세션 시간 집계 리포트 |
| `usage-pattern-analyzer` | "패턴 분석", "사용 통계" | 도구 사용 빈도/시간대별 생산성 시각화 |
| `learning-tracker` | "학습 정리", "TIL", "오늘 배운 것" | 세션에서 학습 내용 추출 → TIL 문서 생성 |
| `backlog-md` | Backlog.md CLI 사용 시 | 태스크 생성/편집/상태 관리 가이드 |
| `brunch-writer` | "브런치", "글 작성" | 브런치 블로그 글 작성 지원 |

### 개발 도구

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `gh` | GitHub CLI, PR, issue 언급 시 | `gh` 명령어 완전 가이드 (PR/Issue/Release/API) |
| `gl` | GitLab CLI, MR, pipeline 언급 시 | `glab` 명령어 완전 가이드 (MR/Pipeline/Release) - Issue 미사용 |
| `jira` | Jira, JQL, 이슈 관리 시 | `jira` CLI 완전 가이드 (JQL 레퍼런스 포함) |
| `react-best-practices` | React/Next.js 코드 작성 시 | Vercel 엔지니어링 기반 50개+ React 최적화 규칙 |
| `pdf-processing-pro` | PDF 처리 작업 시 | OCR, 폼, 테이블, 배치 처리 |
| `skill-creator` | "스킬 만들어줘" | 새 스킬 생성 메타 가이드 (init/package/validate) |
| `find-skills` | "이런 스킬 있어?" | 스킬 검색 및 설치 도우미 |

### Obsidian 지식관리

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `obsidian-vault` | Obsidian, vault, 마크다운, 태그 | markdown-oxide LSP 연동, 태그 체계, 토큰 최적화 전략 |
| `vis` | 시맨틱 검색, vault 분석 | Vault Intelligence System CLI (hybrid/semantic/colbert 검색) |

---

## 3. 슬래시 커맨드 (Commands)

슬래시 커맨드는 **`/커맨드명`으로 직접 호출**합니다.

### 개발 워크플로우

| 커맨드 | 사용법 | 설명 |
|--------|--------|------|
| `/commit` | `/commit` | Conventional Commits 자동 생성 (한국어 인코딩 처리, 임시 파일 방식) |
| `/wrap-up` | `/wrap-up` | 현재 세션 작업 요약 → `cc-logs/` 폴더 저장 |
| `/update-claude-md` | `/update-claude-md` | 세션 패턴 분석 후 CLAUDE.md 인터랙티브 업데이트 |
| `/check-security` | `/check-security [--fix] [--severity high]` | OWASP 기반 보안 취약점 스캔 |
| `/project-overview` | `/project-overview` | 프로젝트 구조/목적 종합 분석 (온보딩용) |
| `/conventional-review` | `/conventional-review` | 리뷰 코멘트 → Conventional Comments 형식 변환 |
| `/my-developer` | `/my-developer` | 개발 계획에 대한 피드백 |
| `/askUserQuestion` | `/askUserQuestion` | 인터랙티브 코드 어시스턴트 |
| `/markitdown-convert` | `/markitdown-convert [파일]` | Microsoft MarkItDown으로 파일 → Markdown 변환 |
| `/meeting-minutes` | `/meeting-minutes` | 회의 녹취록 → 체계적 회의록 마크다운 |
| `/coffee-time` | `/coffee-time` | 커피타임 대화 정리 → GitHub 자동 저장 |

### Augmented Coding (의사결정 지원)

> [lexler.github.io](https://lexler.github.io) 기반의 AI 페어프로그래밍 패턴

| 커맨드 | 언제 사용? | 설명 |
|--------|-----------|------|
| `/augmented:cast-wide` | 설계/의사결정 시 | 첫 번째 해결책에 안주하지 않고 **3개+ 대안 탐색** 강제 |
| `/augmented:parallel-impl` | 접근법이 불확실할 때 | Git worktree로 **3~5개 병렬 구현** 동시 진행 |
| `/augmented:happy-to-delete` | 구현이 꼬였을 때 | AI 코드 **폐기 결정 지원**, revert 후 재시도 가이드 |
| `/augmented:softest-prototype` | 요구사항 불확실할 때 | 코드 전에 **마크다운으로 프로토타이핑** |
| `/augmented:mind-dump` | 아이디어 초기 단계 | 비구조화된 사고 → **구조화된 출력** 변환 |
| `/augmented:reverse-direction` | 의사결정 막힐 때 | AI에게 **제안/질문 역할 위임** |
| `/augmented:refinement-loop` | 리팩토링/품질 개선 시 | 반복적 개선 패스로 **레이어별 노이즈 제거** |

### TDD (Test-Driven Development)

| 커맨드 | 설명 |
|--------|------|
| `/tdp:add-test-for-boundary-values` | 경계값 테스트 추가 (null, 빈 문자열, 경계 숫자 등) |
| `/tdp:add-test-for-change-later` | 미래 변경 시나리오 대비 테스트 |
| `/tdp:add-test-for-misbehaves` | 오작동 테스트 (happy-path 외 실패 케이스) |
| `/tdp:add-test-for-side-effects` | 부작용 테스트 (입력 변조, 공유 상태 변경 감지) |

### Obsidian 지식관리

| 커맨드 | 사용법 | 설명 |
|--------|--------|------|
| `/obsidian:summarize-youtube` | `/obsidian:summarize-youtube [kr\|en] [URL]` | YouTube → Obsidian 한글 요약 (기본: en) |
| `/obsidian:translate-youtube` | `/obsidian:translate-youtube [URL]` | YouTube 번역 → Obsidian 저장 |
| `/obsidian:summarize-article` | `/obsidian:summarize-article [URL]` | 기술 문서 URL → Obsidian 요약 |
| `/obsidian:translate-article` | `/obsidian:translate-article [URL]` | 기술 문서 번역 → Obsidian 저장 |
| `/obsidian:add-tag` | `/obsidian:add-tag [파일] [--dry-run]` | 계층적 태그 자동 부여 (5가지 카테고리) |
| `/obsidian:add-tag-and-move-file` | `/obsidian:add-tag-and-move-file [파일]` | 태그 부여 + 적절한 디렉토리로 이동 |
| `/obsidian:batch-process` | `/obsidian:batch-process` | Vault 파일 대량 처리 (Tmux Orchestrator) |
| `/obsidian:batch-summarize-urls` | `/obsidian:batch-summarize-urls` | URL 목록 → 서브에이전트 병렬 요약 |
| `/obsidian:vault-query` | `/obsidian:vault-query [질문]` | VIS 기반 vault 지능형 검색 |
| `/obsidian:related-contents` | `/obsidian:related-contents [파일]` | 관련 노트 섹션 자동 생성 |
| `/obsidian:create-presentation` | `/obsidian:create-presentation [파일]` | Obsidian → Advanced Slides 프레젠테이션 |
| `/obsidian:weekly-social-posts` | `/obsidian:weekly-social-posts` | Things 메모 → 소셜 미디어 포스트 |
| `/obsidian:tagging-example` | `/obsidian:tagging-example` | 태그 부여 예시 참고 |

---

## 4. 커스텀 에이전트 (Agents)

에이전트는 **`@에이전트명`으로 호출**하거나, Task tool이 자동으로 선택합니다.

### 코드 품질 전문가

| 에이전트 | 호출 | 전문 분야 |
|---------|------|----------|
| `kent-beck-expert` | `@kent-beck-expert` | **Tidy First** 방법론, Simple Design 4 규칙, 구조변경→행위변경 분리 |
| `refactoring-expert` | `@refactoring-expert` | **Martin Fowler 리팩토링 카탈로그**, Code Smell 식별, 안전한 단계별 리팩토링 |
| `code-refactorer` | `@code-refactorer` | 기능 유지하면서 코드 구조 개선 |
| `code-review-expert` | `@code-review-expert` | 체계적 코드 리뷰 (보안/성능/Spring-JPA 특화 체크리스트) |
| `oop-expert` | `@oop-expert` | 객체지향 프로그래밍 원칙 (SOLID, Design Patterns) |

### 개발 전문가

| 에이전트 | 호출 | 전문 분야 |
|---------|------|----------|
| `spring-expert` | `@spring-expert` | Spring Boot, Clean/Hexagonal Architecture, JPA, Security |
| `frontend-designer` | `@frontend-designer` | 프론트엔드 UI/UX 디자인 → 기술 명세 변환 |
| `vibe-coding-coach` | `@vibe-coding-coach` | 대화 기반 앱 개발 (비전 → 코드 변환) |
| `data-scientist` | `@data-scientist` | SQL, BigQuery, 데이터 분석 |
| `prompt-expert` | `@prompt-expert` | 프롬프트 엔지니어링, 프롬프트 최적화 |

### 콘텐츠 & 문서

| 에이전트 | 호출 | 전문 분야 |
|---------|------|----------|
| `youtube-obsidian-summarizer` | `@youtube-obsidian-summarizer` | YouTube → Obsidian 한글 문서 (opus 모델, 타임스탬프/Zettelkasten 포함) |
| `youtube-summarizer` | `@youtube-summarizer` | YouTube 영상 요약 |
| `content-writer` | `@content-writer` | 콘텐츠 작성 (아웃라인 → 풀 아티클) |
| `content-translator` | `@content-translator` | 기술 콘텐츠 번역 |
| `technical-researcher` | `@technical-researcher` | GitHub 프로젝트/API/코드 분석 |

### 프로젝트 관리

| 에이전트 | 호출 | 전문 분야 |
|---------|------|----------|
| `prd-expert` | `@prd-expert` | PRD(Product Requirements Document) 작성 |
| `prd-writer` | `@prd-writer` | PRD 작성 (상세 버전) |
| `project-task-planner` | `@project-task-planner` | PRD → 개발 태스크 리스트 변환 |

### Obsidian 지식관리

| 에이전트 | 호출 | 전문 분야 |
|---------|------|----------|
| `zettelkasten-expert` | `@zettelkasten-expert` | Zettelkasten 방법론 (INBOX→RESOURCES→SLIPBOX) |
| **Obsidian Ops Team** (다중 에이전트) | | |
| `moc-agent` | 자동 | Maps of Content 생성/관리 |
| `tag-agent` | 자동 | 태그 정규화/계층 구조화 |
| `connection-agent` | 자동 | 노트 간 연결 관계 분석/제안 |
| `metadata-agent` | 자동 | 프론트매터 표준화/메타데이터 추가 |
| `review-agent` | 자동 | 일관성 교차 검증 |

---

## 5. 플러그인 스킬 (Plugin Skills)

플러그인에서 제공하는 스킬로, **`/플러그인:스킬명`으로 호출**합니다.

### Superpowers (개발 워크플로우 프레임워크)

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `brainstorming` | 자동 (창작 작업 전 필수) | 구현 전 아이디어 탐색, 사용자 의도 파악 |
| `test-driven-development` | `/superpowers:test-driven-development` | TDD 워크플로우 (테스트 먼저 → 구현) |
| `systematic-debugging` | `/superpowers:systematic-debugging` | 체계적 버그 추적 (원인 분석 → 수정) |
| `writing-plans` | `/superpowers:writing-plans` | 다단계 작업 구현 계획 작성 |
| `executing-plans` | `/superpowers:executing-plans` | 작성된 계획 단계별 실행 |
| `dispatching-parallel-agents` | `/superpowers:dispatching-parallel-agents` | 독립 태스크 병렬 에이전트 분배 |
| `subagent-driven-development` | `/superpowers:subagent-driven-development` | 서브에이전트 기반 구현 |
| `using-git-worktrees` | `/superpowers:using-git-worktrees` | Git worktree 격리 작업 |
| `requesting-code-review` | `/superpowers:requesting-code-review` | 코드 리뷰 요청 |
| `receiving-code-review` | `/superpowers:receiving-code-review` | 코드 리뷰 피드백 반영 |
| `verification-before-completion` | `/superpowers:verification-before-completion` | 완료 전 검증 (테스트/빌드 확인) |
| `finishing-a-development-branch` | `/superpowers:finishing-a-development-branch` | 브랜치 작업 완료 및 통합 가이드 |
| `writing-skills` | `/superpowers:writing-skills` | 새 스킬 작성/검증 |

### Code Review

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `code-review` | `/code-review:code-review` | PR 코드 리뷰 수행 |

### Feature Dev

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `feature-dev` | `/feature-dev:feature-dev` | 코드베이스 이해 기반 피처 개발 가이드 |

### PR Review Toolkit

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `review-pr` | `/pr-review-toolkit:review-pr` | 전문 에이전트 활용 종합 PR 리뷰 |

### Frontend Design

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `frontend-design` | `/frontend-design:frontend-design` | 프로덕션급 프론트엔드 인터페이스 생성 |

### Atlassian (Jira/Confluence)

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `triage-issue` | `/atlassian:triage-issue` | 버그 리포트 트리아지 (중복 검색 → 이슈 생성) |
| `capture-tasks-from-meeting-notes` | `/atlassian:capture-tasks-from-meeting-notes` | 미팅 노트 → Jira 태스크 자동 생성 |
| `generate-status-report` | `/atlassian:generate-status-report` | Jira → Confluence 상태 리포트 |
| `search-company-knowledge` | `/atlassian:search-company-knowledge` | 사내 지식베이스 검색 (Confluence/Jira) |
| `spec-to-backlog` | `/atlassian:spec-to-backlog` | Confluence 스펙 → Jira 백로그 자동 변환 |

### Plugin Dev

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `create-plugin` | `/plugin-dev:create-plugin` | 플러그인 생성 워크플로우 |
| `plugin-structure` | `/plugin-dev:plugin-structure` | 플러그인 구조 이해/스캐폴딩 |
| `command-development` | `/plugin-dev:command-development` | 슬래시 커맨드 개발 |
| `skill-development` | `/plugin-dev:skill-development` | 스킬 개발 |
| `agent-development` | `/plugin-dev:agent-development` | 에이전트 개발 |
| `hook-development` | `/plugin-dev:hook-development` | 훅 개발 |
| `mcp-integration` | `/plugin-dev:mcp-integration` | MCP 서버 통합 |
| `plugin-settings` | `/plugin-dev:plugin-settings` | 플러그인 설정 관리 |

### CLAUDE.md Management

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `revise-claude-md` | `/claude-md-management:revise-claude-md` | 세션 학습 기반 CLAUDE.md 업데이트 |
| `claude-md-improver` | `/claude-md-management:claude-md-improver` | CLAUDE.md 감사/개선 |

### Hookify

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `hookify` | `/hookify:hookify` | 대화 분석 기반 훅 자동 생성 |
| `list` | `/hookify:list` | 설정된 hookify 규칙 목록 |
| `configure` | `/hookify:configure` | hookify 규칙 인터랙티브 설정 |
| `writing-rules` | `/hookify:writing-rules` | hookify 규칙 작성 가이드 |

### Playground

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `playground` | `/playground:playground` | 인터랙티브 HTML 플레이그라운드 생성 |

---

## 6. 훅 (Hooks)

### 현재 활성화된 훅

| 이벤트 | 트리거 | 동작 |
|--------|--------|------|
| **PreToolUse** (`*`) | 모든 도구 실행 시 | terminal-notifier로 macOS 알림 ("도구 실행 준비 중: [도구명]") |
| **PreToolUse** (`bash`) | Bash 명령 실행 시 | 명령어 + 설명을 `~/.claude/bash-command-log.txt`에 로깅 |
| **Stop** | 응답 완료 시 | terminal-notifier 알림 ("Claude 응답이 완료되었습니다") |
| **Notification** (`permission_prompt`) | 권한 요청 시 | "Permission required" 알림 (Ping 사운드) |
| **Notification** (`idle_prompt`) | 입력 대기 시 | "Waiting for input" 알림 (Pop 사운드) |
| **UserPromptSubmit** | 프롬프트 제출 시 | `-u` 감지 → ultra-think 모드 자동 활성화 |

### Ultra-Think 모드 사용법

프롬프트 끝에 `-u`를 추가하면 확장 사고 모드가 활성화됩니다:

```
이 코드를 리팩토링해줘 -u
```

### 보안 훅 스크립트

| 스크립트 | 위치 | 검사 내용 |
|---------|------|----------|
| `check-env-files.sh` | `~/.claude/hooks/` | `.env` 파일 커밋 방지 (`.env.*.example` 허용) |
| `check-sensitive-files.sh` | `~/.claude/hooks/` | `.pem, .key, .p12, .pfx, .jks, .crt, .cer` 파일 차단 |
| `check-hardcoded-paths.sh` | `~/.claude/hooks/` | 하드코딩된 사용자 경로 방지 (`$HOME` 또는 `~` 사용 강제) |
| `update-brewfile.sh` | `~/.claude/hooks/` | 커밋 전 Brewfile 자동 동기화 |

---

## 7. 키바인딩 (Keybindings)

### 핵심 단축키

| 키 | 컨텍스트 | 동작 |
|----|---------|------|
| `meta+p` | Chat | 모델 피커 (Opus/Sonnet/Haiku 선택) |
| `meta+o` | Chat | 패스트 모드 토글 |
| `meta+t` | Chat | 씽킹(확장 사고) 토글 |
| `ctrl+s` | Chat | 대화 스태시 (임시 저장) |
| `ctrl+q` | Chat | 스니펫 피커 |
| `ctrl+t` | Global | 투두 리스트 토글 |
| `ctrl+o` | Global | 트랜스크립트 토글 |
| `ctrl+r` | Global | 히스토리 검색 |
| `y` / `n` | Confirmation | 빠른 승인/거부 |
| `j` / `k` | Settings/Select | Vim 스타일 상하 이동 |
| `/` | Settings | 설정 검색 |
| `ctrl+e` | Confirmation | 설명 토글 |
| `ctrl+b` | Task | 태스크 백그라운드 실행 |
| `space` | Plugin | 플러그인 토글 |
| `i` | Plugin | 플러그인 설치 |

### DiffDialog 단축키

| 키 | 동작 |
|----|------|
| `left` / `right` | 이전/다음 소스 |
| `up` / `down` | 이전/다음 파일 |
| `enter` | 상세 보기 |
| `escape` | 닫기 |

### MessageSelector 단축키

| 키 | 동작 |
|----|------|
| `j` / `down` | 다음 메시지 |
| `k` / `up` | 이전 메시지 |
| `Shift+j` / `Shift+down` | 맨 아래 |
| `Shift+k` / `Shift+up` | 맨 위 |

---

## 8. 환경변수 레퍼런스

| 변수 | 현재 값 | 설명 |
|------|--------|------|
| `ENABLE_LSP_TOOL` | `1` | Serena LSP 통합 활성화 |
| `MAX_THINKING_TOKENS` | `16000` | 확장 사고 최대 토큰 |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `16384` | 최대 출력 토큰 |
| `BASH_MAX_OUTPUT_LENGTH` | `1000000` | Bash 출력 한도 (1MB) |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | 팀 에이전트 기능 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `claude-sonnet-4-5-20250929` | 서브에이전트 모델 (비용 최적화) |
| `BASH_DEFAULT_TIMEOUT_MS` | `120000` | Bash 기본 타임아웃 (2분) |
| `BASH_MAX_TIMEOUT_MS` | `600000` | Bash 최대 타임아웃 (10분) |
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | `1` | 하위 디렉토리 CLAUDE.md 읽기 |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | `1` | 작업 디렉토리 유지 |
| `CLAUDE_CODE_DISABLE_TERMINAL_TITLE` | `1` | 터미널 타이틀 변경 방지 |

---

## 빠른 참조 카드

```
[일상]
/daily-work-logger        어제 작업 정리
/wrap-up                  오늘 세션 요약
/commit                   커밋 생성
/weekly-claude-analytics  주간 통계

[개발]
/check-security           보안 스캔
/augmented:cast-wide      대안 탐색
/augmented:parallel-impl  병렬 구현
/tdp:add-test-for-*       TDD 테스트 추가

[Obsidian]
/obsidian:summarize-youtube [kr|en] [URL]
/obsidian:summarize-article [URL]
/obsidian:add-tag [파일]
/obsidian:vault-query [질문]

[에이전트]
@spring-expert            Spring 질문
@code-review-expert       코드 리뷰
@kent-beck-expert         Tidy First
@refactoring-expert       리팩토링

[GitLab (glab)]
glab mr create --fill           MR 생성
glab mr list --reviewer @me     리뷰 요청 MR
glab ci status                  파이프라인 상태
glab ci trace                   Job 로그 확인
glab mr merge --squash          스쿼시 머지

[Superpowers]
/superpowers:test-driven-development  TDD
/superpowers:systematic-debugging     디버깅
/superpowers:brainstorming            아이디어

[Atlassian]
/atlassian:triage-issue               이슈 트리아지
/atlassian:spec-to-backlog            스펙→백로그

[키보드]
meta+p  모델 선택    meta+o  패스트모드
meta+t  씽킹 토글   ctrl+s  스태시
y/n     승인/거부    j/k     Vim 이동
-u      울트라씽크   ctrl+t  투두 토글
```
