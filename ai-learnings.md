# AI Learnings

작업 중 발견한, 다음에 같은 작업을 더 빠르고 정확하게 하기 위한 기록.

## upstream(msbaek/dotfiles) 비교·이식 절차 (2026-07-12)

- 두 저장소는 **git 히스토리가 독립적** (root commit 다름). `git diff upstream` 불가 —
  scratchpad에 clone 후 **기능 단위 비교**가 정석. 겹치는 파일 9개:
  `.zshrc` `.zprofile` `.tmux.conf` `.config/ghostty/config` `.gitignore`
  `.pre-commit-config.yaml` `.secrets.baseline` `.stow-local-ignore` `README.md`
- 병렬 Explore 에이전트(zsh/터미널/인프라 3분할)가 효율적이나, **핵심 주장은 반드시 재검증**할 것.
  이번에 에이전트가 "tmux-dashboard 바인딩 broken"으로 오판 → 실제로는 홈에 untracked 실물 존재.
- upstream의 cw/cwq 스택은 aerospace+ghostty quick terminal 의존 → 이식 시
  `_cc_goto`의 aerospace 분기를 `tmux switch-client`로 대체하면 단일 터미널 환경에서 동작.

## 이 저장소 고유 제약

- **stow 배포**: repo에 새 파일 추가 후 `stow -R --no-folding -t "$HOME" .` 재실행 필요.
  홈에 같은 경로의 실물 파일이 있으면 conflict → 실물을 백업 후 restow.
  repo 루트 문서(SECURITY.md 등)는 `.stow-local-ignore` 등록 필수 (아니면 홈에 링크됨).
- **teammateMode는 settings.json에 있음** → cld 등 alias에 `--teammate-mode` 플래그 불필요 (중복).
- **claude/node는 Homebrew 설치** (/opt/homebrew/bin). ~~NVM lazy loading 안전~~
  → **오판이었음**: 아래 "셸 스냅샷과 함수 래퍼" 참조. nvm 미설치 상태라 블록 자체를 제거함.
- pre-commit에 update-brewfile 훅은 **미등록** 상태이고 repo에 Brewfile 없음 —
  스크립트만 존재. 등록하려면 `.pre-commit-config.yaml`의 local hooks에 추가.
- zsh alias는 함수 정의 시점에 확장됨 — `rm`을 alias→function으로 바꿀 때
  내부에서 진짜 rm이 필요한 함수(`y()` 등)는 `command rm`으로 명시할 것.

## 멀티 커밋 시 pre-commit 함정 (2026-07-12)

- `.pre-commit-config.yaml`이 **수정-unstaged 상태면 pre-commit이 모든 커밋을 거부**
  ("Your pre-commit configuration is unstaged") → 커밋을 나눌 때 설정 파일 변경분을
  **첫 커밋에 포함**할 것.
- 셸에서 `git add A && git commit` 여러 줄을 이어 실행하면 커밋 실패 시
  **staging이 다음 줄로 누적**되어 뒤 커밋이 전부 삼킴 → `set -e`로 즉시 중단시키고,
  커밋마다 `git show --stat`으로 파일 구성 검증할 것.
- pre-commit은 unstaged 변경을 stash/restore함 — upstream에서 이 과정 중 alias 유실
  사고 이력 있음(23359fd). 멀티 커밋 후 워킹트리와 커밋본 diff로 무결성 확인 권장.

## tmux window 절반 크기 latch (2026-07-12)

- 증상: 클라이언트는 239칸인데 window 레이아웃이 119칸에 고정 → 오른쪽 미사용
  영역이 "빈 pane"처럼 보임. Ghostty 창 복원 타이밍에 `window-size latest`가
  일시적 절반 크기를 latch하며 발생, Ghostty 재시작 시 재발.
- 진단법: `tmux list-clients`(클라이언트 크기) vs `tmux list-panes -a`(pane 크기)
  비교. 단일 pane인데 클라이언트보다 작으면 latch 상태.
- 해결: `set -g window-size largest`(신규 window 예방) + 기존 window는
  `tmux resize-window -A`로 개별 재채택. escape hatch로 `prefix+R` 바인딩 추가.
- 주의: `resize-window`는 대상 window에 수동 크기 상태를 남길 수 있어
  글로벌 옵션 변경만으로는 기존 window가 복구되지 않음.

## 셸 스냅샷과 함수 래퍼 — MCP 서버 사망 사건 (2026-07-12)

- **Claude Code 셸 스냅샷은 `_언더스코어` 헬퍼 함수 정의를 제외**하고 일반 함수만 담음.
  → `npx() { _load_nvm; npx "$@" }` 같은 래퍼는 스냅샷 안에서 `_load_nvm` 부재로
  unfunction이 실행되지 못해 **자기 자신을 무한 재귀 호출** ("maximum nested
  function level reached") → npx 기동 MCP 서버(playwright 등)·statusline 즉사.
- 교훈 1: **.zshrc에서 실제 바이너리를 가리는(shadow) 함수는 self-contained로**
  작성하고 원본 호출은 `command <name>`으로. `_헬퍼` 의존 금지.
  (rm()이 안전한 이유: 자기완결 + `command trash` 호출)
- 교훈 2: **upstream 패턴 이식 시 전제부터 검증** — NVM lazy는 upstream엔 nvm이
  있어 유효했지만 이 머신엔 ~/.nvm 자체가 없었음. `which node`만 보고 안전
  판정한 것이 오판의 원인.
- 교훈 3: 스냅샷은 세션 시작 시 고정 → .zshrc 수정 후 **Claude Code 재시작**
  (`claude --resume`) 필요. cj/ccps 등 `_헬퍼` 의존 함수도 스냅샷 셸에서는
  동작 안 하지만(에러 후 종료), 바이너리를 가리지 않으므로 무해.
- serena MCP는 npx가 아닌 **uvx로 기동** — playwright와 사인(死因)이 다를 수
  있으므로 재시작 후에도 죽어 있으면 별도 진단할 것.
