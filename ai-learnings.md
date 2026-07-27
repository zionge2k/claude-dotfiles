# AI Learnings

작업 중 발견한, 다음에 같은 작업을 더 빠르고 정확하게 하기 위한 기록.

## YouTube 트랜스크립트 수집: 3단계 fallback 체인 (2026-07-25)

- `obsidian-summarize-youtube` 스킬의 기본 경로인 `youtube-transcript-api`는
  **IP 차단(RequestBlocked)으로 실패**하는 경우가 많음. 스킬 문서만 따라가면 여기서 막힘.
- 검증된 fallback 순서:
  1. `youtube-transcript-api` (스킬 기본) → IP ban 시 실패
  2. `yt-dlp` 맨몸 → `HTTP 429` + "Sign in to confirm you're not a bot"으로 실패
  3. **`yt-dlp --cookies-from-browser chrome`** → 성공 (498개 쿠키 추출, deno로 JS challenge 해결)
- **함정: `--print`는 암묵적으로 `--simulate`를 켠다.** 메타데이터와 자막을 한 명령으로 받으려
  `--print`를 붙이면 자막 파일이 **조용히 저장되지 않음**. 메타데이터용/다운로드용 명령을 분리할 것.
- 자막 언어는 `--list-subs`로 먼저 확인. 한국어 영상은 `ko` 자동 생성 자막이 있음.
- **자동 생성 자막은 롤링 윈도우 방식**이라 같은 문장이 점진 누적됨(143KB → 정제 후 23KB).
  단순 인접 중복 제거로는 부족하고, "이전 줄이 현재 줄의 부분 문자열이면 교체" 로직 필요:
  ```python
  if clean and (t in clean[-1][1]): continue          # 현재가 이전에 포함 → 버림
  if clean and clean[-1][1] in t: clean[-1] = (ts, t) # 이전이 현재에 포함 → 교체
  ```
- 한국어 자동 자막은 **기술 고유명사를 음차 오인식**함. 문맥 교정 필수 사례:
  오퍼스→Opus, 페이블→Fable, 솔/쏘리→Sol, 클로스→Claude, 미토스→Mythos,
  한네스→harness, 언트라 코드→ultracode, 웹자인→웹디자인.
  요약 문서의 Uncertainty Map에 교정 목록을 남길 것.
- zsh에는 `timeout`이 없음(coreutils 미설치). 루프 안에서 `timeout` 쓰지 말 것.

## vis tag는 명세 태그를 덮어쓴다 (2026-07-25, 재확인)

- `vis tag` 실행 시 스킬/문서 명세로 부여한 태그 중 일부만 살아남고
  `newsletter`, `weekly-digest`, `daily` 같은 **노이즈 태그가 추가**됨.
  원인: vault 기존 문서들의 오염된 태그를 공출현 패턴으로 재학습하는 되먹임 구조.
- **더 심각한 실패 모드: 주제 자체를 오분류함.** Gemini 딥 리서치 영상 문서에
  `ai/tools/claude/skills`를 붙이고 `AI/tools/gemini`·`AI/features/deep-research`를
  **전부 삭제**함. vault에 Claude 문서가 압도적으로 많아 임베딩이 그쪽으로 끌린 것으로 추정.
  → **비(非)Claude 주제 문서일수록 `vis tag` 결과를 반드시 검토**할 것.
- 대응: `vis tag` → `vis add-related-docs` 순으로 실행한 뒤 **마지막에 프론트매터 tags를 수동 복원**.
  (add-related-docs가 프론트매터를 다시 건드릴 수 있으므로 복원은 반드시 맨 마지막)
- 근본 해결은 기존 changelog 문서들의 태그 일괄 정리. 미착수.

## weekly-claude-analytics: 세션 파일 ≠ 작업 단위 (2026-07-25, W30)

- `~/.claude/projects/<proj>/` 직속 `*.jsonl`이 top-level 세션이지만, W30부터
  **agent-team 워커**(첫 user 메시지가 `<teammate-message`로 시작)와 **cron 원샷**
  (msgs≤2·활성≤10m, stock 브리핑 생성기)이 top-level 파일로 대량 생성됨.
  W30: 71개 중 실작업 11개뿐. 분류 없이 세션 수·프로젝트 시간을 읽으면 오독.
- subagent 로그는 `<proj>/<sessionId>/subagents/*.jsonl`. `memory/`·scratchpad
  프로젝트 디렉토리는 제외할 것.
- 활성 시간 기준: 인접 timestamp 간격 <30m 합산 (W19부터 동일). raw span 사용 금지
  (켜둔 세션이 68h까지 부풀음). 주간 경계는 이벤트 발생일 기준으로 클립.
- Jira 정규식 `[A-Z]{2,10}-\d+`는 `UTF-8`·`SHA-256`·`RTX-4060`·`AI-7`(Ryzen) 등
  기술 용어 오탐이 전부라 수동 검증 필수.
- 파싱 스크립트 2단계 구성이 유효: stage1(jsonl→세션별 JSON 덤프) + stage2(분류·집계).
  W30 실행본: `/tmp/weekly_claude_analytics.py`, `/tmp/w30_aggregate.py` (일회성, 삭제됨 —
  구조는 이 항목과 W30 리포트 메모 참조).

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

## tmux 창 크기 고정 — 원인은 resize-window (2026-07-27 확정)

**철칙: 자동화(훅·스크립트)에서 `tmux resize-window`를 절대 호출하지 말 것.**
`-A` 유무·인자 형태와 무관하게 **모든** `resize-window` 호출은 대상 window에
`window-size manual`을 즉시 기록하며(man tmux 명시), 그 window는 그 순간부터
전역 `window-size largest`를 **영구히 상속하지 않는다**. 즉 이 명령은
"클라이언트 크기로 동기화"가 아니라 **"그 순간 크기로 박제"**다.

- 증상(양방향): 터미널 > 창이면 남는 영역이 점(`.`)으로 채워지고, 터미널 < 창이면
  내용이 리플로우되지 않고 잘린다. 어느 쪽이든 터미널 리사이즈를 창이 안 따라온다.
- 진단: `tmux show-options -w -t <win> window-size`.
  `manual`이 나오면 박제 상태. 비어 있으면 정상(전역 상속).
  창별 일괄 확인은 `list-windows -a` 돌면서 위 명령 실행.
- 복구(서버 재시작 불필요): `tmux set-option -uwt <win> window-size`.
  서버에 남은 훅 옵션은 `tmux set-option -gu @resurrect-hook-post-restore-all`.
  (`-gu` 후 조회 시 `invalid option`은 정상 삭제됨을 뜻함)
- **설정 파일에서 줄을 지워도 실행 중 서버의 옵션은 안 사라진다.** `prefix+r`
  리로드로도 안 된다. 위 `-u`/`-gu`로 명시 삭제하거나 서버를 재시작해야 한다.
- escape hatch를 둘 거면 반드시 manual을 즉시 털 것:
  `bind R resize-window -A \; set-option -uw window-size \; display-message ...`

### 실측 검증 (격리 소켓 `tmux -L`)
- `resize-window` 호출 → 즉시 `window-size manual` 기록 (`-A` 유무 무관)
- manual 창(160x40) vs 비설정 창(239x43) 동시 비교 → manual 창만 추종 안 함
- `select-layout`은 manual을 유발하지 **않음** → resurrect 복원 경로는 무죄
- `set-option -uw` → manual 해제되고 전역 largest 재상속 확인

### 실패한 수정 이력 (반복 금지)
- 2026-07-12: `prefix+R`에 `resize-window -A` 바인딩. 이때 이미 "수동 크기 상태를
  남긴다"고 기록했으나 **경고와 해결책을 따로 적어둔 탓에** 8일 뒤 스스로 위반.
- 2026-07-20: "pane 레벨 latch"로 오진하고 `@resurrect-hook-post-restore-all`에
  `resize-window -A`를 **전 window 자동 실행**으로 승격. **이 훅이 다음 사건의 직접
  원인.** 수동으로 가끔 밟던 지뢰를 복원할 때마다 자동으로 밟게 만든 셈.
- 2026-07-24: 복원 시 창 3개가 239칸 중 119칸+manual로 박제, 사흘간 자가 복구 불가.
  같은 세션의 stock 창만 멀쩡했던 이유는 훅 실행 7시간 뒤 수동 생성되어 대상이
  아니었기 때문(pane PID `ps -o lstart=`로 확인). **"고칠수록 나빠진" 사례.**
- 2026-07-27: 훅 제거 + `bind R`에 `-uw` 추가로 종결. 커밋 `245fa67`.

### 미확정
- 복원 시점 클라이언트가 왜 하필 119칸(=239의 절반)이었는지는 당시 로그가 없어
  확정 불가. Ghostty의 macOS 창 복원 비동기 타이밍(continuum은 `sleep 1`만 대기)이
  유력하나 미측정. **다만 manual만 안 남기면 119의 출처와 무관하게 자동 회복된다.**

### 관련 (버그 아님)
- "tmux ls는 비었는데 진입하니 이전 창들이 있다"는 정상 동작 —
  `@continuum-restore 'on'`이 서버 기동 시 `~/.local/share/tmux/resurrect/`
  마지막 저장본을 자동 복원하는 것.

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
