# Claude Code Dotfiles

> Claude Code 개인 설정 파일 관리 레포지토리.
> macOS와 Arch Linux에서 동일한 Claude Code 환경을 빠르게 구성합니다.

---

## 목차

1. [Quick Start](#1-quick-start)
2. [사전 요구사항](#2-사전-요구사항)
3. [설치 옵션](#3-설치-옵션)
4. [포함 내용](#4-포함-내용)
5. [크로스 플랫폼 지원](#5-크로스-플랫폼-지원)
6. [커스터마이징](#6-커스터마이징)
7. [제외 항목](#7-제외-항목)
8. [문제 해결](#8-문제-해결)
9. [빠른 참조 카드](#9-빠른-참조-카드)

---

## 1. Quick Start

```bash
git clone https://github.com/zionge2k/claude-dotfiles ~/claude-dotfiles
cd ~/claude-dotfiles
./install.sh
```

설치 후 Claude Code를 재시작하면 모든 설정이 적용됩니다.

---

## 2. 사전 요구사항

### 필수

| 항목 | 설명 |
|------|------|
| [Claude Code](https://claude.ai/code) | CLI 설치 필요 (플러그인 설치 시) |
| Git | 레포 클론용 |

### 자동 설치되는 의존성

| 도구 | macOS (Homebrew) | Arch Linux (pacman) | 용도 |
|------|-----------------|---------------------|------|
| GNU Stow | `brew install stow` | `pacman -S stow` | 심링크 기반 dotfiles 배포 |
| jq | `brew install jq` | `pacman -S jq` | JSON 처리 |
| Node.js | `brew install node` | `pacman -S nodejs npm` | 일부 스킬 의존성 |
| 알림 도구 | `brew install terminal-notifier` | `pacman -S libnotify` | 데스크톱 알림 |

> `install.sh`가 OS를 감지하여 자동으로 설치합니다.

---

## 3. 설치 옵션

```bash
./install.sh                # 전체 설치 (의존성 + dotfiles + 플러그인)
./install.sh --no-plugins   # 플러그인 제외 (dotfiles만 배포)
./install.sh --plugins-only # 플러그인만 설치 (dotfiles 이미 배포된 경우)
```

### 설치 과정

| 단계 | 동작 | 비고 |
|------|------|------|
| 1. 의존성 설치 | OS 감지 → brew/pacman으로 도구 설치 | `--plugins-only` 시 건너뜀 |
| 2. 기존 설정 백업 | `~/.claude/` 존재 시 → `~/.claude.backup.{timestamp}/` | 설정 파일만 백업 (런타임 데이터 제외) |
| 3. Stow 배포 | `stow --no-folding` → `~/.claude/`에 심링크 생성 | 런타임 디렉토리와 공존 가능 |
| 4. 플러그인 설치 | 3개 마켓플레이스 등록 + 24개 플러그인 설치 | `--no-plugins` 시 건너뜀 |

### 설치되는 플러그인 (24개)

**공식 플러그인 (19개)**

| 플러그인 | 설명 |
|---------|------|
| `superpowers` | 개발 워크플로우 프레임워크 (brainstorming, TDD, debugging 등 13개 스킬) |
| `feature-dev` | 코드베이스 이해 기반 피처 개발 |
| `code-review` | PR 코드 리뷰 |
| `code-simplifier` | 코드 간소화/리팩토링 |
| `pr-review-toolkit` | 전문 에이전트 기반 종합 PR 리뷰 |
| `frontend-design` | 프로덕션급 프론트엔드 인터페이스 생성 |
| `github` | GitHub 통합 |
| `playwright` | 브라우저 자동화 (MCP) |
| `serena` | LSP 기반 시맨틱 코드 탐색 (MCP) |
| `security-guidance` | 보안 가이드라인 |
| `atlassian` | Jira/Confluence 통합 |
| `plugin-dev` | 플러그인 개발 도구 |
| `hookify` | 대화 분석 기반 훅 자동 생성 |
| `claude-md-management` | CLAUDE.md 감사/개선 |
| `greptile` | 코드 검색 강화 |
| `explanatory-output-style` | 설명형 출력 스타일 |
| `learning-output-style` | 학습형 출력 스타일 |
| `playground` | 인터랙티브 HTML 플레이그라운드 |
| `Notion` | Notion 통합 |

**LSP 플러그인 (4개)**

| 플러그인 | 지원 언어 |
|---------|----------|
| `jdtls` | Java |
| `kotlin-lsp` | Kotlin |
| `vtsls` | TypeScript/JavaScript |
| `pyright` | Python |

**서드파티 (1개)**

| 플러그인 | 설명 |
|---------|------|
| `msbaek-tdd` | TDD RGB 사이클 (Red/Green/Blue) |

---

## 4. 포함 내용

### 디렉토리 구조

```
claude-dotfiles/
├── install.sh                    # 설치 스크립트
├── README.md                     # 이 파일
└── .claude/
    ├── CLAUDE.md                 # 글로벌 지시사항
    ├── settings.json             # 환경변수, 훅, 플러그인 설정
    ├── keybindings.json          # 키바인딩
    ├── agents/                   # 커스텀 에이전트 (24개)
    │   └── obsidian-ops-team/    # Obsidian 멀티 에이전트 (5개)
    ├── commands/                 # 슬래시 커맨드 (35개)
    │   ├── augmented/            # AI 페어프로그래밍 패턴 (7개)
    │   ├── obsidian/             # Obsidian 지식관리 (13개)
    │   └── tdp/                  # TDD 테스트 패턴 (4개)
    ├── skills/                   # 직접 만든 스킬 (9개)
    ├── hooks/                    # 알림 + 보안 검사 스크립트
    ├── docs/                     # 가이드 문서
    │   ├── SKILLS-GUIDE.md       # 종합 사용 가이드 (★ 필독)
    │   ├── JAVA-APP-GUIDE.md     # Java 앱 개발 가이드
    │   └── snippets.md           # 코드 스니펫
    └── README.md                 # 워크북 (빠른 참조 카드)
```

### 에이전트 (24개)

| 카테고리 | 에이전트 | 호출 | 설명 |
|---------|---------|------|------|
| **코드 품질** | `kent-beck-expert` | `@kent-beck-expert` | Tidy First, Simple Design |
| | `refactoring-expert` | `@refactoring-expert` | Martin Fowler 리팩토링 카탈로그 |
| | `code-refactorer` | `@code-refactorer` | 코드 구조 개선 |
| | `code-review-expert` | `@code-review-expert` | 체계적 코드 리뷰 |
| | `oop-expert` | `@oop-expert` | SOLID, Design Patterns |
| **개발** | `spring-expert` | `@spring-expert` | Spring Boot, JPA, Security |
| | `frontend-designer` | `@frontend-designer` | UI/UX → 기술 명세 |
| | `vibe-coding-coach` | `@vibe-coding-coach` | 대화 기반 앱 개발 |
| | `data-scientist` | `@data-scientist` | SQL, BigQuery, 데이터 분석 |
| | `prompt-expert` | `@prompt-expert` | 프롬프트 엔지니어링 |
| **콘텐츠** | `youtube-obsidian-summarizer` | `@youtube-obsidian-summarizer` | YouTube → Obsidian 문서 |
| | `youtube-summarizer` | `@youtube-summarizer` | YouTube 요약 |
| | `content-writer` | `@content-writer` | 아웃라인 → 아티클 |
| | `content-translator` | `@content-translator` | 기술 콘텐츠 번역 |
| | `technical-researcher` | `@technical-researcher` | GitHub/API 분석 |
| **프로젝트** | `prd-expert` | `@prd-expert` | PRD 작성 |
| | `prd-writer` | `@prd-writer` | PRD 작성 (상세) |
| | `project-task-planner` | `@project-task-planner` | PRD → 태스크 리스트 |
| **Obsidian** | `zettelkasten-expert` | `@zettelkasten-expert` | Zettelkasten 방법론 |
| | `moc-agent` | 자동 | Maps of Content 관리 |
| | `tag-agent` | 자동 | 태그 정규화 |
| | `connection-agent` | 자동 | 노트 연결 분석 |
| | `metadata-agent` | 자동 | 프론트매터 표준화 |
| | `review-agent` | 자동 | 일관성 교차 검증 |

### 슬래시 커맨드 (35개)

| 카테고리 | 커맨드 | 설명 |
|---------|--------|------|
| **개발** | `/commit` | Conventional Commits 자동 생성 (한국어 인코딩 처리) |
| | `/wrap-up` | 세션 작업 요약 저장 |
| | `/check-security` | OWASP 기반 보안 스캔 |
| | `/update-claude-md` | CLAUDE.md 인터랙티브 업데이트 |
| | `/project-overview` | 프로젝트 구조 분석 |
| | `/conventional-review` | Conventional Comments 변환 |
| | `/my-developer` | 개발 계획 피드백 |
| | `/meeting-minutes` | 녹취록 → 회의록 |
| | `/coffee-time` | 커피타임 대화 정리 → GitHub |
| | `/markitdown-convert` | 파일 → Markdown 변환 |
| | `/askUserQuestion` | 인터랙티브 코드 어시스턴트 |
| **Augmented** | `/augmented:cast-wide` | 3개+ 대안 탐색 강제 |
| | `/augmented:parallel-impl` | Git worktree 병렬 구현 |
| | `/augmented:happy-to-delete` | 코드 폐기 결정 지원 |
| | `/augmented:softest-prototype` | 마크다운 프로토타이핑 |
| | `/augmented:mind-dump` | 사고 구조화 |
| | `/augmented:reverse-direction` | AI에게 제안/질문 위임 |
| | `/augmented:refinement-loop` | 반복적 품질 개선 |
| **Obsidian** | `/obsidian:summarize-youtube` | YouTube → Obsidian 요약 |
| | `/obsidian:translate-youtube` | YouTube 번역 → Obsidian |
| | `/obsidian:summarize-article` | 기술 문서 → Obsidian 요약 |
| | `/obsidian:translate-article` | 기술 문서 번역 → Obsidian |
| | `/obsidian:add-tag` | 계층적 태그 자동 부여 |
| | `/obsidian:add-tag-and-move-file` | 태그 + 디렉토리 이동 |
| | `/obsidian:batch-process` | Vault 대량 처리 |
| | `/obsidian:batch-summarize-urls` | URL 목록 병렬 요약 |
| | `/obsidian:vault-query` | VIS 기반 검색 |
| | `/obsidian:related-contents` | 관련 노트 자동 생성 |
| | `/obsidian:create-presentation` | Advanced Slides 변환 |
| | `/obsidian:weekly-social-posts` | 소셜 미디어 포스트 생성 |
| | `/obsidian:tagging-example` | 태그 부여 예시 |
| **TDD** | `/tdp:add-test-for-boundary-values` | 경계값 테스트 |
| | `/tdp:add-test-for-change-later` | 미래 변경 대비 테스트 |
| | `/tdp:add-test-for-misbehaves` | 오작동 테스트 |
| | `/tdp:add-test-for-side-effects` | 부작용 테스트 |

### 스킬 (9개)

| 스킬 | 트리거 | 설명 |
|------|--------|------|
| `daily-work-logger` | "어제 작업 정리해줘" | 5개 서브에이전트 병렬 분석 → Daily Note |
| `weekly-claude-analytics` | "주간 분석" | 주간 세션 로그 분석 리포트 |
| `weekly-newsletter` | "뉴스레터 만들어줘" | 주간 뉴스레터 생성 |
| `project-time-tracker` | "시간 추적" | 프로젝트별 세션 시간 집계 |
| `usage-pattern-analyzer` | "패턴 분석" | 도구 사용 빈도/생산성 시각화 |
| `learning-tracker` | "학습 정리", "TIL" | 학습 내용 추출 → TIL 문서 |
| `obsidian-vault` | Obsidian 관련 작업 | markdown-oxide LSP 연동 |
| `vis` | 시맨틱 검색 | Vault Intelligence System CLI |
| `brunch-writer` | "브런치", "글 작성" | 브런치 블로그 글 작성 |

### 훅 & 보안 스크립트

| 파일 | 이벤트 | 동작 |
|------|--------|------|
| `notify.sh` | PreToolUse, Stop, Notification | 크로스 플랫폼 데스크톱 알림 |
| `UserPromptSubmit/` | 프롬프트 제출 | `-u` 감지 → ultra-think 모드 활성화 |
| `check-env-files.sh` | 보안 | `.env` 파일 커밋 방지 |
| `check-sensitive-files.sh` | 보안 | `.pem, .key, .p12` 등 차단 |
| `check-hardcoded-paths.sh` | 보안 | 하드코딩 경로 방지 (`$HOME`/`~` 강제) |
| `update-brewfile.sh` | macOS | 커밋 전 Brewfile 동기화 |

---

## 5. 크로스 플랫폼 지원

| 기능 | macOS | Arch Linux |
|------|-------|------------|
| 패키지 관리 | Homebrew | pacman |
| 알림 | terminal-notifier / osascript | notify-send (libnotify) |
| 터미널 | Warp, Ghostty, Kitty | Ghostty, Kitty |
| 심링크 | GNU Stow | GNU Stow |
| 알림 스크립트 | `notify.sh` (OS 자동 감지) | `notify.sh` (OS 자동 감지) |

> `hooks/notify.sh`가 `uname -s`로 OS를 감지하여 적절한 알림 도구를 자동 선택합니다.

---

## 6. 커스터마이징

### Obsidian Vault 경로

`obsidian-ops-team` 에이전트들이 `~/Documents/zion-vault/` 경로를 참조합니다.
Vault 경로가 다르면 해당 파일들을 수정하세요:

```bash
grep -rl "zion-vault" .claude/agents/
# 결과: moc-agent.md, tag-agent.md, connection-agent.md, metadata-agent.md
```

### 환경변수

`settings.json`의 `env` 섹션에서 조정 가능한 주요 변수:

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `MAX_THINKING_TOKENS` | `16000` | 확장 사고 최대 토큰 |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `16384` | 최대 출력 토큰 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `claude-sonnet-4-5-20250929` | 서브에이전트 모델 (비용 최적화) |
| `BASH_DEFAULT_TIMEOUT_MS` | `120000` | Bash 기본 타임아웃 (2분) |

### 키바인딩

`keybindings.json`에서 수정 가능. 주요 단축키:

| 키 | 동작 |
|----|------|
| `meta+p` | 모델 피커 (Opus/Sonnet/Haiku) |
| `meta+o` | 패스트 모드 토글 |
| `meta+t` | 씽킹(확장 사고) 토글 |
| `ctrl+s` | 대화 스태시 |
| `ctrl+q` | 스니펫 피커 |
| `ctrl+t` | 투두 리스트 토글 |
| `y` / `n` | 빠른 승인/거부 |
| `j` / `k` | Vim 스타일 이동 |

---

## 7. 제외 항목

다음 파일은 `.gitignore`로 제외됩니다:

| 파일/디렉토리 | 이유 | 복원 방법 |
|-------------|------|----------|
| `.credentials.json` | OAuth 토큰 (민감) | `claude auth` 실행 시 자동 생성 |
| `settings.local.json` | 로컬 퍼미션 | 사용 중 자동 생성 |
| `plugins/` | 플러그인 캐시 | `./install.sh --plugins-only` |
| `projects/` | 프로젝트별 설정 | 프로젝트에서 자동 생성 |
| `history.jsonl` | 대화 히스토리 | 사용 중 자동 생성 |
| `plans/`, `todos/`, `tasks/`, `teams/` | 세션 상태 | 사용 중 자동 생성 |
| 외부 스킬 (gh, jira 등) | 플러그인으로 관리 | `./install.sh --plugins-only` |

---

## 8. 문제 해결

### Stow 충돌

```bash
# 기존 파일이 심링크가 아닌 경우 충돌 발생
# 해결: 백업 후 기존 파일 삭제
mv ~/.claude/settings.json ~/.claude/settings.json.bak
cd ~/claude-dotfiles && stow --no-folding -t "$HOME" -v .
```

### 플러그인 설치 실패

```bash
# Claude Code CLI가 설치되어 있는지 확인
which claude

# 개별 플러그인 수동 설치
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install superpowers@claude-plugins-official
```

### 알림이 안 되는 경우

```bash
# macOS: terminal-notifier 확인
which terminal-notifier || brew install terminal-notifier

# Arch Linux: libnotify 확인
which notify-send || sudo pacman -S libnotify
```

### 새 머신에서 빠른 설정

```bash
# 1. Claude Code 설치
# 2. Dotfiles 클론 + 설치
git clone https://github.com/zionge2k/claude-dotfiles ~/claude-dotfiles
cd ~/claude-dotfiles && ./install.sh
# 3. Claude Code 재시작
# 4. claude auth 실행 (인증)
```

---

## 9. 빠른 참조 카드

```
[설치]
git clone ... ~/claude-dotfiles    레포 클론
./install.sh                       전체 설치
./install.sh --no-plugins          dotfiles만
./install.sh --plugins-only        플러그인만

[상세 가이드]
.claude/docs/SKILLS-GUIDE.md       종합 사용 가이드 (★ 필독)
.claude/README.md                  워크북 (빠른 참조)
.claude/docs/JAVA-APP-GUIDE.md     Java 개발 가이드

[일상 워크플로우]
/daily-work-logger                 어제 작업 정리
/commit                            커밋 생성
/wrap-up                           세션 요약 저장
/check-security                    보안 스캔

[수정이 필요한 경우]
settings.json                      환경변수, 훅 설정
keybindings.json                   키바인딩
agents/obsidian-ops-team/          Vault 경로 (~/Documents/zion-vault/)
```
