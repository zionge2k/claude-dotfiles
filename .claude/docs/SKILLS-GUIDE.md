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
8. [CLAUDE.md 규칙 레퍼런스](#8-claudemd-규칙-레퍼런스)
9. [환경변수 및 설정 레퍼런스](#9-환경변수-및-설정-레퍼런스)

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

### 직접 만든 스킬 (dotfiles 포함, 11개)

#### 세션 탐색 및 프롬프트 구조화

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `agf` | "세션 목록", "session list", "세션 검색", "session search", "agf" | AI Agent Session Finder — `history.jsonl` 기반 세션 리스트/검색/상세분석. list, search, show 커맨드 지원 |
| `prompt-contracts` | brainstorming, planning, design, 설계, 기능 개발 | Prompt Contracts 프레임워크 — Goal/Constraints/Format/Failure Conditions 4요소로 바이브 코딩 방지 |

#### 일상 생산성

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `daily-work-logger` | "어제 작업 정리해줘", "daily log" | 4개 서브에이전트(haiku)가 병렬로 어제 활동 분석 후 Daily Note 자동 반영 (Vault Files / CC Sessions / Meeting Notes / Learning Extractor) |
| `weekly-claude-analytics` | "주간 분석", "Claude 사용 통계" | 주간 세션 로그 분석 → 프로젝트별 시간/작업유형/Jira 이슈 리포트 |
| `weekly-newsletter` | "뉴스레터 만들어줘" | 이번 주 작성/수정 글을 모아 뉴스레터 생성 |
| `project-time-tracker` | "시간 추적", "time tracking" | 프로젝트별 Claude 세션 시간 집계 리포트 |
| `usage-pattern-analyzer` | "패턴 분석", "사용 통계" | 도구 사용 빈도/시간대별 생산성 시각화 |
| `learning-tracker` | "학습 정리", "TIL", "오늘 배운 것" | 세션에서 학습 내용 추출 → TIL 문서 생성 |
| `brunch-writer` | "브런치", "글 작성", "블로그 글" | 브런치 블로그 글 작성 지원 (vault-intelligence로 관련 자료 검색, 구조 제안, 스타일 체크) |

#### Obsidian 지식관리

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `obsidian-vault` | Obsidian, vault, 마크다운, 태그, 백링크, wiki-link, PKM | markdown-oxide LSP 연동, 태그 체계, 토큰 최적화 전략 |
| `vis` | vault 검색, 문서 정리, 태그, MOC, 관련 문서, 주제 수집, 중복 검사, 학습 리뷰, 지식 공백, 클러스터링, 인덱싱, 태그 통계 | Vault Intelligence System CLI — 19개 명령어 지원 (아래 표 참조) |

#### vis 명령어 전체 목록

| 명령어 | 사용자 의도 | 예시 요청 |
|--------|-----------|----------|
| `vis search` | 문서 검색 (hybrid/semantic/keyword/colbert) | "TDD 관련 문서 찾아줘" |
| `vis collect` | 주제별 문서 수집 | "클린코드 문서 모아줘" |
| `vis related` | 관련 문서 찾기 | "이 문서와 비슷한 거 찾아줘" |
| `vis generate-moc` | MOC(Maps of Content) 생성 | "TDD MOC 만들어줘" |
| `vis tag` | 자동 태깅 | "이 문서에 태그 달아줘" |
| `vis add-related-docs` | 관련 문서 섹션 추가 | "관련 문서 링크 넣어줘" |
| `vis analyze-gaps` | 지식 공백 분석 | "vault에 부족한 주제 찾아줘" |
| `vis duplicates` | 중복 문서 감지 | "중복 문서 있어?" |
| `vis analyze` | 주제 분석/분포 | "vault 주제 분포 보여줘" |
| `vis summarize` | 클러스터 요약 | "주제별로 묶어줘" |
| `vis review` | 학습 리뷰 | "이번 주 학습 정리해줘" |
| `vis clean-tags` | 고립 태그 정리 | "안 쓰는 태그 정리해줘" |
| `vis reindex` | 인덱스 갱신 | "인덱스 다시 만들어줘" |
| `vis list-tags` | 태그 목록/통계 | "태그 분포 보여줘" |
| `vis connect-topic` | 주제별 문서 연결 | "TDD 주제 문서 연결해줘" |
| `vis connect-status` | 연결 진행 상황 | "연결 작업 얼마나 됐어?" |
| `vis info` | 시스템 상태 확인 | "vis 상태 어때?" |
| `vis init` | 인덱스 초기화 | "vis 새로 셋업해줘" |
| `vis test` | 검색 품질 테스트 | "검색 잘 되는지 확인해줘" |

### 외부 설치 스킬 (플러그인으로 관리, dotfiles 미포함)

다음 스킬은 `install.sh --plugins-only`로 설치됩니다. dotfiles에는 포함되지 않습니다.

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `gh` | GitHub CLI, PR, issue 언급 시 | `gh` 명령어 완전 가이드 (PR/Issue/Release/API) |
| `gl` | GitLab CLI, MR, pipeline 언급 시 | `glab` 명령어 완전 가이드 (MR/Pipeline/Release) |
| `jira` | Jira, JQL, 이슈 관리 시 | `jira` CLI 완전 가이드 (JQL 레퍼런스 포함) |
| `backlog-md` | Backlog.md CLI 사용 시 | 태스크 생성/편집/상태 관리 가이드 |
| `react-best-practices` | React/Next.js 코드 작성 시 | Vercel 엔지니어링 기반 50개+ React 최적화 규칙 |
| `pdf-processing-pro` | PDF 처리 작업 시 | OCR, 폼, 테이블, 배치 처리 |
| `skill-creator` | "스킬 만들어줘" | 새 스킬 생성 메타 가이드 (init/package/validate) |
| `find-skills` | "이런 스킬 있어?" | 스킬 검색 및 설치 도우미 |

---

## 3. 슬래시 커맨드 (Commands)

슬래시 커맨드는 **`/커맨드명`으로 직접 호출**합니다.

### 개발 워크플로우

| 커맨드 | 사용법 | 설명 |
|--------|--------|------|
| `/commit` | `/commit [--push] [--amend]` | Conventional Commits 자동 생성 (한국어 인코딩 처리, 임시 파일 방식) |
| `/wrap-up` | `/wrap-up [주제명] [--include-code] [--format markdown\|summary]` | 현재 세션 작업 요약 → `cc-logs/` 폴더 저장 |
| `/update-claude-md` | `/update-claude-md` | 세션 패턴 분석 후 CLAUDE.md 인터랙티브 업데이트 |
| `/check-security` | `/check-security [--fix] [--severity high]` | OWASP 기반 보안 취약점 스캔 |
| `/project-overview` | `/project-overview [--depth shallow\|deep] [--focus area] [--format summary\|detailed]` | 프로젝트 구조/목적 종합 분석 (온보딩용) |
| `/conventional-review` | `/conventional-review <review comment>` | 리뷰 코멘트 → Conventional Comments 형식 변환 |
| `/my-developer` | `/my-developer` | 개발자의 구현 계획에 대한 상세 피드백 (아키텍처 ~ 세부사항) |
| `/askUserQuestion` | `/askUserQuestion` | AskUserQuestion 도구를 활용한 대화형 요구사항 명확화 어시스턴트 |
| `/markitdown-convert` | `/markitdown-convert <file_path>` | Microsoft MarkItDown으로 파일 → Markdown 변환 |
| `/meeting-minutes` | `/meeting-minutes [YYYY-MM-DD] [회의 녹취록]` | 회의 녹취록 → 체계적 회의록 마크다운 |
| `/coffee-time` | `/coffee-time [YYYY-MM-DD] [대화 내용]` | 커피타임 대화 정리 → GitHub 자동 저장 |

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

| 에이전트 | 호출 | 모델 | 전문 분야 |
|---------|------|------|----------|
| `kent-beck-expert` | `@kent-beck-expert` | 기본 | **Tidy First** 방법론, Simple Design 4 규칙, 구조변경→행위변경 분리 |
| `refactoring-expert` | `@refactoring-expert` | 기본 | **Martin Fowler 리팩토링 카탈로그**, Code Smell 식별, 안전한 단계별 리팩토링 |
| `code-refactorer` | `@code-refactorer` | 기본 | 기능 유지하면서 코드 구조 개선 |
| `code-review-expert` | `@code-review-expert` | 기본 | 체계적 코드 리뷰 (보안/성능/품질/유지보수성, Spring-JPA 포함) |
| `ddd-expert` | `@ddd-expert` | 기본 | **Domain-Driven Design** (Bounded Context, Aggregate, Entity/Value Object, Domain Events) + OOP/SOLID 원칙 |

> 참고: `ddd-expert`의 파일명은 `oop-expert.md`이지만, 실제 에이전트 이름은 `ddd-expert`입니다.

### 개발 전문가

| 에이전트 | 호출 | 모델 | 전문 분야 |
|---------|------|------|----------|
| `spring-expert` | `@spring-expert` | 기본 | Spring Boot, Clean/Hexagonal Architecture, JPA, Security |
| `frontend-designer` | `@frontend-designer` | 기본 | 프론트엔드 UI/UX 디자인 → 기술 명세 변환 |
| `vibe-coding-coach` | `@vibe-coding-coach` | 기본 | 대화 기반 앱 개발 (비전 → 코드 변환) |
| `data-scientist` | `@data-scientist` | **haiku** | SQL, BigQuery, 데이터 분석 (경량 모델 — 비용 최적화) |
| `prompt-expert` | `@prompt-expert` | 기본 | 프롬프트 엔지니어링, 프롬프트 최적화 |

### 콘텐츠 & 문서

| 에이전트 | 호출 | 모델 | 전문 분야 |
|---------|------|------|----------|
| `youtube-obsidian-summarizer` | `@youtube-obsidian-summarizer` | **opus** | YouTube → Obsidian 한글 문서 (고품질, 타임스탬프/Zettelkasten 포함) |
| `youtube-summarizer` | `@youtube-summarizer` | 기본 | YouTube 영상 요약 |
| `content-writer` | `@content-writer` | 기본 | 콘텐츠 작성 (아웃라인 → 풀 아티클) |
| `content-translator` | `@content-translator` | 기본 | 기술 콘텐츠 번역 |
| `technical-researcher` | `@technical-researcher` | 기본 | GitHub 프로젝트/API/코드 분석 |

### 프로젝트 관리

| 에이전트 | 호출 | 모델 | 전문 분야 |
|---------|------|------|----------|
| `prd-expert` | `@prd-expert` | 기본 | PRD(Product Requirements Document) 작성 |
| `prd-writer` | `@prd-writer` | 기본 | PRD 작성 (상세 버전) |
| `project-task-planner` | `@project-task-planner` | 기본 | PRD → 개발 태스크 리스트 변환 |

### Obsidian 지식관리

| 에이전트 | 호출 | 모델 | 전문 분야 |
|---------|------|------|----------|
| `zettelkasten-expert` | `@zettelkasten-expert` | 기본 | Zettelkasten 방법론 (INBOX→RESOURCES→SLIPBOX) |
| **Obsidian Ops Team** (다중 에이전트) | | | |
| `moc-agent` | 자동 | 기본 | Maps of Content 생성/관리 |
| `tag-agent` | 자동 | 기본 | 태그 정규화/계층 구조화 |
| `connection-agent` | 자동 | 기본 | 노트 간 연결 관계 분석/제안 |
| `metadata-agent` | 자동 | 기본 | 프론트매터 표준화/메타데이터 추가 |
| `review-agent` | 자동 | 기본 | 일관성 교차 검증 |

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
| `using-superpowers` | 자동 (세션 시작 시) | 스킬 사용법 가이드 |

### Code Review

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `code-review` | `/code-review:code-review` | PR 코드 리뷰 수행 |

### Feature Dev

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `feature-dev` | `/feature-dev:feature-dev` | 코드베이스 이해 기반 피처 개발 가이드 |

### Code Simplifier

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `simplify` | `/simplify` | 변경된 코드의 재사용성, 품질, 효율성 리뷰 및 개선 |

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

### Notion

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `find` | `/Notion:find` | 제목 키워드로 페이지/데이터베이스 검색 |
| `search` | `/Notion:search` | Notion 워크스페이스 전체 검색 |
| `create-page` | `/Notion:create-page` | 새 Notion 페이지 생성 |
| `create-task` | `/Notion:create-task` | 태스크 데이터베이스에 새 태스크 생성 |
| `create-database-row` | `/Notion:create-database-row` | 데이터베이스에 새 행 삽입 |
| `database-query` | `/Notion:database-query` | 데이터베이스 쿼리 및 구조화된 결과 반환 |
| `tasks:plan` | `/Notion:tasks:plan` | Notion 페이지 URL에서 태스크 계획 |
| `tasks:build` | `/Notion:tasks:build` | Notion 페이지 URL에서 태스크 구현 |
| `tasks:explain-diff` | `/Notion:tasks:explain-diff` | 코드 변경사항을 Notion 문서로 설명 |
| `tasks:setup` | `/Notion:tasks:setup` | Notion 태스크 보드 설정 |

### msbaek-tdd

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `tdd-rgb` | `/msbaek-tdd:tdd-rgb` | TDD RGB 사이클 진행 (Red/Green/Blue agent 순차 위임) |
| `tdd` | `/msbaek-tdd:tdd` | TDD 오케스트레이터 — 프로젝트 생성 및 워크플로우 안내 |
| `tdd-plan` | `/msbaek-tdd:tdd-plan` | TDD Planning — SRS, 예제, 테스트 목록 작성 |

### GitHub

| 스킬 | 사용법 | 설명 |
|------|--------|------|
| `gh` | `/gh` | GitHub CLI 작업 시 자동 적용 (PR, issue, release, GitHub 자동화) |

### 출력 스타일

| 플러그인 | 설명 |
|---------|------|
| `explanatory-output-style` | 설명형 출력 — 교육적 인사이트와 함께 작업 수행 |
| `learning-output-style` | 학습형 출력 — 사용자 코드 기여 요청 + 교육적 설명 결합 |

### 기타 플러그인

| 플러그인 | 설명 |
|---------|------|
| `security-guidance` | 보안 관련 작업 시 OWASP 기반 가이드라인 적용 |
| `greptile` | 코드 검색 강화 (코드베이스 인덱싱 기반) |
| `serena` | LSP 기반 시맨틱 코드 탐색 (MCP 서버) |
| `playwright` | 브라우저 자동화 (MCP 서버) |

---

## 6. 훅 (Hooks)

### 현재 활성화된 훅

| 이벤트 | 트리거 | 동작 |
|--------|--------|------|
| **PreToolUse** (`*`) | 모든 도구 실행 시 | 크로스 플랫폼 알림 via `notify.sh` ("도구 실행 준비 중: [도구명]") |
| **PreToolUse** (`bash`) | Bash 명령 실행 시 | 명령어 + 설명을 `~/.claude/bash-command-log.txt`에 로깅 |
| **Stop** | 응답 완료 시 | 크로스 플랫폼 알림 ("Claude 응답이 완료되었습니다") |
| **Notification** (`permission_prompt`) | 권한 요청 시 | "Permission required" 알림 |
| **Notification** (`idle_prompt`) | 입력 대기 시 | "Waiting for input" 알림 |
| **UserPromptSubmit** | 프롬프트 제출 시 | `-u` 플래그 감지 → ultrathink 사용 지시문 자동 추가 |

> 알림 스크립트(`notify.sh`)가 OS를 자동 감지합니다:
> - macOS: `terminal-notifier` (기본 사운드) 또는 `osascript` (Ping 사운드)
> - Linux: `notify-send`

### Ultra-Think 모드 사용법

프롬프트 끝에 `-u`를 추가하면 ultrathink 지시문이 자동 추가됩니다:

```
이 코드를 리팩토링해줘 -u
```

### 보안 훅 스크립트

| 스크립트 | 위치 | 검사 내용 |
|---------|------|----------|
| `check-env-files.sh` | `~/.claude/hooks/` | `.env` 파일 커밋 방지 (`.env.*.example` 허용) |
| `check-sensitive-files.sh` | `~/.claude/hooks/` | `.pem, .key, .p12, .pfx, .jks, .crt, .cer` 파일 차단 |
| `check-hardcoded-paths.sh` | `~/.claude/hooks/` | 하드코딩된 사용자 경로 방지 (`$HOME` 또는 `~` 사용 강제) |
| `update-brewfile.sh` | `~/.claude/hooks/` | 커밋 전 Brewfile 자동 동기화 (macOS) |

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
| `ctrl+v` | Chat | 이미지 붙여넣기 |
| `ctrl+g` | Chat | 외부 에디터에서 편집 |
| `ctrl+_` / `ctrl+shift+-` | Chat | 실행 취소 (undo) |
| `shift+tab` | Chat | 모드 순환 |
| `escape` | Chat | 취소 |
| `ctrl+t` | Global | 투두 리스트 토글 |
| `ctrl+o` | Global | 트랜스크립트 토글 |
| `ctrl+shift+o` | Global | 팀메이트 프리뷰 토글 |
| `ctrl+r` | Global | 히스토리 검색 |

### 승인/거부 (Confirmation)

| 키 | 동작 |
|----|------|
| `y` / `enter` | 승인 |
| `n` / `escape` | 거부 |
| `up` / `down` | 이전/다음 옵션 |
| `tab` | 다음 필드 |
| `space` | 토글 |
| `shift+tab` | 모드 순환 |
| `ctrl+e` | 설명 토글 |

### 자동완성 (Autocomplete)

| 키 | 동작 |
|----|------|
| `tab` | 수락 |
| `escape` | 닫기 |
| `up` / `down` | 이전/다음 제안 |

### 설정/선택 (Settings/Select)

| 키 | 동작 |
|----|------|
| `j` / `down` / `ctrl+n` | 다음 항목 |
| `k` / `up` / `ctrl+p` | 이전 항목 |
| `enter` / `space` | 선택 |
| `escape` | 취소 |
| `/` | 설정 검색 |
| `r` | 재시도 |

### DiffDialog

| 키 | 동작 |
|----|------|
| `left` / `right` | 이전/다음 소스 |
| `up` / `down` | 이전/다음 파일 |
| `enter` | 상세 보기 |
| `escape` | 닫기 |

### MessageSelector

| 키 | 동작 |
|----|------|
| `j` / `down` | 다음 메시지 |
| `k` / `up` | 이전 메시지 |
| `shift+j` / `shift+down` / `ctrl+down` / `meta+down` | 맨 아래 |
| `shift+k` / `shift+up` / `ctrl+up` / `meta+up` | 맨 위 |
| `enter` | 선택 |

### ModelPicker

| 키 | 동작 |
|----|------|
| `left` | Effort 감소 |
| `right` | Effort 증가 |

### 기타

| 컨텍스트 | 키 | 동작 |
|---------|---|------|
| Task | `ctrl+b` | 태스크 백그라운드 실행 |
| Plugin | `space` | 플러그인 토글 |
| Plugin | `i` | 플러그인 설치 |
| Tabs | `tab` / `right` | 다음 탭 |
| Tabs | `shift+tab` / `left` | 이전 탭 |
| Transcript | `ctrl+e` | 전체 표시 토글 |
| Transcript | `escape` | 나가기 |
| HistorySearch | `ctrl+r` | 다음 결과 |
| HistorySearch | `tab` / `escape` | 수락 |
| HistorySearch | `enter` | 실행 |
| ThemePicker | `ctrl+t` | 구문 강조 토글 |
| Help | `escape` | 닫기 |
| Attachments | `left` / `right` | 이전/다음 첨부 |
| Attachments | `backspace` / `delete` | 첨부 삭제 |
| Footer | `left` / `right` | 이전/다음 |
| Footer | `enter` | 선택 열기 |

---

## 8. CLAUDE.md 규칙 레퍼런스

CLAUDE.md에 정의된 주요 규칙과 가이드라인입니다. Claude Code 세션 시작 시 자동으로 적용됩니다.

### 코드 조사 (Code Investigation)

| 규칙 | 설명 |
|------|------|
| `investigate_before_answering` | 코드를 열어보지 않고 추측 금지. 파일을 먼저 읽고 답변 |
| `root_cause_analysis` | 증상 패치(symptom patching) 금지. 근본 원인(root cause)을 추적한 후 수정. 시니어 개발자 기준 적용 |

### 품질 관리 (Quality Control)

| 규칙 | 설명 |
|------|------|
| `avoid_overengineering` | 요청된 것만 구현. 불필요한 기능/리팩토링/추상화 금지 |
| `avoid_hardcoding_for_tests` | 테스트 케이스에 맞춘 하드코딩 금지. 범용 알고리즘 구현 |
| `reduce_file_creation` | 임시 파일 생성 시 작업 완료 후 삭제 |
| `elegance_check` | 50줄 이상 변경 또는 새 추상화(abstraction) 도입 시, "더 우아한 방법이 있는가?" 자문 후 진행. 단순한 수정은 스킵 |

### 장기 실행 태스크 (Long-running Tasks)

| 규칙 | 설명 |
|------|------|
| `context_persistence` | 컨텍스트 한계와 무관하게 작업 완료. ~80% 활용 시 anchored iterative summarization 적용 (Session Intent / Files Modified / Decisions Made / Current State / Next Steps) |
| `state_management` | 구조화 정보는 JSON, 자유 형식은 progress.txt, 이력 추적은 git 사용 |
| `output_offloading` | 2KB 초과 도구 출력(tool output)은 파일로 저장 후 경로+요약만 반환. `.claude/scratch/` 또는 `/tmp/` 사용, 세션 종료 시 정리 |
| `context_health` | 장기 세션 중 성능 저하 신호(degradation signal) 모니터링: Poisoning (도구 오정렬, 반복 실수) → 컨텍스트 절단 / Distraction (무관한 검색 결과) → 필터링 강화 / Confusion (무관한 작업 혼합) → 서브에이전트 격리 |

### 협업 패턴 (Collaboration Patterns)

| 규칙 | 설명 |
|------|------|
| `active_partner` | 묵묵히 따르지 않기. 불명확한 지시에 반박, 잘못된 가정에 도전 |
| `check_alignment_first` | 구현 전 이해도 확인. 5분 정렬(alignment)이 1시간 잘못된 코딩보다 효율적 |
| `noise_cancellation` | 간결하게. 불필요한 반복/설명/서두 제거. 지식 문서 정기 압축 |
| `offload_deterministic` | AI에게 결정적(deterministic) 작업 직접 시키지 않기. 카운팅, 파싱 등은 스크립트 작성하여 실행 |

### 작업 완료 검증 (Verification)

작업 완료 전 체크리스트:

```
- [ ] 모든 테스트 통과
- [ ] Plan/todo 문서에 완료 상태 반영
- [ ] main과의 diff 동작 확인
- [ ] "스태프 엔지니어가 승인할까?" 자문
- [ ] 폴더별 INDEX.md 업데이트 (resume point, status)
- [ ] 글로벌 INDEX.md 상태 업데이트 (해당 시)
- [ ] 다음 세션을 위한 컨텍스트 기록
- [ ] Git worktree 격리 확인 (해당 시)
```

---

## 9. 환경변수 및 설정 레퍼런스

### 환경변수

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

### 추가 설정

| 설정 | 현재 값 | 설명 |
|------|--------|------|
| `permissions.defaultMode` | `acceptEdits` | 파일 편집 자동 승인 |
| `effortLevel` | `high` | 기본 추론 노력 수준 |
| `spinnerVerbs` | 한국어 동사 목록 | 로딩 스피너에 한국어 표시 ("분석 중...", "탐색 중..." 등) |

---

## 빠른 참조 카드

```
[일상]
/daily-work-logger                 어제 작업 정리
/wrap-up [주제] [--format ...]     오늘 세션 요약
/commit [--push] [--amend]         커밋 생성
/weekly-claude-analytics           주간 통계
/weekly-newsletter                 주간 뉴스레터
/agf list [YYYY-MM-DD]             세션 리스트
/agf search [--deep] <쿼리>        세션 검색
/agf show <세션ID>                  세션 상세 분석

[개발]
/check-security                    보안 스캔
/project-overview [--depth ...]    프로젝트 분석
/conventional-review <코멘트>       리뷰 코멘트 변환
/markitdown-convert <파일>          파일→Markdown
/meeting-minutes [날짜] [녹취록]    회의록 생성
/coffee-time [날짜] [내용]          커피타임 정리

[Augmented Coding]
/augmented:cast-wide               대안 탐색
/augmented:parallel-impl           병렬 구현
/augmented:happy-to-delete         코드 폐기
/augmented:softest-prototype       마크다운 프로토타입
/augmented:mind-dump               사고 구조화
/augmented:reverse-direction       AI에게 질문 위임
/augmented:refinement-loop         반복 품질 개선

[TDD]
/tdp:add-test-for-boundary-values  경계값 테스트
/tdp:add-test-for-change-later     변경 대비 테스트
/tdp:add-test-for-misbehaves       오작동 테스트
/tdp:add-test-for-side-effects     부작용 테스트
/msbaek-tdd:tdd-rgb                TDD RGB 사이클
/msbaek-tdd:tdd-plan               TDD 계획

[Obsidian]
/obsidian:summarize-youtube [kr|en] [URL]
/obsidian:summarize-article [URL]
/obsidian:translate-youtube [URL]
/obsidian:translate-article [URL]
/obsidian:add-tag [파일]
/obsidian:vault-query [질문]
/obsidian:batch-process
vis search "키워드" [--rerank]
vis collect "주제" [--tag]
vis generate-moc "주제"

[에이전트]
@spring-expert            Spring 질문
@code-review-expert       코드 리뷰
@kent-beck-expert         Tidy First
@refactoring-expert       리팩토링
@ddd-expert               DDD/OOP 설계
@data-scientist           데이터 분석 (haiku)
@youtube-obsidian-summarizer  YouTube 요약 (opus)

[GitLab (glab)]
glab mr create --fill           MR 생성
glab mr list --reviewer @me     리뷰 요청 MR
glab ci status                  파이프라인 상태
glab ci trace                   Job 로그 확인
glab mr merge --squash          스쿼시 머지

[Superpowers]
/superpowers:brainstorming            아이디어 탐색
/superpowers:test-driven-development  TDD
/superpowers:systematic-debugging     디버깅
/superpowers:writing-plans            계획 작성
/superpowers:executing-plans          계획 실행

[Atlassian]
/atlassian:triage-issue               이슈 트리아지
/atlassian:spec-to-backlog            스펙→백로그
/atlassian:generate-status-report     상태 리포트

[Notion]
/Notion:search                        워크스페이스 검색
/Notion:create-task                   태스크 생성
/Notion:tasks:plan                    태스크 계획
/Notion:tasks:build                   태스크 구현

[키보드]
meta+p  모델 선택    meta+o  패스트모드
meta+t  씽킹 토글   ctrl+s  스태시
ctrl+q  스니펫      ctrl+v  이미지 붙여넣기
ctrl+g  외부 에디터  ctrl+t  투두 토글
ctrl+o  트랜스크립트  ctrl+r  히스토리 검색
y/n     승인/거부    j/k     Vim 이동
-u      울트라씽크   ctrl+b  백그라운드
```
