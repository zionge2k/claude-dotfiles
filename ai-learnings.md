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
- **claude/node는 Homebrew 설치** (/opt/homebrew/bin) → NVM lazy loading 안전.
- pre-commit에 update-brewfile 훅은 **미등록** 상태이고 repo에 Brewfile 없음 —
  스크립트만 존재. 등록하려면 `.pre-commit-config.yaml`의 local hooks에 추가.
- zsh alias는 함수 정의 시점에 확장됨 — `rm`을 alias→function으로 바꿀 때
  내부에서 진짜 rm이 필요한 함수(`y()` 등)는 `command rm`으로 명시할 것.
