# Claude Code Dotfiles

> Claude Code 개인 설정 파일 관리 레포지토리.
> macOS와 Arch Linux에서 동일한 Claude Code 환경을 빠르게 구성합니다.
>
> 이 dotfiles는 [msbaek/dotfiles](https://github.com/msbaek/dotfiles)를 기반으로 만들어졌습니다.

**포함:** 에이전트 24개 | 커맨드 35개 | 스킬 11개 | 플러그인 24개 | 훅 6개

---

## Quick Start

```bash
git clone https://github.com/zionge2k/claude-dotfiles ~/claude-dotfiles
cd ~/claude-dotfiles
./install.sh
```

설치 후 Claude Code를 재시작하면 모든 설정이 적용됩니다.

> **동작 원리:** `install.sh`는 [GNU Stow](https://www.gnu.org/software/stow/)를 사용하여 `~/.claude/`에 심볼릭 링크를 생성합니다.
> 이후 dotfiles 레포에서 파일을 수정하면 `~/.claude/`에 즉시 반영됩니다.
> 새 파일/폴더를 추가한 경우에만 `install.sh`를 재실행하면 됩니다.

---

## 목차

| # | 섹션 | 내용 |
|---|------|------|
| 1 | [설치](#1-설치) | 요구사항, 설치 옵션, 플러그인 목록 |
| 2 | [포함 내용](#2-포함-내용) | 에이전트, 커맨드, 스킬, 훅 |
| 3 | [커스터마이징](#3-커스터마이징) | 경로, 환경변수, 키바인딩 |
| 4 | [문제 해결](#4-문제-해결) | Stow 충돌, 플러그인, 알림 |
| 5 | [빠른 참조 카드](#5-빠른-참조-카드) | 자주 쓰는 명령 요약 |

---

## 1. 설치

### 설치 옵션

```bash
./install.sh                # 전체 설치 (의존성 + dotfiles + 플러그인)
./install.sh --no-plugins   # 플러그인 제외 (dotfiles만 배포)
./install.sh --plugins-only # 플러그인만 설치
```

### 설치 과정

```
1. 의존성 설치    OS 감지 → brew/pacman으로 stow, jq, node, 알림 도구 설치
2. 기존 설정 백업  ~/.claude/ → ~/.claude.backup.{timestamp}/
3. Stow 배포      stow --no-folding → ~/.claude/에 심볼릭 링크 생성
4. 플러그인 설치   3개 마켓플레이스 + 24개 플러그인
```

<details>
<summary><b>사전 요구사항</b></summary>

| 항목 | 설명 |
|------|------|
| [Claude Code](https://claude.ai/code) | CLI 설치 필요 (플러그인 설치 시) |
| Git | 레포 클론용 |

`install.sh`가 나머지 의존성(stow, jq, node, 알림 도구)을 자동 설치합니다.

</details>

<details>
<summary><b>설치되는 플러그인 (24개)</b></summary>

**공식 (19개):** superpowers, feature-dev, code-review, code-simplifier, pr-review-toolkit, frontend-design, github, playwright, serena, security-guidance, atlassian, plugin-dev, hookify, claude-md-management, greptile, explanatory-output-style, learning-output-style, playground, Notion

**LSP (4개):** jdtls (Java), kotlin-lsp, vtsls (TS/JS), pyright (Python)

**서드파티 (1개):** msbaek-tdd (TDD RGB 사이클)

</details>

---

## 2. 포함 내용

### 디렉토리 구조

```
claude-dotfiles/
├── install.sh                    # 설치 스크립트
└── .claude/
    ├── CLAUDE.md                 # 글로벌 지시사항
    ├── settings.json             # 환경변수, 훅, 플러그인
    ├── keybindings.json          # 키바인딩
    ├── agents/          (24개)   # 커스텀 에이전트
    ├── commands/        (35개)   # 슬래시 커맨드
    ├── skills/          (11개)   # 직접 만든 스킬
    ├── hooks/            (6개)   # 알림 + 보안 검사
    └── docs/                     # SKILLS-GUIDE.md 등 가이드 문서
```

### 스킬 (11개)

자동 감지 방식. 관련 키워드를 언급하면 활성화됩니다.

| 스킬 | 트리거 | 설명 |
|------|--------|------|
| `agf` | "세션 목록", "agf" | AI Agent Session Finder — 세션 리스트/검색/상세분석 |
| `prompt-contracts` | brainstorming, planning | Goal/Constraints/Format/Failure Conditions 프레임워크 |
| `daily-work-logger` | "어제 작업 정리해줘" | 4개 서브에이전트 병렬 분석 → Daily Note |
| `weekly-claude-analytics` | "주간 분석" | 주간 세션 로그 분석 리포트 |
| `weekly-newsletter` | "뉴스레터 만들어줘" | 주간 뉴스레터 생성 |
| `project-time-tracker` | "시간 추적" | 프로젝트별 세션 시간 집계 |
| `usage-pattern-analyzer` | "패턴 분석" | 도구 사용 빈도/생산성 시각화 |
| `learning-tracker` | "학습 정리", "TIL" | 학습 내용 추출 → TIL 문서 |
| `obsidian-vault` | Obsidian 관련 작업 | markdown-oxide LSP 연동 |
| `vis` | 시맨틱 검색 | Vault Intelligence System (19개 CLI 명령어) |
| `brunch-writer` | "브런치", "글 작성" | 브런치 블로그 글 작성 |

### 훅 & 보안 (6개)

| 파일 | 동작 |
|------|------|
| `notify.sh` | 크로스 플랫폼 데스크톱 알림 (PreToolUse, Stop) |
| `UserPromptSubmit/` | `-u` 감지 → ultra-think 모드 |
| `check-env-files.sh` | `.env` 파일 커밋 방지 |
| `check-sensitive-files.sh` | `.pem, .key, .p12` 등 차단 |
| `check-hardcoded-paths.sh` | 하드코딩 경로 방지 |
| `update-brewfile.sh` | 커밋 전 Brewfile 동기화 |

<details>
<summary><b>에이전트 (24개)</b></summary>

**코드 품질**
- `@kent-beck-expert` — Tidy First, Simple Design
- `@refactoring-expert` — Martin Fowler 리팩토링 카탈로그
- `@code-refactorer` — 코드 구조 개선
- `@code-review-expert` — 체계적 코드 리뷰
- `@oop-expert` — SOLID, Design Patterns (name: ddd-expert)

**개발**
- `@spring-expert` — Spring Boot, JPA, Security
- `@frontend-designer` — UI/UX → 기술 명세
- `@vibe-coding-coach` — 대화 기반 앱 개발
- `@data-scientist` — SQL, BigQuery, 데이터 분석 (haiku)
- `@prompt-expert` — 프롬프트 엔지니어링

**콘텐츠**
- `@youtube-obsidian-summarizer` — YouTube → Obsidian 문서 (opus)
- `@youtube-summarizer` — YouTube 요약
- `@content-writer` — 아웃라인 → 아티클
- `@content-translator` — 기술 콘텐츠 번역
- `@technical-researcher` — GitHub/API 분석

**프로젝트**
- `@prd-expert` / `@prd-writer` — PRD 작성
- `@project-task-planner` — PRD → 태스크 리스트

**Obsidian (5개 팀 에이전트)**
- `@zettelkasten-expert` — Zettelkasten 방법론
- `moc-agent` / `tag-agent` / `connection-agent` / `metadata-agent` / `review-agent`

</details>

<details>
<summary><b>슬래시 커맨드 (35개)</b></summary>

**개발 (11개)**

| 커맨드 | 설명 |
|--------|------|
| `/commit` | Conventional Commits 자동 생성 (한국어 인코딩 처리) |
| `/wrap-up` | 세션 작업 요약 저장 |
| `/check-security` | OWASP 기반 보안 스캔 |
| `/update-claude-md` | CLAUDE.md 인터랙티브 업데이트 |
| `/project-overview` | 프로젝트 구조 분석 |
| `/conventional-review` | Conventional Comments 변환 |
| `/my-developer` | 개발 계획 피드백 |
| `/meeting-minutes` | 녹취록 → 회의록 |
| `/coffee-time` | 커피타임 대화 정리 → GitHub |
| `/markitdown-convert` | 파일 → Markdown 변환 |
| `/askUserQuestion` | 인터랙티브 코드 어시스턴트 |

**Augmented Coding (7개)** — [lexler.github.io](https://lexler.github.io) 기반

| 커맨드 | 설명 |
|--------|------|
| `/augmented:cast-wide` | 3개+ 대안 탐색 강제 |
| `/augmented:parallel-impl` | Git worktree 병렬 구현 |
| `/augmented:happy-to-delete` | 코드 폐기 결정 지원 |
| `/augmented:softest-prototype` | 마크다운 프로토타이핑 |
| `/augmented:mind-dump` | 사고 구조화 |
| `/augmented:reverse-direction` | AI에게 제안/질문 위임 |
| `/augmented:refinement-loop` | 반복적 품질 개선 |

**Obsidian (13개)**

| 커맨드 | 설명 |
|--------|------|
| `/obsidian:summarize-youtube` | YouTube → Obsidian 요약 |
| `/obsidian:translate-youtube` | YouTube 번역 → Obsidian |
| `/obsidian:summarize-article` | 기술 문서 → Obsidian 요약 |
| `/obsidian:translate-article` | 기술 문서 번역 → Obsidian |
| `/obsidian:add-tag` | 계층적 태그 자동 부여 |
| `/obsidian:add-tag-and-move-file` | 태그 + 디렉토리 이동 |
| `/obsidian:batch-process` | Vault 대량 처리 |
| `/obsidian:batch-summarize-urls` | URL 목록 병렬 요약 |
| `/obsidian:vault-query` | VIS 기반 검색 |
| `/obsidian:related-contents` | 관련 노트 자동 생성 |
| `/obsidian:create-presentation` | Advanced Slides 변환 |
| `/obsidian:weekly-social-posts` | 소셜 미디어 포스트 생성 |
| `/obsidian:tagging-example` | 태그 부여 예시 |

**TDD (4개)**

| 커맨드 | 설명 |
|--------|------|
| `/tdp:add-test-for-boundary-values` | 경계값 테스트 |
| `/tdp:add-test-for-change-later` | 미래 변경 대비 테스트 |
| `/tdp:add-test-for-misbehaves` | 오작동 테스트 |
| `/tdp:add-test-for-side-effects` | 부작용 테스트 |

</details>

---

## 3. 커스터마이징

### Obsidian Vault 경로

`obsidian-ops-team` 에이전트들이 `~/Documents/zion-vault/` 경로를 참조합니다.
Vault 경로가 다르면 해당 파일들을 수정하세요:

```bash
grep -rl "zion-vault" .claude/agents/
```

### 환경변수

`settings.json`의 `env` 섹션에서 조정:

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `MAX_THINKING_TOKENS` | `16000` | 확장 사고 최대 토큰 |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `16384` | 최대 출력 토큰 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `claude-sonnet-4-5-20250929` | 서브에이전트 모델 |
| `BASH_DEFAULT_TIMEOUT_MS` | `120000` | Bash 기본 타임아웃 (2분) |

### 키바인딩

`keybindings.json`에서 수정. 주요 단축키:

```
meta+p  모델 피커          meta+o  패스트 모드
meta+t  씽킹 토글          ctrl+s  대화 스태시
ctrl+q  스니펫 피커         ctrl+t  투두 토글
y / n   빠른 승인/거부      j / k   Vim 스타일 이동
```

---

## 4. 문제 해결

<details>
<summary><b>Stow 충돌</b></summary>

```bash
# 기존 파일이 심링크가 아닌 경우 충돌 발생
# 해결: 백업 후 기존 파일 삭제
mv ~/.claude/settings.json ~/.claude/settings.json.bak
cd ~/claude-dotfiles && stow --no-folding -t "$HOME" -v .
```

</details>

<details>
<summary><b>플러그인 설치 실패</b></summary>

```bash
# Claude Code CLI 확인
which claude

# 개별 플러그인 수동 설치
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install superpowers@claude-plugins-official
```

</details>

<details>
<summary><b>알림이 안 되는 경우</b></summary>

```bash
# macOS
which terminal-notifier || brew install terminal-notifier

# Arch Linux
which notify-send || sudo pacman -S libnotify
```

</details>

<details>
<summary><b>새 머신에서 빠른 설정</b></summary>

```bash
git clone https://github.com/zionge2k/claude-dotfiles ~/claude-dotfiles
cd ~/claude-dotfiles && ./install.sh
# Claude Code 재시작 → claude auth 실행
```

</details>

---

## 5. 빠른 참조 카드

```
[설치]
git clone ... ~/claude-dotfiles    레포 클론
./install.sh                       전체 설치
./install.sh --no-plugins          dotfiles만
./install.sh --plugins-only        플러그인만

[일상 워크플로우]
/daily-work-logger                 어제 작업 정리
/commit [--push]                   커밋 생성
/wrap-up                           세션 요약 저장
/check-security                    보안 스캔
/agf list                          오늘 세션 리스트

[상세 가이드]
.claude/docs/SKILLS-GUIDE.md       종합 사용 가이드
.claude/docs/JAVA-APP-GUIDE.md     Java 개발 가이드
```

---

## 크로스 플랫폼 지원

| 기능 | macOS | Arch Linux |
|------|-------|------------|
| 패키지 관리 | Homebrew | pacman |
| 알림 | terminal-notifier | notify-send |
| 심링크 | GNU Stow | GNU Stow |

> `hooks/notify.sh`가 `uname -s`로 OS를 감지하여 적절한 알림 도구를 자동 선택합니다.

## 제외 항목

다음은 `.gitignore`로 제외됩니다 (런타임 데이터):

`.credentials.json` | `settings.local.json` | `plugins/` | `projects/` | `history.jsonl` | `plans/` | `todos/` | `tasks/` | `teams/` | 외부 스킬 (gh, jira 등)
