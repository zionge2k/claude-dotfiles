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

## vis tag가 명세 태그를 지운다 — 근본 수정 완료 (2026-07-25 → 2026-08-06)

> **결론: vis 소스 2곳을 고쳐 해결했다. 이제 수동 태그 복원은 불필요하다.**
> 아래 "원인 추적" 항목들은 배제된 가설이라 재조사 방지용으로만 남긴다.

- **진짜 원인: `_apply_tags_to_file`이 병합이 아니라 교체였다.**
  `semantic_tagger.py`가 frontmatter의 `tags:` 블록을 통째로 버리고 생성 태그로
  재작성했다. `original_tags`가 같은 함수 호출부(354행)에 이미 있었는데 쓰지 않았다.
  → **수정: frontmatter 태그 전량 보호 + 생성 태그는 남은 자리에만 채움.**
  태그 블록 위치도 원래 자리에 유지(전에는 frontmatter 맨 아래로 밀려났다).
- **함께 고친 것: `related_docs_finder.py:161`의 되먹임 고리.**
  관련 문서 목록에 `- 태그: #foo` 처럼 **`#`를 붙여 본문에 쓰던 것**이 문제였다.
  `vault_processor._extract_tags`(196행)가 본문 인라인 `#...`를 전부 태그로 읽기 때문에
  그 줄이 다음 태깅의 입력으로 되돌아왔다(같은 문서 "기존 태그" 7개 → 14개).
  → **수정: `#` 대신 백틱(`` `foo` ``)으로 표기.** 정보는 유지하고 태그화만 차단.
  **순서 주의: 이 수정을 병합보다 먼저 해야 한다.** 반대로 하면 노이즈가 영구 누적된다.
- **왜 vis 태그를 살려야 하는가**: Obsidian에서 태그는 **관련 문서 연결 수단**이다.
  손으로 단 태그는 정확하지만 대개 싱글턴이라 그래프에 기여가 없다(Suno 문서: 6개 중
  5개가 1개 문서). vis의 닫힌 어휘 방식은 **기존 어휘를 재사용해 연결을 만드는** 설계라
  목적에 맞다. 그래서 "vis를 끄기"가 아니라 "둘을 합치기"가 정답이었다.
- **병합이 신규 주제 부트스트랩도 해결한다.** 닫힌 어휘라 vault에 없는 축(`suno/*`)은
  영원히 생성되지 않았는데, 사람이 심은 태그가 보존되면 **다음 문서부터 vis가 그 축을
  후보로 쓴다.** 사람이 축을 심고 vis가 전파하는 역할 분담이 성립한다.
- 검증(2026-08-06): Suno 문서 실행 → 명세 태그 6개 전부 생존, 본문 노이즈 8개는
  frontmatter로 승격되지 않음, 본문 무손상(관련 문서 섹션 외 diff 0).
  `_clean_frontmatter_tag`가 `"#youtube/summary"` 같은 인용·해시 표기도 정상 처리.
- **세 번째 수정: 추가 태그에 신뢰도 컷오프.** 병합으로 바꾸자 추가된 태그가 영구히
  남게 되어, vault 다수파라는 이유만으로 끌려온 `newsletter`/`weekly-digest`/`daily`
  (각 34~45개 문서에 존재)가 눌러앉았다. → `semantic_tagger`의 적용 지점에서
  `min_add_confidence`(기본 0.7) 초과 태그만 기록하도록 필터 추가.
  **0.7은 새로 만든 숫자가 아니라 CLI가 이미 '고신뢰도 태그'를 판정하던 기준**(`__main__.py`)
  과 같은 값이다. 결과: 두 Suno 문서 모두 명세 태그만 남고 오분류 재유입 없음.
- **`#` 벗기기를 빼먹으면 백틱 수정이 무력하다.** 관련 문서 태그가 `"#youtube/summary"`
  처럼 값 자체에 해시를 품은 경우가 있어, `` `{tag}` ``로만 감싸면 백틱 안에 `#`가 남고
  `vault_processor`의 정규식은 백틱을 모르므로 그대로 추출한다.
  → `f"\`{str(tag).lstrip('#')}\`"`로 고쳐야 완전히 막힌다.
- **기존 문서의 누적 노이즈(`#1`, `#newsletter` 등)는 정리되지 않았다.** 신규 오염만
  막았다. 일괄 정리는 미착수(`vis clean-tags` 검토 필요).
- vis는 pipx **editable 설치**라 `~/git/vault-intelligence` 소스 수정이 즉시 반영된다
  (`~/.local/pipx/venvs/vault-intelligence/bin/python`). 재설치 불필요.

### 원인 추적 기록 (배제된 가설 — 재조사 방지용)

- **rules_file 경로 오류는 실재했고 고쳤지만, 오분류의 원인은 아니었다.**
  `~/git/vault-intelligence/config/settings.yaml:252`가 `~/dotfiles/...`를 가리켰는데
  이 저장소는 `~/claude-dotfiles`다(경로 자체가 부재).
  `~/.claude/skills/obsidian-add-tag/SKILL.md`로 수정 → `규칙 로딩 완료: 8개 규칙` 확인.
  **그러나 `--dry-run` 결과는 수정 전과 동일했다.** Suno 문서에 여전히
  `ai/context-optimization/progressive-disclosure`가 붙고 명세 태그는 살아남지 못했다.
  → `tag_rule_engine`의 규칙은 **`semantic_tagger`의 출력을 통제하지 못하는 구조**로 보인다.
  경로를 고쳐도 수동 복원은 계속 필요하다.
- **경로 오류의 유래**: 커밋된 원본은 `~/dotfiles/.claude/commands/obsidian/add-tag.md`
  (upstream msbaek 환경). 스킬 구조 변경에 맞춰 **뒷부분만 갱신하고 `~/dotfiles` 접두사는
  그대로 둔** 절반 수정이었다. 같은 파일의 `vault.path`는 본인 경로로 잘 바뀌어 있었다.
- **stow 미배포가 원인이 아니다.** stow 타겟은 `$HOME`(`install.sh:153`)이라 배포 결과는
  항상 `~/.claude/...`에 생긴다. `~/dotfiles/...`는 stow가 만들 수 있는 경로가 아니라
  **저장소 체크아웃 경로**를 가리킨 값이었다.
- **외부 도구가 dotfiles를 참조할 땐 저장소 경로가 아니라 stow 배포 경로(`~/.claude/...`)를
  쓸 것.** 저장소를 어디에 클론하든, 이름이 바뀌든 깨지지 않는다.
- 교훈 1: `✅ 성공`으로 끝나도 **WARNING을 읽을 것.** 규칙 파일이 없어도 vis는 죽지 않고
  조용히 강등된다. 폴백이 있는 시스템은 고장을 오래 숨긴다.
- 교훈 2: **경고를 없앤 것과 문제를 고친 것은 다르다.** 이번엔 로그가 깨끗해졌지만
  동작은 그대로였다. 수정 후 `--dry-run`으로 **결과가 실제로 바뀌었는지** 반드시 확인할 것.
- `vis tag` 실행 시 스킬/문서 명세로 부여한 태그 중 일부만 살아남고
  `newsletter`, `weekly-digest`, `daily` 같은 **노이즈 태그가 추가**됨.
  원인: vault 기존 문서들의 오염된 태그를 공출현 패턴으로 재학습하는 되먹임 구조.
- **더 심각한 실패 모드: 주제 자체를 오분류함.** Gemini 딥 리서치 영상 문서에
  `ai/tools/claude/skills`를 붙이고 `AI/tools/gemini`·`AI/features/deep-research`를
  **전부 삭제**함. vault에 Claude 문서가 압도적으로 많아 임베딩이 그쪽으로 끌린 것으로 추정.
  → **비(非)Claude 주제 문서일수록 `vis tag` 결과를 반드시 검토**할 것.
- 대응: `vis tag` → `vis add-related-docs` 순으로 실행한 뒤 **마지막에 프론트매터 tags를 수동 복원**.
  (add-related-docs가 프론트매터를 다시 건드릴 수 있으므로 복원은 반드시 맨 마지막)
- **2026-08-02, 최악의 실패 모드 확인: 태그를 전부 삭제한다.** 실행 로그에
  `발견된 파일: 0개` / `태그 학습 완료: 0개 태그`가 찍히면 vis가 vault를 빈 디렉토리로
  인식한 것이고, 이때 `vis tag`는 **기존 태그 6개를 지우고 0개를 기록**한다
  (프론트매터에 빈 `tags:`만 남고, 위치도 맨 아래로 이동). 종료 코드는 `✅ 성공`이라
  **결과만 보면 정상으로 착각**한다. 이어지는 `add-related-docs`는 `❌ 인덱스 구축 실패`로 죽는다.
- → **`vis` 실행 시 로그의 "발견된 파일" 개수를 먼저 확인**할 것. 0이면 즉시 중단하고
  아래 TCC 항목을 의심할 것. 원인은 vis가 아니라 실행 환경일 가능성이 높다.
- **2026-08-06 재현 확인**: Suno AI 음악 영상 요약 문서에 `vis tag`가
  `ai/context-optimization/progressive-disclosure`(Claude Code 스킬 개념)를 붙이고
  명세 태그 6개 중 `ai/music-generation/suno`·`youtube/summary`를 삭제했다.
  규칙 미로드 상태에서는 **비Claude 주제일수록 vault 다수파(Claude 문서)로 끌려간다**는
  가설과 정확히 일치.
- **되먹임 고리를 실측했다: `add-related-docs`가 본문에 심는 노이즈가 다음 `vis tag`의
  입력이 된다.** add-related-docs는 관련 문서마다 `- 태그: #1, #1의, #2` 같은 줄을 붙이는데
  (번호 매기기 마커를 태그로 오인식), 여기에 `#newsletter` `#weekly-digest` `#해시태그`가
  섞여 들어온다. 그 결과 같은 문서의 "기존 태그"가 **7개 → 14개로 불어났다**.
  즉 노이즈가 본문 → 재학습 → 더 많은 노이즈로 순환한다. 후처리 순서를 지켜도 막히지 않는다.
- 근본 해결은 기존 changelog 문서들의 태그 일괄 정리. 미착수.

## Claude Code의 Bash는 ~/Documents(TCC 보호 영역)에 접근 못 한다 (2026-08-02 → 08-06 해결)

- **2026-08-06 해결 확인.** 전체 디스크 접근 권한 등록 후 실측: `find`로 vault .md
  245개, `grep`으로 239건 정상 탐색, 권한 에러 0건, `vis info`도 vault 인식 성공.
  Desktop·Downloads도 모두 통과. **아래 우회 절차는 더 이상 필수가 아니다.**
  단, **판정 기준은 남겨둘 것**: "에러가 없다"가 아니라 **"발견 개수가 0이 아니다"** 로
  확인해야 한다. TCC 거부는 에러가 아니라 빈 결과로 나타나기 때문이다.
- (이하 2026-08-02 당시 기록 — 다른 머신/재발 시 참고)
- macOS TCC는 Claude Code **앱 본체**에만 Documents 권한을 준다.
  `Bash` 도구가 띄우는 **하위 프로세스에는 상속되지 않는다**:
  - `Read` / `Write` / `Edit` 도구 → obsidian vault 읽기·쓰기 **성공**
  - `Bash`의 `ls` / `find` / `grep` / `vis` → `Operation not permitted`,
    `Permission denied - code: 13`
  - **`dangerouslyDisableSandbox: true`로도 뚫리지 않음** — 샌드박스가 아니라 OS 권한 계층이다.
- **증상이 조용한 게 함정.** 에러가 아니라 "0개 발견", "no matches found"로 나와
  빈 vault처럼 보인다. 위 `vis tag` 태그 전멸 사고의 직접 원인.
- 대응: vault 파일 조작은 **Read/Write/Edit 도구로** 하고, `vis` 같은 CLI는
  **사용자가 터미널에서 직접 실행**하도록 안내할 것(프롬프트에 `!vis tag ...`).
  근본 해결은 시스템 설정 > 개인정보 보호 및 보안 > 전체 디스크 접근 권한 등록.

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
  **W31에서 영속화 완료**: `~/.claude/skills/weekly-claude-analytics/scripts/wk_analytics.py`
  + `wk_classify.py`. 상단 `WEEK_START`/`NOW` 상수만 바꿔 재실행하면 됨.
- **주간 필터는 파일 mtime이 아니라 레코드 timestamp로 할 것.** 지난주 세션이 이번 주에
  한 줄만 추가돼도 mtime은 이번 주가 되어 span·활성이 통째로 딸려 들어온다.
- **함정: 세션별 파일 목록을 `[:N]`으로 잘라 저장한 뒤 union하면 고유 파일 수가 조용히
  과소 집계된다** (W31: 195 vs 실제 222). 절단한 컬렉션으로 파생 지표를 만들지 말 것.
- **무인화된 프로젝트는 활성 시간에 안 잡힌다.** W31 stock은 8%였지만 발행 저장소
  (`~/projects/portfolio`)에 브리핑 커밋 13건이 올라갔다. 프로젝트별 시간과 함께
  **각 저장소의 주간 커밋 수**(`git log --since=<월요일> --oneline | wc -l`)를 볼 것.
- **agent-team 지표(Agent·SendMessage) 하락 = 오케스트레이션 퇴행 아님.** 감각 판정
  비중이 높은 주(콘텐츠 검수 등)에는 위임 가능한 일 자체가 없어 자연히 죽고,
  대신 AskUserQuestion·playwright가 뛴다. W30→W31이 이 케이스.

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
