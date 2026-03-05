# Keybindings Guide

키보드 중심 워크플로우를 위한 단축키 종합 가이드.
Ghostty → tmux → zsh/fzf → Claude Code 레이어 순으로 정리.

> 업데이트: 2026-03-05

---

## Layer 1: Ghostty (터미널 에뮬레이터)

Ghostty가 최상위 레이어에서 키 입력을 처리. `Cmd` 키 조합은 여기서 소비됨.

### 리더 키 시퀀스 (Cmd+S → ...)

| 키 | 동작 | 비고 |
|----|------|------|
| `Cmd+S → R` | 설정 리로드 | config 파일 수정 후 사용 |
| `Cmd+S → X` | 현재 surface 닫기 | |
| `Cmd+S → N` | 새 윈도우 | |
| `Cmd+S → C` | 새 탭 | |
| `Cmd+S → Shift+L` | 다음 탭 | |

### 기본 단축키 (Cmd 계열)

| 키 | 동작 |
|----|------|
| `Cmd+T` | 새 탭 |
| `Cmd+W` | 현재 surface 닫기 |
| `Cmd+Shift+W` | 윈도우 닫기 |
| `Cmd+N` | 새 윈도우 |
| `Cmd+Q` | 종료 |
| `Cmd+1~9` | 탭 번호로 이동 |
| `Cmd+Shift+]` | 다음 탭 |
| `Cmd+Shift+[` | 이전 탭 |
| `Ctrl+Tab` | 다음 탭 |
| `Ctrl+Shift+Tab` | 이전 탭 |

### 스플릿 관리

| 키 | 동작 |
|----|------|
| `Cmd+Shift+D` | 아래로 스플릿 |
| `Cmd+Shift+Enter` | 스플릿 줌 토글 |
| `Cmd+Alt+↑↓←→` | 스플릿 간 이동 |
| `Cmd+Ctrl+↑↓←→` | 스플릿 크기 조절 |
| `Cmd+Ctrl+=` | 스플릿 균등 분할 |
| `Cmd+[` / `Cmd+]` | 이전/다음 스플릿 |

### 스크롤 & 네비게이션

| 키 | 동작 |
|----|------|
| `Cmd+↑` | 이전 프롬프트로 점프 |
| `Cmd+↓` | 다음 프롬프트로 점프 |
| `Cmd+Home` | 최상단 스크롤 |
| `Cmd+End` | 최하단 스크롤 |
| `Cmd+PageUp/Down` | 페이지 스크롤 |

### 편집 & 기타

| 키 | 동작 |
|----|------|
| `Cmd+C` | 복사 |
| `Cmd+V` | 붙여넣기 |
| `Cmd+A` | 전체 선택 |
| `Cmd+K` | 화면 클리어 |
| `Cmd+=` / `Cmd+-` | 폰트 크기 조절 |
| `Cmd+0` | 폰트 크기 리셋 |
| `Cmd+,` | 설정 파일 열기 |
| `Cmd+Shift+P` | 명령 팔레트 |
| `Cmd+Alt+I` | 인스펙터 토글 |
| `Cmd+Enter` | 전체화면 토글 |

### 비활성화된 키

| 키 | 상태 | 이유 |
|----|------|------|
| `Cmd+D` | unbind | tmux/다른 도구와 충돌 방지 |

---

## Layer 2: tmux (터미널 멀티플렉서)

Ghostty 안에서 실행. prefix 키를 누른 뒤 명령 키를 입력.

### Prefix: `Ctrl+A`

> 기본 tmux prefix인 `Ctrl+B`에서 변경됨. Ghostty의 `Cmd+S` 리더 키와 독립적으로 동작.

### 세션 & 윈도우

| 키 | 동작 |
|----|------|
| `Ctrl+A → S` | 세션 목록 (시간순 정렬) |
| `Ctrl+A → C` | 새 윈도우 |
| `Ctrl+A → ,` | 윈도우 이름 변경 |
| `Ctrl+A → N` | 다음 윈도우 |
| `Ctrl+A → P` | 이전 윈도우 |
| `Ctrl+A → 0~9` | 윈도우 번호로 이동 |
| `Ctrl+A → &` | 윈도우 닫기 |
| `Ctrl+A → $` | 세션 이름 변경 |
| `Ctrl+A → D` | 세션 분리 (detach) |

### 패인 관리

| 키 | 동작 | 비고 |
|----|------|------|
| `Ctrl+A → \|` | 수평 스플릿 | 커스텀 (기본: %) |
| `Ctrl+A → -` | 수직 스플릿 | 커스텀 (기본: ") |
| `Ctrl+A → H/J/K/L` | 패인 크기 조절 | 반복 가능 (-r) |
| `Ctrl+A → M` | 패인 줌 토글 | 반복 가능 (-r) |
| `Ctrl+A → {` / `}` | 패인 위치 교환 (왼/오) | |
| `Ctrl+A → X` | 패인 닫기 | |
| `Ctrl+A → Q` | 패인 번호 표시 | |

### vim-tmux-navigator (플러그인)

tmux 패인과 Neovim 스플릿 간 **매끄러운 이동**.
tmux + Neovim 양쪽에 플러그인 설치 필요 (`~/.config/nvim/lua/plugins/vim-tmux-navigator.lua`).

| 키 | 동작 |
|----|------|
| `Ctrl+H` | 왼쪽 패인/스플릿 |
| `Ctrl+J` | 아래 패인/스플릿 |
| `Ctrl+K` | 위 패인/스플릿 |
| `Ctrl+L` | 오른쪽 패인/스플릿 |
| `Ctrl+\` | 이전 패인/스플릿 |

> vim 안에서도 동작함 (Neovim에 vim-tmux-navigator 플러그인 설치됨)

### 복사 모드 (Vi 스타일)

| 키 | 동작 |
|----|------|
| `Ctrl+A → Y` | 복사 모드 진입 |
| `V` | 선택 시작 (복사 모드 내) |
| `Y` | 선택 복사 (복사 모드 내) |
| `H/J/K/L` | 커서 이동 (복사 모드 내) |
| `Q` / `Esc` | 복사 모드 종료 |

### 기타

| 키 | 동작 |
|----|------|
| `Ctrl+A → R` | 설정 리로드 |
| `Ctrl+A → Shift+D` | 대시보드 팝업 (대문자 D) |

### 플러그인 목록

| 플러그인 | 역할 |
|----------|------|
| vim-tmux-navigator | Vim↔tmux 패인 매끄러운 이동 |
| tmux-resurrect | 세션 저장/복원 |
| tmux-continuum | 자동 저장 (5분 간격) + 자동 복원 |
| tmux-fzf | fzf 기반 tmux 작업 |
| catppuccin/tmux | 테마 (latte) |

---

## Layer 3: Zsh (셸)

### Vi 모드 (`set -o vi`)

| 모드 | 키 | 동작 |
|------|-----|------|
| Insert | `Esc` | Normal 모드 전환 |
| Normal | `I` | Insert 모드 (줄 처음) |
| Normal | `A` | Insert 모드 (줄 끝) |
| Normal | `0` / `$` | 줄 처음/끝 이동 |
| Normal | `W/B` | 단어 앞/뒤 이동 |
| Normal | `DD` | 줄 전체 삭제 |
| Normal | `V` | Visual 모드 |
| Normal | `/` | 히스토리 검색 |

### 히스토리 탐색

| 키 | 동작 |
|----|------|
| `↑` | 현재 입력 기준 이전 히스토리 검색 |
| `↓` | 현재 입력 기준 다음 히스토리 검색 |

### fzf 키바인딩

| 키 | 동작 | 프리뷰 |
|----|------|--------|
| `Ctrl+T` | 파일 검색 삽입 | bat (구문 강조) |
| `Ctrl+R` | 히스토리 검색 | - |
| `Alt+C` | 디렉토리 이동 | eza (트리) |

### 커스텀 함수

| 명령어 | 동작 |
|--------|------|
| `fsb` | fzf로 git branch 검색 → checkout |
| `fshow` | fzf로 git log 인터랙티브 탐색 |
| `kill_by_port <port>` | 해당 포트의 프로세스 종료 |
| `y` | yazi 파일 관리자 (종료 시 해당 디렉토리로 cd) |

### 유용한 Alias

| Alias | 원본 명령 |
|-------|-----------|
| `ll` | `lsd -aFlht` |
| `ls` | `eza --color=always --icons=always -a -1 --git` |
| `vi` | `nvim` |
| `ta` | `tmux attach` |
| `rm` | `trash` (안전 삭제) |
| `fdm` | `fd --hidden --no-ignore` |
| `rgm` | `rg --no-ignore --hidden` |
| `z <dir>` | zoxide 스마트 디렉토리 이동 |
| `fk` | thefuck (잘못된 명령 수정) |
| `greset` | `git add .; git reset --hard HEAD` |

### Claude Code Alias

| Alias | 동작 |
|-------|------|
| `claude` / `cl` | Claude Code (tmux teammate 모드) |
| `cld` | Claude Code (권한 스킵, tmux 모드) |
| `cc-commit` | 자동 커밋 |
| `cc-push` | 자동 커밋 + push |

---

## Layer 4: Claude Code (AI 코딩 에이전트)

### 글로벌

| 키 | 동작 |
|----|------|
| `Ctrl+T` | 할 일 목록 토글 |
| `Ctrl+O` | 트랜스크립트 토글 |
| `Ctrl+Shift+O` | 팀메이트 미리보기 토글 |
| `Ctrl+R` | 히스토리 검색 |

### 채팅 입력

| 키 | 동작 |
|----|------|
| `Enter` | 메시지 전송 |
| `Shift+Enter` | 줄바꿈 |
| `Esc` | 취소 |
| `Shift+Tab` | 모드 전환 (plan/act) |
| `Meta+P` | 모델 선택 |
| `Meta+O` | 패스트 모드 토글 |
| `Meta+T` | 씽킹 토글 |
| `Ctrl+_` | 실행 취소 (undo) |
| `Ctrl+G` | 외부 에디터에서 편집 |
| `Ctrl+S` | 대화 스태시 |
| `Ctrl+V` | 이미지 붙여넣기 |
| `Ctrl+Q` | 스니펫 피커 |
| `↑` / `↓` | 이전/다음 히스토리 |

### 확인 대화상자

| 키 | 동작 |
|----|------|
| `Y` / `Enter` | 승인 |
| `N` / `Esc` | 거부 |
| `Space` | 토글 |
| `Ctrl+E` | 설명 토글 |
| `Shift+Tab` | 모드 전환 |

### 메시지 네비게이션 (Vim 스타일)

| 키 | 동작 |
|----|------|
| `J` / `↓` | 다음 메시지 |
| `K` / `↑` | 이전 메시지 |
| `Shift+J` / `Ctrl+↓` | 최하단 |
| `Shift+K` / `Ctrl+↑` | 최상단 |
| `Enter` | 메시지 선택 |

### Diff 뷰어

| 키 | 동작 |
|----|------|
| `←` / `→` | 이전/다음 소스 |
| `↑` / `↓` | 이전/다음 파일 |
| `Enter` | 상세 보기 |
| `Esc` | 닫기 |

### Task

| 키 | 동작 |
|----|------|
| `Ctrl+B` | 태스크 백그라운드 전환 |

---

## 레이어 간 키 충돌 정리

| 키 | Ghostty | tmux | zsh | Claude Code |
|----|---------|------|-----|-------------|
| `Ctrl+A` | - | **prefix** | 줄 처음 | - |
| `Ctrl+B` | - | (unbind됨) | - | 태스크 배경 |
| `Ctrl+R` | - | - | fzf 히스토리 | CC 히스토리 |
| `Ctrl+S` | - | - | - | 대화 스태시 |
| `Ctrl+T` | - | - | fzf 파일 | 할일 토글 |
| `Cmd+S` | **리더 키** | - | - | - |
| `Cmd+D` | unbind | - | - | - |

> **참고**: `Ctrl+R`, `Ctrl+T`는 Claude Code와 zsh/fzf에서 중복되지만, Claude Code가 활성 상태일 때만 Claude Code 바인딩이 적용되므로 실제 충돌은 없음.

---

## 테마 현황

| 도구 | 테마 | 비고 |
|------|------|------|
| Ghostty | Catppuccin Latte | 라이트 테마 |
| tmux | Catppuccin Latte | 라이트 테마 (통일됨) |
| bat | GitHub | `BAT_THEME=GitHub` |
| fzf | GitHub Light | 커스텀 색상 |
| LS_COLORS | one-light | vivid |

---

## 설정 파일 위치

| 파일 | 역할 |
|------|------|
| `~/.config/ghostty/config` | Ghostty 설정 |
| `~/.tmux.conf` | tmux 설정 |
| `~/.zshrc` | Zsh 메인 설정 |
| `~/.claude/keybindings.json` | Claude Code 키바인딩 |
| `~/.config/starship.toml` | Starship 프롬프트 |
| `~/.config/nvim/lua/plugins/vim-tmux-navigator.lua` | Neovim ↔ tmux 패인 이동 |
| `~/.config/keybindings-guide.md` | 이 문서 |
