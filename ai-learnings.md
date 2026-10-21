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
- **재검증(2026-08-14, Krea 2 문서)**: 명세 태그 6개 전부 생존, 파일 diff **0바이트**.
  CLI가 "새 태그"로 `ai/tools/claude-code/automation`(주제 무관 노이즈)을 출력했지만
  고신뢰도 목록에서 빠져 파일에는 기록되지 않았다.
  (구 메모리 "vis tag 후 프론트매터 수동 복원 필요"는 폐기된 정보다.)
- **⚠️ 위 재검증 결론은 2026-09-02에 뒤집혔다.** "CLI 출력 ≠ 실제 기록분"은 **일반 법칙이 아니라
  그날 그 문서의 우연**이었다. 09-02 changelog 문서에서는 CLI가 출력한 5개가 **그대로 기록됐다**.
  `min_add_confidence` 필터는 지금도 살아 있다(`semantic_tagger.py:382`) — 통과한 쪽이 문제다.
  아래 "vis tag 오탐의 근본 원인" 절 참조.

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
  **W31에서 영속화, W32에서 파라미터화 완료**:
  `~/.claude/skills/weekly-claude-analytics/scripts/wk_analytics.py` + `wk_classify.py`.
  `WK_START=2026-08-03 WK_END=2026-08-08T08:00 WK_OUT=/tmp/wk32.json` 환경변수로 실행
  (소스 상수 편집 불필요 — 지난주 상수로 그대로 돌리는 사고를 구조적으로 차단).
  고유 편집 파일 union도 스크립트가 `UNIQUE edited files:` 줄로 직접 출력한다.
  **주의: 이 scripts/ 디렉토리는 claude-dotfiles 저장소에 미추적**(SKILL.md만 심볼릭 링크).
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
  **W32에서 역방향도 확인**: 리서치·구현 성격의 신규 프로젝트(ai-character) 하나가
  생기자 Agent 15/SendMessage 14로 즉시 되살아났다(주간 위임의 83%가 그 세션 하나).
  위임 지표는 절대량이 아니라 **작업 성격의 대리 변수**로 읽을 것.
- **⚠️ 월요일 00:00 고정 경계 + 토요일 오전 실행 = 주말 데이터 구조적 유실 (W32에서 발각).**
  W31 리포트는 51h 38m로 기록됐지만 재측정 실제는 **75h 03m** — 31% 누락.
  원인 둘: ① 토 08:00에 실행해 `NOW=일 00:00`으로 잡았는데 토요일 오전 8시 이후
  12h 50m이 리포트 시점엔 아직 없었다 ② ISO 주차상 일요일이 W31인데 `NOW`가
  일 00:00이라 **일요일이 어느 리포트에도 안 잡힘**(10h 35m).
  **해법: 주간 경계를 "직전 리포트의 NOW"에서 시작하는 이월형(carry-forward)으로 할 것.**
  각 리포트 말미에 자신의 `WK_END`를 명시하고, 다음 주는 그 값을 `WK_START`로 쓴다.
- **W33에서 이월형 경계 첫 적용 — 주말 유실은 0이 됐지만 새 함정이 생겼다.**
  이월형은 **관측창 길이가 매주 달라진다**(W32 5.33일 → W33 7.0일). 총량 비교는
  전부 창 길이 효과라 무의미 — **모든 비교를 일평균으로 정규화할 것.**
  W33 총량 +31%였지만 일평균은 ±0%(병합 기준 -4%)였다.
- **⚠️ "활성 시간"은 세션별로 재서 더하므로 동시 세션이 중복 계산된다.**
  W33 08-11에 하루 20h 46m이 찍혔다(24h 중). 오류가 아니라 정의의 한계.
  **해법: 모든 top-level 세션의 활성 구간을 합집합으로 병합한 wall-clock 지표를 병기.**
  W33 = 합산 74h 20m vs 병합 54h 20m → **병렬 계수 1.37**(W32 1.31).
  병합 스크립트는 아직 `/tmp/wk33_union.py` 임시본 — `wk_analytics.py` 편입 필요.
- **cron 프롬프트 마커는 조용히 바뀐다.** W33에서 stock 프롬프트가
  `이벤트 확인기` → **`이벤트 수집기`**로 바뀌어 cron 세션이 실작업으로 오분류됐다.
  `wk_classify.py`의 `CRON_MARKS`에 추가 완료. **매주 real 세션 목록을 눈으로 훑어
  cron스러운 게 섞였는지 확인할 것** — 마커 방식은 프롬프트 변경에 취약하다.
- **프로젝트 디렉토리 ≠ 산출물 저장소.** W33 `claude-dotfiles`는 활성 1h 45m인데
  커밋 0건 — 그 시간의 산출물이 전부 zion-vault(별도 저장소)로 갔다.
  커밋 수만으로 "일 안 한 프로젝트"로 판정하지 말 것.
- **⚠️ "편집된 고유 파일" 지표는 스크래치가 3~5할이다 (W34에서 발각).**
  `/private/tmp/claude-501/...` 에 쓰는 임시 산출물이 그대로 카운트된다:
  W33 288개 중 139개(48%), W34 196개 중 64개(33%). 스크래치를 빼면 주간 변화가
  **-29% → -11%**로, 시간당으로는 **부호가 뒤집힌다**(2.74→3.68/h, +34%).
  `wk_analytics.py`가 `/private/tmp`·`/tmp` 경로를 분리 집계하도록 개정 필요.
- **이월형 경계가 창 길이를 고정하자 새 교란 변수가 나왔다 — 창 안의 휴지(休止).**
  W34는 W33과 같은 7.0일 창인데 **가동일이 4.58일**(08-15 12:36 → 08-17 18:01,
  53시간 정지). 총량은 -42%였지만 **병합활성/가동일은 7h43m vs 7h46m(-1%)**.
  **총량·창일평균·가동일평균 3종을 병기할 것.** 가동일 = 첫 실작업 이벤트부터 WK_END까지.
- **병렬 계수는 채널 수와 연동되지 않는다.** W33은 "justsoombi가 3번째 라인이 되면
  1.5를 넘는가"를 물었는데 실제로는 **1.37 → 1.14로 하락**했다. justsoombi가 별도
  세션이 아니라 soombicafe 세션 내부의 작업 축으로 흡수됐기 때문. 병렬은 대신
  **세션 밖(agent-team 워커 17개, Workflow +71%/h)**으로 이동했다.
  **"라인이 늘면 병렬도가 는다"는 가설은 기각.**
- **자동 실행 스킬 세션이 `real`로 새어 들어온다.** W34에서 `/weekly-newsletter`
  자동 실행 세션이 실작업으로 잡혔다. `wk_classify.py`에 `META_MARKS` 리스트를
  신설(`/clear`·`/effort`·`/login`·`/status`·`/model`·`weekly-claude-analytics`·
  `weekly-newsletter`·`daily-work-logger`)하고 임계를 `user_msgs<=4`로 완화해 정정.
  **새 자동 실행 스킬을 만들 때마다 이 리스트를 갱신할 것.**
- **`/clear`로 시작한 세션은 `first_prompt`에 작업 내용이 안 남는다.** W34 실작업
  16개 중 9개가 이 케이스라 분류 스크립트 출력만으로는 주간 서사를 못 쓴다.
  **`<command-`·`<system-reminder`·`[Request interrupted`로 시작하는 줄을 건너뛰고
  첫 "실질" 유저 메시지를 따로 뽑을 것** — 이게 서사 작성의 실제 입력이다.
- **⚠️ 스크립트 미추적 4주 연속.** `scripts/` 3종(`wk_analytics`·`wk_classify`·
  `wk_union`)은 여전히 `claude-dotfiles` 밖. W33 권고였던 `wk_union.py` 편입은
  됐지만 저장소 추적은 안 됐다. **매주 개정분이 백업 없이 쌓이는 중.**
- **W35에서 창·가동일을 둘 다 7.0일로 고정하니, 남은 건 평평한 선이었다.**
  가동일 평균 병합 활성: W33 7h 46m → W34 7h 49m → **W35 7h 06m**. 3주 연속 7h대.
  주간 총량 변동(-34% → +39%)은 전부 **가동일 수의 함수**였다.
  **총량 증감을 강도로 읽지 말 것** — W34의 "-42%"와 W35의 "+39%"는 같은 오독의 앞뒷면.
- **⚠️ 모델 분포 표는 클래스별로 쪼개지 않으면 거짓말을 한다.** W35에서 sonnet-4-6가
  7%→49%로 1위가 됐지만, **워커는 W34에도 100% sonnet-4-6**였다. 바뀐 건 모델 선택이
  아니라 워커 메시지 물량(592→6,304, 10.6배)뿐이고 **실작업 믹스는 opus 63→67% /
  fable 37→33%로 불변**. `wk_derive`류에서 `models by class`를 기본 출력으로 쓸 것.
- **병렬 계수 가설 정정: `f(반복 위임 물량)`이지 `f(라인 수)`가 아니다.** W34는 라인-병렬
  가설을 기각만 했는데, W35에서 계수가 1.14→1.32로 올랐다. 늘어난 건 채널 수(3→4)가
  아니라 **위임 가능한 반복 브라우저 작업**(업로드 워커 19 + 최종화면 6)이었다.
- **⚠️ 일별 표에서 "세션 합산"과 "병합"의 대소를 비교하지 말 것.** 합산은 *이벤트 날짜*,
  병합은 *구간 종료 시각의 날짜*로 귀속해서 **자정을 넘긴 블록에서 날짜 배분이 어긋난다**
  (W35 08-23·08-25는 병합 > 합산). 일별로 유효한 건 병합 열 하나뿐이고, 병렬 계수는
  자정을 안 넘긴 날에만 의미가 있다.
- **W34 권고 2건 이행 완료(W35).** ① `wk_analytics.py`에 `SCRATCH_RE`(`^(/private)?/tmp/`)
  추가 → `product=108 scratch=40` 분리 출력 ② `/clear` 시작 세션용 `real_prompt` 필드
  (`<command-`·`<system-reminder`·`[Request interrupted`·`<local-command`·`<teammate-message`·
  `Caveat:` 접두 스킵). W35 실작업 18개 중 **12개가 `/clear` 시작**이라 이 필드 없이는 서사를 못 쓴다.
  **개정 후 회귀 검증법: 지난주 창을 재계산해 원 리포트 수치와 대조**(W34 = 196/132/64·
  3585·750·41h 00m 완전 일치). 스크립트를 고칠 때마다 이 대조를 먼저 할 것.
- **Jira 섹션을 "채널별 발행 현황"으로 대체 완료(W35).** 8주 연속 0건이라 정보량이 0이었다.
  이 워크로드의 실제 단위는 티켓이 아니라 **발행물·소급 정비 편수**다.
  `TaskCreate`는 2주 연속 0이라 표에서 제거, 대신 `TaskStop`·`Monitor`·`ListAgents`가
  올라왔다 — **워커 체제가 커지면 태스크 생성이 아니라 감시/중단으로 도구가 이동한다.**
- **"커밋 0 = 사용 중단"이 아니다 — 프로젝트가 라이브러리로 흡수된다.** W35 `mastering`은
  세션 0·커밋 0인데 pw03 커밋이 `mastering 프로젝트 genre 계열 마스터링 적용 — 8곡`이다.
  **"상시 라인"과 "상시 도구"는 다른 상태**이고, 커밋 수는 후자를 못 본다.
- **⚠️ 스크립트 미추적 5주 연속.** `scripts/` 3종은 여전히 `claude-dotfiles` 밖.
  **W35 개정분(스크래치 분리·real_prompt)도 백업 없음.** 다음 주엔 권고가 아니라 작업 항목.

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

## obsidian-summarize-youtube 실전 함정 4가지 (2026-08-14)

- **`## Related` 플레이스홀더를 미리 넣지 말 것.** `vis add-related-docs`는 기존 섹션을
  찾지 않고 **`## 관련 문서` 섹션을 새로 append**한다. 플레이스홀더가 있으면 빈 섹션 +
  자동 섹션이 **둘 다 남는다**. 스킬 문서엔 이 순서가 안 적혀 있음.
- **`vis add-related-docs` 추천은 그대로 믿지 말 것.** Krea 2(이미지 생성 워크플로) 문서에
  `APoSD Ch.7`·`유튜브 세팅 가이드`·`OpenAI 슈퍼앱`이 딸려 왔다. 유사도가 **0.72~0.75
  좁은 구간에 밀집**하면 임베딩이 "AI 관련 한국어 기술 문서"라는 **표면 특징만 잡은 신호**다.
  → 상위 2~3건만 사람이 골라 남기고 나머지 제거. 판별 기준은 점수 절대값이 아니라 **분산**.
- **자동 생성 자막은 기술 용어를 대량 오인식한다.** 실측: `레디드`→Reddit, `VA`→VAE,
  `컨트롤렛/컨트롤 S`→ControlNet, `시드 VR2/CDVR2`→SeedVR2, `제 이미지`→Z-Image,
  `QN`→Qwen, `완 2.1`→Wan 2.1, `댑스맵`→Depth Map. → **"용어 복원 테이블"을 문서에
  포함**시켜야 나중에 재검색이 된다. 이게 없으면 문서가 검색 불가능해진다.
- **기존 vault 문서와의 식별 충돌을 적극적으로 찾을 것.** 같은 고유명사(`크레아 2`)를
  기존 문서는 FLUX.1 Krea로, 신규 영상은 Qwen-Image 계열(Qwen3-VL 인코더 + Wan 2.1 VAE)로
  가리키고 있었다. **구성 요소(인코더/VAE)를 비교하면 아키텍처 계열이 드러난다.**
  → 신규 문서 작성 시 `grep -rli "<고유명사>"`로 선행 문서를 먼저 확인.

### 도구 사용 메모
- **`ls`가 eza 별칭**이라 `ls -t`가 `--time <FIELD> 값 필요` 에러로 죽는다. → `command ls -t`.
- `youtube-transcript-api`는 **항상 막히는 건 아니다**(이번 `ko` 자막 정상 수신).
  기존 학습("IP 차단으로 자주 실패")은 유효하되 **먼저 시도해 보는 게 맞다** — 성공 시
  yt-dlp 쿠키 추출(~수 초)을 통째로 건너뛴다.
- 메타데이터는 Playwright MCP(스킬 기본) 대신 **`yt-dlp --skip-download --print`** 가 훨씬 빠르다
  (제목/채널/길이/업로드일 한 방). 단 `--print`는 자막 저장을 무력화하므로 **명령 분리 필수**.

## weekly-newsletter: 스킬 문서의 주차 계산 명령이 macOS에서 깨진다 (2026-08-22)

- `SKILL.md`의 `date -j -f "%G-W%V-%u" "${WEEK_NUM}-1"`는 **BSD date에서 항상 실패**한다
  (`illegal time format`). BSD `date`는 `%G`/`%V`를 **출력(`+%G-W%V`)은 지원하지만 입력 파싱은 못 한다.**
  → `ISO_MONDAY`가 빈 문자열이 되고, 이후 `SATURDAY`/`FRIDAY`가 전부 빈 값으로 전파된다.
- **토요일 오전 실행 전제라면 ISO 주차 파싱이 아예 불필요하다**:
  ```bash
  SATURDAY=$(date -j -v-7d +%Y-%m-%d)   # 지난주 토
  FRIDAY=$(date -j -v-1d +%Y-%m-%d)     # 어제(금)
  WEEK_NUM=$(date +%G-W%V)              # 출력은 정상 동작
  ```
- **정황 증거: 2026-W33 뉴스레터가 통째로 누락됐다.** W10~W32가 매주 토요일 09:0x에 생성됐는데
  W33만 없다(08-15 실행분). 같은 날 analytics는 정상 생성됐으므로 스킬 단독 실패다.
  날짜 변수가 빈 값이 되면 조용히 아무것도 못 찾고 끝나므로 **실패가 눈에 띄지 않는다.**
- 스킬 본문의 `find ... | awk -v start=... '$1 >= start && $1 <= end {print $2}'` 부분도
  **인수 치환으로 `$1`/`$2`가 파괴돼 있다**(`'실행 >= start ... {print 컨텍스트입니다.}'`).
  슬래시 커맨드 인수가 SKILL.md 본문의 `$1`을 덮어쓰는 문제 — awk 스크립트는 `$1` 대신
  `substr()`나 `-F` 기반으로 재작성하거나, 아예 `find -newermt`로 대체할 것.
- **`find -newermt "YYYY-MM-DD" ! -newermt "YYYY-MM-DD"`가 `stat`+`awk` 조합보다 안전하다**
  (macOS의 `find`는 GNU식 `-newermt`를 지원한다). 단 **종료 경계는 배타적**이라
  마지막 날을 포함하려면 `! -newermt "다음날"`로 써야 한다.

## claude-updates 스킬: changelog 수집·태깅 함정 (2026-09-02)

- **Playwright 스냅샷은 컨텍스트에 못 올린다.** `browser_snapshot`으로 받은 changelog 페이지는
  1,306,713자 / 18,380줄이라 자동으로 파일로 떨어진다. 전체를 읽지 말고 최신 릴리스만
  `grep -n "2\.1\.2[0-9][0-9]"`로 위치를 잡아 `sed -n '160,600p'` 식으로 상단만 잘라낼 것.
- **스냅샷의 가격 표기는 MathML로 깨진다.** `$10/$50 per Mtok`이 접근성 트리에서
  `"10" "/" "10/" "50 per Mtok"`으로 분해돼 나온다. 숫자·기호가 섞인 항목은
  `curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`로
  원문 마크다운 교차검증 필수. (docs 페이지는 이 파일을 렌더링한 것)
- **`vis tag` 실행 후 반드시 frontmatter를 검증할 것.** 2026-09-02 실행 시
  `newsletter`, `weekly-digest`, `daily`, `2-1-114`, `2-1-149` 5개가 **실제로 기록됐다**.
  동일 시리즈 문서는 canonical 태그 3개만 유지
  (`tools/claude-code/changelog`, `tools/claude-code/updates`, `tools/ai-tools/release-notes`).
- **frontmatter만 뽑을 때 `sed -n '/^tags:/,/^[a-z_]*:/p'`는 틀린다.** 본문에도 `  - 태그:` 로
  시작하는 줄(add-related-docs 출력)이 있어 범위가 본문까지 흘러간다. 반드시 첫 `---` 블록으로 한정:
  ```bash
  awk 'NR==1&&/^---$/{fm=1;next} fm&&/^---$/{exit} fm' "$F"
  ```
- **`vis add-related-docs`가 표시하는 관련 문서의 태그는 신뢰할 수 없다.** 실제 frontmatter에는
  canonical 태그 3개뿐인데 `1의`, `2-1-114`, `2-1-149`로 표시된다. 별도 인덱스/캐시를 읽는 것으로 추정.
  링크 추천 자체(유사도 순 changelog 문서들)는 정확했다.
- **볼트 정리본 갭 확인은 `sort -V` 필수.** `ls | grep Changelog | sort -V | tail`.
  단순 `sort`는 `2.1.98 > 2.1.220`으로 잘못 정렬한다.

### vis tag 오탐의 근본 원인 — 레거시 오염이 스스로를 재생산한다 (2026-09-02 확정)

`semantic_tagger.py:366-374`의 신뢰도 공식은 다음과 같다:

```python
confidence = similarity_to_existing[tag] + 0.1 * (매칭된 key_concepts 수)   # cap 1.0
```

**`similarity_to_existing`이 "기존 vault 태그 corpus"를 기준으로 계산된다는 게 핵심이다.**
corpus가 오염돼 있으면 오염 태그가 높은 점수를 받고, 그 결과 새 문서가 또 오염되어
카운트가 올라가고, 다음 문서의 점수가 더 높아진다. **되먹임 구조다.**

실측 (vault 268개 md, frontmatter 기준):

| 태그 | 총계 | 정당한 위치 | 오염된 위치 |
|---|---|---|---|
| `daily` | 44 | `notes/dailies/` 32 | **`003-RESOURCES/` 11** |
| `newsletter` | 36 | `newsletters/` 20 | **`003-RESOURCES/` 15** |
| `weekly-digest` | 36 | `newsletters/` 20 | **`003-RESOURCES/` 15** |

이 3개가 **vault 최다 태그 1·2·3위**다. 정당한 `tools/claude-code/changelog`(33)보다 많다.
데일리노트와 뉴스레터가 정상적으로 쌓인 결과 다수파가 됐고, 그 다수성 자체가
"한국어 기술 문서"면 무엇에나 붙는 힘이 됐다.

- **`min_add_confidence`(0.7) 상향은 해법이 아니다.** 컷오프는 "진짜 흔한 태그"와
  "오염돼서 흔해진 태그"를 구분할 수 없다. 08-06에 필터를 넣고도 09-02에 같은 3개가
  다시 통과한 이유가 이것이다.
- **해법은 레거시 오염 제거다.** 08-06 기록의 "기존 문서 누적 노이즈는 정리되지 않았다
  (일괄 정리 미착수)" 항목이 4주 뒤 재발의 직접 원인이 됐다. **오염이 폴더 경계와 정확히
  일치**하므로 안전하게 걷어낼 수 있다: `003-RESOURCES/`에서 이 3개 태그만 제거하고
  `notes/dailies/`·`newsletters/`는 그대로 둔다.
- `2-1-114`/`2-1-149`(각 2개 문서)는 아직 소수라 `similarity`가 아니라 **`concept_score`
  경로**로 통과한 것으로 보인다. 0.1 × 개념 수는 상한 없이 누적되어 **개념 7개만 겹치면
  유사도 0이어도 컷오프를 넘는다.** 방치하면 changelog 문서마다 자기 버전 번호를 심어
  같은 되먹임에 올라탄다.

#### 정리 실행과 검증 결과 (2026-09-02, 절반의 성공)

오염이 폴더 경계와 정확히 일치해 안전하게 걷어냈다. **`notes/dailies/`·`newsletters/`는 보존**하고
`003-RESOURCES/`(17) + `000-SLIPBOX/`(1) = **18개 문서**에서만 3개 태그를 제거,
버전번호 태그(`2-1-114`/`2-1-149`)는 별도 3개 문서에서 제거했다.

| 태그 | 정리 전 | 정리 후 | 잔존 위치 |
|---|---|---|---|
| `daily` | 44 | **32** | `notes/dailies/` only |
| `newsletter` | 36 | **20** | `newsletters/` only |
| `weekly-digest` | 36 | **20** | `newsletters/` only |

태그 순위가 뒤집혀 이제 `tools/ai-tools/release-notes`(35)·`tools/claude-code/changelog`(33)가
1·2위다. **되먹임의 동력이 사라졌다.**

- **✅ 검증됨**: 정리 후 같은 문서에 `vis tag`를 재실행하니 `newsletter`/`weekly-digest`/`daily`가
  **추천 목록에서 완전히 사라졌다.** 근본 원인 진단이 실측으로 확인됐다.
- **❌ 단, `vis tag`는 여전히 오탐을 쓴다.** 재실행에서 `ai/video-generation/stop-motion`
  (changelog와 완전 무관), `ai/agents/practical-guide` 등 5개가 새로 기록됐다.
  성격만 "vault 다수파 오염" → "**주제 인접 노이즈**"로 바뀐 것이다.
  → **운영 규칙은 그대로 유효**: `vis tag` 후 반드시 frontmatter를 눈으로 검증할 것.
- **vault는 git 저장소가 아니다.** 일괄 변경 전 반드시 백업할 것 — 되돌릴 방법이 없다.

## weekly-analytics 스크립트: 주간 창 필터 누락 (2026-09-02, W34 재계산으로 확정)

- **⚠️ `models`·`user_msgs`·`asst_msgs`에 주간 창 가드가 없었다.** 같은 루프의 `tools`와
  `files_edited`에는 `if inwk:`가 있는데 이 셋에만 없었다. 세션은 **주간 이벤트가 하나라도
  있으면 포함**되므로, 창을 걸친 세션이 **전체 이력을 이번 주 표에 쏟아붓는다.**
  W34 실측: 64개 세션 중 **1개**가 assistant 메시지 8888개 중 **772개(9%)**를 차지.
- **정정된 W34 수치** — `claude-opus-5` 5187 → **3636 (-1551, 30% 과다계상)**.
  실작업 믹스 opus 63%/fable 37% → **opus 54%/fable 46%**.
  → **W35 노트의 "실작업 믹스는 opus 63→67% / fable 37→33%로 불변"은 오류다.**
  참값은 **54→67%로 13pt 이동**. 오염된 W34를 기준으로 비교한 결과였다.
- `first_prompt`/`real_prompt`는 **의도적으로 창을 걸지 않는다.** 세션의 정체(cron/meta
  판정, 서사)를 나타내는 값이지 주간 물량이 아니다. 창을 걸면 창 이전에 시작된 cron 세션이
  분류를 벗어난다.
- **`wk_classify`의 클래스별 `files=`는 단순 합계였다** — 여러 세션에서 편집된 파일이 중복
  계상된다(real 164→146, worker 59→53). `wk_analytics`의 헤드라인은 합집합인데 같은 라벨이
  두 스크립트에서 다른 뜻이었다. 합집합으로 통일.
- **창을 두 번, 다른 이름으로 정의하고 있었다** (`WK_START/WK_END` vs `U_START/U_END`).
  어긋나면 합산과 병합이 **서로 다른 창을 조용히 설명**한다. `U_*` 없으면 `WK_*`로 폴백.
- `wk_analytics`는 창 경계를 걸친 gap의 앞단을 클램프하지 않아 `wk_union`(`max(a, WS)`)과
  세션당 최대 30분 어긋날 수 있었다. W34에서는 실차이 0이었지만 정합성 위해 수정.
- **회귀 검증법이 실제로 값을 했다.** 수정 후 헤드라인(196/132/64 · 41h 00m)은 원 리포트와
  완전 일치하고 모델 표만 움직였다 — **어디가 바뀌고 어디가 안 바뀌어야 하는지**를
  구분해 주는 게 이 검증의 핵심이다. 스크립트를 고칠 때마다 먼저 돌릴 것.
- **스크립트 3종은 2026-09-02에 dotfiles로 편입됐다**(`chore(skills)` 커밋).
  6주간의 "미추적" 경고는 해소. `stow -R --no-folding`이라 파일 단위 심링크로 걸린다.

## weekly-analytics W36: 웹 호출·모델 고정·재분류 함정 (2026-09-05)

- **WebSearch/WebFetch 전체 합은 cron이 지배한다.** W36 전체 73/54 중 stock cron이 48/31(62%).
  이벤트 수집기·확인기 프롬프트가 웹 검색을 강제하므로, 헤드라인에 전체 합을 쓰면 실작업
  리서치가 늘어난 것처럼 보인다. 모델 표(W35 교훈)와 같이 **클래스별 분해가 기본형**.
  실작업만 비교하려면 `WK_OUT` JSON을 읽어 `cls()`별 Counter를 따로 뽑아야 한다
  (`wk_classify.py`의 per-class 출력에는 Web 열이 없다 → 추가 후보).
- **수정판 스크립트로 이전 주를 재계산하면 분류가 1건 움직일 수 있다.** W35 real 18→17 /
  meta 3→4 — 09-02 수정 때 `META_MARKS`에 `weekly-newsletter`가 추가된 탓. 헤드라인
  (세션 수·활성·병합)은 불변이므로 "회귀 없음"이지만, **클래스별 n을 비교할 땐 재계산값을 쓸 것**.
- **`settings.json`의 모델 고정은 실작업 점유율로 바로 나타나지 않는다.** 09-02 "Fable 5.1
  고정" 커밋 이후에도 09-04 실작업은 opus 503 / fable-5-1 20. 세션 단위 `/model`이 설정을
  덮는 것으로 추정 — 로그의 `message.model`은 설정값이 아니라 **실제 응답 모델**이므로 이걸 믿을 것.
- **`git log --format=%ad | uniq -c` 월별 집계는 창 밖 커밋을 섞는다.** 09월 23건 vs 창 내
  23건이 우연히 같았지만, 주간 수치는 반드시 `--since/--until`에 KST 오프셋을 붙여 셀 것.

## weekly-newsletter: 문서 분석기의 mtime 필터는 태그 정리 주에 전량 오탐 (2026-09-05)

- 스킬의 SubAgent 3(주간 문서 분석)은 `stat -f %Sm`(mtime)으로 "이번 주 문서"를 고른다.
  W36 실행에서 20건이 잡혔는데 **19건이 09-02 vault 태그 정리로 mtime만 갱신된 3월 문서**였다.
  서브 에이전트는 이를 신규 문서로 요약해 반환했고, 관련 노트 슬러그(`Autoresearch-Pattern` 등)도
  실제 파일명이 아닌 **지어낸 이름**이었다.
- 판별법: frontmatter `created_at`(또는 `created`)과 `stat -f %SB`(birth time)를 대조. 둘 다 3월이면 오탐.
- 처방: 스킬 프롬프트의 필터를 mtime → `created_at` 기준으로 바꾸거나, mtime 후보에 대해
  `created_at`이 창 안인지 2차 검증을 강제할 것. Related Notes는 반드시 `find -name`으로 실존 확인 후 링크.
- 같은 실행에서 확인된 소스 공백: dailies 최신 06-29, coffee-time 최신 03-07(7주 연속 없음).
  W35·W36 모두 `analytics/claude-weekly/YYYY-WXX.md`를 업무 하이라이트 소스로 대체 사용했다.
- `date -j -f "%G-W%V-%u"` 역파싱은 macOS에서 실패한다. `date -v-mon`으로 월요일을 얻고 -2d 하는 우회가 동작함.

## vis add-related-docs: 관련 문서의 "태그:" 줄은 신뢰할 수 없다 (2026-09-10)

- `vis add-related-docs`가 삽입하는 Related 섹션의 각 항목 아래 `- 태그: ...` 줄이
  **대상 문서의 실제 frontmatter 태그와 무관**하다. 링크와 유사도 점수는 정확하지만 태그 줄만 틀림.
- 증거: `조회수 흐름을 바꾸는 유튜브 세팅 15가지 가이드.md`의 실제 frontmatter는
  `youtube/algorithm/...`, `content-creation/youtube/...` 등인데, Related 줄에는 `1`, `1의`, `2`로 표기됨.
  **관련 문서 10개 전부 동일한 3개 태그**가 붙는다 → 문서별 조회가 아니라 전역 태그 인덱스에서
  알파벳 순 상위 3개를 뽑는 것으로 보인다.
- vault 전역 분포로 재확인: `#1의, #2-1-114, #AI/claude-code/skills` / `#1, #1의, #2` 조합이 각각 수십~수백 건.
  `2-1-114`는 `Claude Code v2.1.114 Changelog` 제목에서 온 숫자 토큰 → 전역 인덱스에 숫자 오염이 있고,
  그 오염분이 알파벳 순 맨 앞이라 모든 문서에 반복 노출된다.
- 영향 범위: 표시용 주석 줄에 한정. **링크·유사도·frontmatter는 정상**이므로 문서 품질에는 영향 없음.
  단 이 줄을 읽고 "관련 문서의 주제"를 판단하면 안 된다.
- 검증 절차(매번 할 것): `vis tag` 실행 후 `sed -n '1,15p'`로 frontmatter 태그가 보존됐는지 확인.
  이번 실행에서는 내가 부여한 6개 태그가 전부 고신뢰도로 유지되어 덮어쓰기 없음.

## obsidian-summarize-youtube: 1차 경로가 살아있을 때가 있다 (2026-09-10)

- `youtube-transcript-api`가 **1차 시도에서 성공**(ko 트랙, 5.7KB). 2026-07-25 기록의 IP ban은
  상시가 아니라 간헐적이므로, yt-dlp 쿠키 fallback으로 곧장 건너뛰지 말고 1차부터 순서대로 시도할 것.
- 메타데이터는 스킬 문서가 지정한 Playwright MCP 대신 `yt-dlp --skip-download --print`로 취득.
  제목·채널·길이·게시일을 한 줄로 받아 토큰 비용이 브라우저 스냅샷의 수십 분의 1. **단 자막 다운로드와
  같은 명령에 섞지 말 것**(`--print`가 암묵적 `--simulate`을 켬 — 2026-07-25 기록과 동일 함정).
- 한국어 자막이 있는 영어 영상은 **더빙/자동번역 트랙**이라 이미 1차 번역을 거친 텍스트다.
  고유명사(채널명·툴명)와 수치는 원문 검증 없이 단정하지 말고 문서에 (불확실) 표기를 남길 것.

## weekly-analytics W37: 저장소 개명·무인 배치·META 임계 (2026-09-12)

- **저장소 개명은 세션 디렉토리를 가른다.** `soombicafe→soombi`(09-10), `automation_youtube→chalna`(09-12).
  스크립트는 `~/.claude/projects/*` 전체를 훑으므로 누락은 없지만 **per-project 표에 두 이름이 따로 뜬다.**
  `wk_analytics`의 git 카운트 루프도 디렉토리명(`-` 치환)으로 경로를 짚으면 `playlist_auto_uploader`
  처럼 언더스코어 저장소를 못 찾는다 — 실제 경로는 `ls ~/projects`로 먼저 확인할 것.
- **밤샘 자율 배치가 병합 활성을 부풀린다.** 09-06·09-12 두 밤(병합 13h 31m)은 사용자 부재 중 워커만 돈
  시간인데 `wk_union`은 유인/무인을 구분하지 않는다. "가동일 평균 10h 10m"의 1/5이 무인.
  → 워커 세션만의 병합 시간을 따로 뽑거나, 실작업 세션과 겹치지 않는 워커 구간을 "무인"으로 분리하는 열이 필요.
- **META 임계(활성 <600s)의 경계 사례**: 이 스킬의 자동 실행 세션 자체가 11분 걸리면 `real`로 분류된다.
  헤드라인엔 영향 없지만 real n 비교 시 1건 오차. 임계를 900s로 올리거나 `weekly-*` 마크는 시간 무관 meta로.
- **웹 호출 지배자는 주마다 바뀐다.** W36은 cron(62%), W37은 워커(임영웅 리서치 40/16)가 절반.
  클래스별 분해가 기본형이라는 결론은 같고, "cron만 빼면 된다"는 지름길은 틀린다.
- **`wk_extra`식 per-day 모델 표는 세션 시작일 귀속이라 틀린다.** 49시간짜리 세션이 모델 1,000건을 시작일에
  몰아넣는다. 스크립트가 per-day 모델을 기록하지 않으므로 일별 모델 서사는 세션 단위로만 쓸 것.
- 새 모델 ID 관측: `claude-opus-4-8`, `claude-sonnet-5`, `claude-haiku-4-5-20251001`. 모델 표 비교 시 열이 늘어난다.

## weekly-newsletter 스킬 실행 시 함정 3건 (2026-09-12, W37 실행)

- **스킬 문서의 날짜 계산 스니펫이 macOS에서 실패한다.** `date -j -f "%G-W%V-%u"`는 BSD date가
  ISO 주차 파싱을 지원하지 않아 빈 문자열을 뱉고, 이어지는 `-v-2d`도 연쇄 실패. 대체:
  ```bash
  DOW=$(date +%u); ISO_MONDAY=$(date -v-$((DOW-1))d +%Y-%m-%d)
  SATURDAY=$(date -j -v-2d -f "%Y-%m-%d" "$ISO_MONDAY" +%Y-%m-%d)
  ```
  (토요일 오전 실행 기준: 대상 주 = 지난 토 ~ 어제 금, `date +%G-W%V`의 주차와 일치)
- **`~/git/aboutme/AI-PROFILE.md`는 존재하지 않는다.** 톤 참조는 직전 뉴스레터
  (`newsletters/YYYY-W(XX-1)-newsletter.md`) 본문으로 대체. `find ~ -name AI-PROFILE.md`는 2분 넘게
  걸리니 시도하지 말 것.
- **입력 소스 대체 규칙(W36부터 고정)**: `notes/dailies/`는 2026-06-29 이후 비어 있음 →
  `analytics/claude-weekly/YYYY-WXX.md`가 주 소스. coffee-time은 2026-03-07이 마지막 →
  W38부터 섹션 제거 결정됨. 문서 분석기는 mtime 후보에 `created_at` frontmatter 검사를
  덧붙여야 태그 정리 주 오탐(W36 19/20건)을 막는다 — 현재는 서브에이전트 프롬프트에서만 보정,
  스킬 본문(`~/.claude/skills/weekly-newsletter/SKILL.md`)에는 미반영.

## weekly-analytics W38: 원격 기계 사각지대·무인 판정·서브에이전트 이동 (2026-09-19)

- **⚠️ 로컬 로그 ≠ 사용자 전체 사용량.** W38 soombi 커밋 113건 중 이 맥 세션의 `git commit` 호출은 5건,
  chalna 33건 중 ~4건. 나머지는 Windows PC의 Claude 세션(커밋 "Windows cp949", 발화 "window pc 에서 inject").
  맥 쪽 soombi 세션은 "최신화 해줘"(pull)만 반복한다. **저장소 커밋 수 vs 로컬 `git commit` 호출 수**를
  매주 대조할 것 — 호출 수는 jsonl에서 assistant `tool_use.input.command`에 `git commit` 포함 여부로 센다.
- **zsh는 따옴표 없는 `$VAR`를 단어 분할하지 않는다.** `R="--since=.. --until=.."; git log $R`는 인자 1개로
  넘어가 **에러 없이 빈 출력**. 배열 `R=(--since=.. --until=..)`로 쓸 것.
- **"무인 시간" 판정법**: 워커-only 병합 구간에서 실작업-only 병합 구간을 뺀 차집합. W38 = 0h 35m.
  보조 증거로 실작업 세션의 **사람 입력 프롬프트 시각 분포**(`<task-notification`·`<system-reminder`·
  `<command-`·`<teammate-message`·`Another Claude session sent a message` 제외)를 볼 것 — 00~04시 31%였고 05~07시 0.
- **위임이 agent-team 워커 → 직접 Agent 서브에이전트로 이동**(워커 54→23, 서브에이전트 로그 16→95).
  서브에이전트 구간은 `wk_union` 병합에 안 잡히므로 병렬 계수가 위임 물량을 더 이상 반영하지 못한다.
  playwright도 워커 482→12 대신 서브에이전트 429 — **top-level 표만 보면 브라우저 자동화가 준 것처럼 오독**.
- `wk_classify`의 META 경계 문제(자동 실행 analytics 세션 12m → real) 2주 연속 미이행. 빈 세션(msgs=0)도 real로 샌다.

## weekly-newsletter W38 실행: haiku 분석기의 주차 혼입 (2026-09-19)

- **haiku 업무 분석기가 전주 리포트 내용을 이번 주 성과로 섞었다.** W37 수치를 "헤드라인만 참고"하라고
  허용했더니 "288곡 회수", "09-12 사전 승인 배치"(둘 다 W37 사건)가 W38 하이라이트로 들어왔다.
  → 주간 리포트(`analytics/claude-weekly/YYYY-WXX.md`, ~24KB)는 **메인이 직접 Read**하는 편이 정확하다.
  포커스 판정·수치 인용이 핵심이라 요약본으로는 부족하다. 서브에이전트는 문서 분석기만으로 충분.
- 문서 분석기가 뽑은 인용문은 `grep`으로 원문 존재를 확인한 뒤 싣는다(이번엔 둘 다 실재).
- 스킬 본문(`SKILL.md`)은 W38 시점에도 커피타임 SubAgent 2·`created_at` 미반영 그대로다(2주째).

## obsidian-summarize-youtube: vis tag 대소문자 중복 · zsh `===` 함정 (2026-09-23)

- `vis tag`는 고신뢰도 태그를 **소문자로 정규화해 append**한다. 내가 `AI/cost-optimization/token-efficiency`를
  이미 달아둬도 `ai/cost-optimization/token-efficiency`가 **대소문자만 다른 중복**으로 추가됨.
  → 실행 후 frontmatter 확인 시 `ai/` 소문자 중복 줄을 찾아 삭제할 것(vault 관례는 `AI/` 대문자).
- zsh에서 `echo ===`는 `=cmd` 경로 확장으로 해석돼 `== not found`로 **체인 전체가 중단**된다.
  명령 사이 구분선은 `echo '---'`처럼 따옴표로 감쌀 것.
- 한국어 원본 영상의 자동 자막은 모델명이 심하게 깨진다(Sol→"쏘리", effort→"F42", Three.js→"3J").
  복원은 문맥 추정이므로 문서에 (추정) 표기 + Uncertainty Map에 원문 자막을 남길 것.

## weekly-analytics W39: Workflow 에이전트 누락·원격=팀원·해시 대조 실패 (2026-09-26)

- **⚠️ `wk_analytics.py`는 Workflow 에이전트 로그를 못 본다.** glob이 `<proj>/<session>/subagents/*.jsonl`인데
  Workflow가 띄운 에이전트는 `subagents/workflows/<wf_id>/agent-*.jsonl`(+`journal.jsonl`)에 쌓인다.
  W39 창 내 240개·8h 43m·sonnet-4-6 2,499건이 통째로 누락(서브에이전트 6h 45m보다 큼). 전 기간 1,393개.
  수정: glob에 `*/*/subagents/workflows/*/agent-*.jsonl` 추가(`journal.jsonl` 제외) 후 **W38 재계산으로 회귀 검증**.
  W39 측정용 임시본은 `/tmp/wk39d/wf.py`.
- **W38의 "원격 = 사용자 본인의 Windows PC" 추정은 틀렸다 — 팀원이다.** 09-23 발화 "팀원은 맥을 사용하지 않기 때문에…".
  커밋 작성자가 전부 `zionge2k`여도 작업자는 다를 수 있다. 커밋 메시지의 "언니"·"사장님"도 단서였다.
  이 리포트는 "이 맥 사용자 1인의 사용량"이지 팀 사용량이 아니다.
- **커밋 해시 ↔ 세션 tool_result 대조는 안 된다.** `[branch abc1234]` 패턴으로 잡으면 playlist 호출 27건 중 6건만 일치
  (출력 생략·다중 커밋·형식 차이). 맥/원격 귀속은 `git commit` 호출 수 + 시각 대조(세션 발화 시간대 vs 커밋 시각)로 할 것.
- **`grep -o '"name":"mcp__…"'`로 도구 사용을 세면 안 된다** — 도구 스키마 목록(deferred tools 안내)에도 같은 문자열이
  들어 있어 실호출보다 수십 배 부풀려진다. 반드시 `assistant` 레코드의 `tool_use` 블록만 셀 것.
- **stock cron 누락처럼 보여도 휴장일일 수 있다.** 09-24·25 저녁 브리핑 부재는 `~/projects/stock/logs/*.log`의
  `Holiday … no briefing`으로 확인됨(추석). 장애 판정 전에 로그부터 볼 것.
- 병렬 계수는 위임이 부모 세션 안(서브에이전트·Workflow)으로 들어가면서 "동시에 연 세션 수"만 잰다.
  위임 강도는 *(서브에이전트+Workflow 활성) / 병합 활성* 비율로 따로 볼 것(W39 = 0.52).

## weekly-newsletter W39 실행 메모 (2026-09-26)

- **haiku 문서 분석기는 "AI 코딩 도구" 필터를 좁게 읽어 AI 음악(Suno) 문서를 제외한다.** W38 호는
  같은 계열 문서를 기술 트렌드 머리기사로 썼으므로, 프롬프트에 "생성형 AI 도구 전반 포함"을 명시할 것.
- **리포트의 저장소 커밋 수는 `git log --all`(전체 브랜치) 기준이다.** 기본 브랜치만 세면
  soombi 33 / chalna 18로 과소집계되어 리포트 값(34/35)과 어긋난다. 사각지대 비율 검증 시 `--all` 사용.

## 서브에이전트 모델 선택: 우선순위·실측·미로딩 에이전트 (2026-09-29)

- **모델 결정 순서(공식 문서)**: 호출 시 `model` > 에이전트 frontmatter `model:` > `CLAUDE_CODE_SUBAGENT_MODEL`
  > 메인 세션 모델. 환경변수는 "미지정일 때의 기본값"일 뿐 덮어쓰지 않는다
  (강제하려면 `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`). 에이전트 frontmatter는 `effort:`도 지원하나
  **호출 시 effort 지정은 불가** — effort는 frontmatter로만 고정된다.
- **환경변수에 버전을 고정하면 조용히 낡는다.** `claude-sonnet-4-6` 고정 탓에 최근 30일 서브에이전트·Workflow
  실행 파일의 93%(1,412/1,515)가 두 세대 전 모델이었다. 별칭 `sonnet`으로 교체.
- **claude-code-guide 에이전트 답변도 원문 대조 필수.** "에이전트 frontmatter에 effort 없음"이라 답했으나
  문서 표에는 `effort` 행이 있었다. 핵심 주장은 WebFetch로 원문 인용을 받아 확인할 것.
- **에이전트 frontmatter의 `description:`은 반드시 한 줄이어야 한다.** 빈 줄 + `Examples:` 블록이 여러 줄로
  이어지던 8개(code-review-expert, ddd-expert, kent-beck-expert, prompt-expert, refactoring-expert,
  spring-expert, vibe-coding-coach, zettelkasten-expert)가 **에러 없이 조용히 로딩 누락**되고 있었다.
  줄바꿈을 리터럴 `\n`으로 이어 한 줄로 합치니 전부 로딩됨(2026-09-29 수정).
  검증법: `claude -p --model haiku "사용 가능한 subagent_type 이름만 나열"`을 새 프로세스로 실행해 목록 대조.
- 실측 스크립트 요령: 서브에이전트 실제 모델은 `~/.claude/projects/*/*/subagents/**/*.jsonl`의 assistant
  `message.model`, 요청 모델은 메인 세션 jsonl의 `tool_use`(name=Agent) `input.model`에서 센다.

## weekly-analytics W40: 클라우드 사각지대·top-level 강도 붕괴·분류 누수 2종 (2026-10-03)

- **⚠️ 클라우드가 세 번째 관측 사각지대다.** `RemoteTrigger`(create/update/list_runs)로 띄운 원샷 루틴과
  claude.ai/code 클라우드 세션은 로컬 jsonl을 남기지 않는다. 흔적은 ① 부모 세션의 `RemoteTrigger` tool_use
  (`input.body.name`·`job_config.ccr.session_context.model`에 루틴명·모델이 있음) ② **커밋 작성자 `Claude`**
  (`git log --format=%an`) 둘뿐. W40 yt-postflow는 커밋 57 / 로컬 `git commit` 호출 0이었다.
- **커밋 시각은 `--date=format-local:`로 볼 것.** `--date=format:`은 커밋에 기록된 TZ를 그대로 써서, 클라우드
  커밋(UTC)이 9시간 앞당겨져 보였다(03:05 ↔ 실제 12:05 KST).
- **top-level 시간당 호출(5주간 84~99/h)은 위임이 부모 세션 안으로 들어가면 무너진다.** W40은 53/h였지만 서브에이전트
  5,064 + Workflow 601을 더하면 154/h다. 강도 비교는 **top-level과 전체를 병기**하고, 브라우저(playwright +
  `mcp__Claude_Browser__*`)는 서브에이전트 포함 열을 기본으로 둘 것.
- **분류 누수 2종(미수정):** `-private-tmp` 디렉토리의 `claude -p` 프로브(메시지 1·활성 0)와 메시지 0인 빈 세션이
  `real`로 샌다. `wk_classify.cls()`에 `user_msgs == 0 or active_s == 0 → meta`를 넣으면 막힌다. W40은
  `/tmp/wk40/derive.py`의 `cls2()`로 수동 보정(real 17 → 13).
- **서브에이전트 모델 전환을 일별로 보면 정책 효과가 바로 보인다.** sonnet-4-6이 09-29까지 100% → 09-30부터 0%
  (sonnet-5-5로). 09-29 `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 커밋과 사용자의 명시 지시("sonnet 5.5로")가 같은 날이라
  원인 분리는 불가. Workflow 에이전트는 09-26 실행분이라 여전히 sonnet-4-6.
- `wk_analytics.py`의 Workflow glob 미편입 2주 연속(W39 권고). 이번 주는 Workflow 3회뿐이라 영향은 작았다.

## weekly-newsletter: 스킬 인수가 본문의 `$0`/`$1`을 치환한다 (2026-10-03, W40 실행)

- 인수를 붙여 실행하면(자동 실행 컨텍스트 문구 등) 스킬 본문의 `$1`·`$0`가 **인수 단어로 치환**된다.
  W40에서 awk 필터 `'$1 >= start ... {print $0}'`가 `'실행 >= start ... {print 컨텍스트입니다.}'`로 깨져서 로드됐다.
  `if [ -n "$1" ]`도 같은 이유로 깨진다. → 서브에이전트 프롬프트에 그대로 복사하지 말고 `$1`/`$0`을 복원할 것.
  근본 해결은 SKILL.md의 필터를 `$N` 없는 형태(예: `find -newermt START ! -newermt NEXT_DAY`)로 바꾸는 것. 미착수.
- 기존 티켓(SubAgent 2 제거·`created_at` 필터 명문화·날짜 스니펫 교체)은 W40 기준 4주째 미반영.

## OBS 설정 조사 세션: 토큰 노출·ffmpeg 조용한 실패·서브에이전트 추가 지시 누락 (2026-10-03)

- **⚠️ OBS 프로필 `basic.ini`를 통째로 출력하지 말 것.** `[YouTube]` 섹션에 OAuth `RefreshToken`/`Token`이
  평문으로 들어 있다(스트림 키는 `service.json`). 설정 확인은 `grep -E '^(Encoder|FPSCommon|OutputC[XY]|SampleRate)='`
  처럼 필요한 키만 뽑을 것. 이번에 `cat`으로 읽어 토큰이 세션 기록에 남았다.
- **ffmpeg concat demuxer는 비트 심도가 섞이면 조용히 깨진다.** 24bit + 16bit WAV를 합치면 decode error를 내면서도
  **exit 0**이고 결과 길이만 짧아진다. → 합치기 전 `ffprobe -show_entries stream=codec_name,sample_rate,channels`를
  `sort | uniq -c`로 돌려 한 줄인지 확인, 합친 뒤 입력 길이 합계와 결과 길이를 대조할 것.
- zsh에서 concat 목록의 작은따옴표 이스케이프는 `${f//\'/\'\\\'\'}`로 쓰면 깨진다.
  `q="'\\''"; printf "file '%s'\n" "${f//\'/$q}"`처럼 변수로 뺄 것.
- **실행 중인 서브에이전트에 `SendMessage`로 보낸 추가 지시는 반영되지 않은 채 끝날 수 있다.** 3건 중 1건만 반영됐다.
  완료 보고에서 반영 여부를 확인하고, 빠졌으면 완료 후 재개 메시지로 다시 보낼 것.
- 재개된 서브에이전트의 완료 알림에는 **마지막 메시지만** 실려 본문이 잘린다(체크리스트만 도착, 출처 누락).
  프롬프트에 "전체를 한 응답에, N줄 이내로"를 명시하면 막힌다.

## obsidian-summarize-youtube: 설명란이 자막보다 정확한 원문이다 (2026-10-06)

- **자막 교정의 1차 근거는 영상 설명란과 챕터다.** `yt-dlp --skip-download --print "%(description)s"`와
  `--print "%(chapters)j"`로 받는다. 프롬프트·태그명 같은 영문 원문이 설명란에 그대로 있어, 자동 자막의 음차
  오인식(`서브드롬`→Sub Drop, `8세토 프립`→Falsetto Flip)을 추측 없이 교정할 수 있었다.
- 고정 댓글은 `--write-comments --extractor-args "youtube:max_comments=30,30,0,0;comment_sort=top"`로 받아
  `info.json`의 `comments[].is_pinned`로 찾는다. 영상이 "고정 댓글에 있다"고 해도 실제로는 없을 수 있으니 확인 후 쓸 것.
- **본문에 `[[#6. 제목]]` 같은 헤딩 앵커 링크를 쓰지 말 것.** vis가 인라인 `#`을 태그로 읽어 `6` 같은 가짜 태그가
  인덱스에 들어간다(관련 문서 목록의 `태그: 6`, `7`이 이것). 평문("하단 6장")으로 적을 것.
- **`vis add-related-docs`는 링크를 파일명이 아니라 `id`로 만든다.** `id`에 `:`가 있는 문서는 깨진 링크가 된다
  (`[[Suno AI: …]]` ↔ 실제 파일 `Suno AI - ….md`). 실행 후 링크 대상 파일 존재 여부를 스크립트로 확인할 것.
- 이번에는 `youtube-transcript-api`가 차단 없이 한 번에 성공했다. fallback 체인은 실패했을 때만 탈 것.

## 출력 상한 16,384는 자체 설정이었고 서브에이전트에도 걸린다 (2026-10-06)

- `CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384`는 플랫폼 한계가 아니라 초기 구성(2026-03-05)부터 `settings.json`에 걸어 둔 값이었다.
  `MAX_THINKING_TOKENS=16000`과 거의 같아, 사고가 길어지면 본문 자리가 거의 남지 않는 구성이었다. → 32000으로 상향.
- **이 상한은 서브에이전트에도 적용된다(2.1.291 실측).** 최근 45일 로그에서 `stop_reason == "max_tokens"`이고
  `usage.output_tokens == 16384`인 응답이 서브에이전트 282회, 메인 132회였다. "서브에이전트에는 적용 안 됨"이라는
  웹 자료(오래된 GitHub 이슈)는 이 환경과 맞지 않았다. **문서 조사와 로그가 충돌하면 로그를 따를 것.**
- 잘림 여부 점검: `~/.claude/projects/**/*.jsonl`에서 assistant 메시지의 `stop_reason`과 `usage.output_tokens`를 센다.
  서브에이전트는 경로에 `/subagents/`가 들어간다.
- `claude -p --output-format json`의 `modelUsage.<model>.maxOutputTokens`는 **모델 최대치(Sonnet 5.5 = 128000)** 이지
  현재 적용된 상한이 아니다. 설정값 확인 용도로 쓰지 말 것.
- 설정 변경은 새 세션부터 적용된다. 상한에 맞춰 둔 우회 규칙(작업 쪼개기 등)은 새 세션에서 확인한 뒤에 풀 것.

## 이미지형 강의록 PDF 학습: OCR 초안 + 서브에이전트 육안 교정 (2026-10-06)

- 방송대 강의록 PDF는 "Microsoft: Print To PDF" 산출물이라 **텍스트 레이어가 없다**. `pdftotext` 결과가
  글머리표만 나오면 이미지형으로 판단하고 바로 OCR 경로로 갈 것. 같은 과목의 PPTX는 XML에서 텍스트가 그대로 나온다.
- macOS Vision OCR(`VNRecognizeTextRequest`, ko-KR)은 한글 본문은 잘 읽지만 **한자 당사자 표기(甲·乙·丙)를
  "4", "Z", "#", "변", "거" 등으로 깨뜨린다.** 법학 사례에서는 당사자가 뒤바뀌므로 OCR만으로 쓰면 안 된다.
- 통한 절차: OCR 초안 생성 → 강의별 서브에이전트가 Read(pages, 20쪽 단위)로 원본을 보며 교정 전사 →
  메인이 숫자·표·판례 쪽을 표본 대조. 321쪽 7개 강의가 병렬로 수 분 내 끝났고 표본 대조에서 불일치 0건.
- 전사 프롬프트에 "슬라이드에 없는 조문·판례 번호 추가 금지", "확신 없으면 `[불확실]` 표시"를 넣으면
  원본 자체의 오류(같은 사건번호에 법원명이 다른 경우 등)를 고치지 않고 주석으로 올려 준다.

## Claude Docs 초안을 Word 제출본으로 옮기기 (2026-10-08)

- 이 Mac에는 LibreOffice·Word·Pages·한글이 없다. `/opt/homebrew/bin/soffice`는 래퍼만 남아 있어
  docx 스킬의 `soffice.py` 변환이 **오류 없이 멈춘다**(180초 타임아웃). 렌더 확인은
  `qlmanage -t -s 1600 -o <dir> file.docx`(첫 쪽 PNG)로 대체. Quick Look은 쪽 나눔·탭 위치·표 너비를
  무시하므로 뒤쪽 내용은 "그 지점부터 시작하는 임시 docx"를 만들어 한 장씩 본다.
- Claude Docs `export`는 base64를 대화로 돌려줘서 디스크에 못 쓴다. 대신 `read`로 전문을 한 번 읽으면
  그 XML이 세션 트랜스크립트(`~/.claude/projects/<proj>/<스크래치패드와 같은 id>.jsonl`)에 남으므로
  스크립트로 꺼내 변환하면 본문을 다시 타이핑하지 않아도 된다. tasks 경로의 세션 id는 다른 id다.
- 목록을 `기호 + 탭`으로 만들면 뷰어마다 탭 위치가 달라진다. `기호 + 공백` + 내어쓰기가 어디서나 맞는다.
- `rm`이 trash로 alias되어 있어 없는 경로를 지우면 실패하고 `&&` 체인이 끊긴다.
- **Google Docs는 `lineRule="exact"`(고정 줄간격)를 지원하지 않는다.** docx를 올리면 숫자는 그대로 두고
  `auto`로 바꾼다(`line=320 exact` 16pt → `1.33배`). 맑은 고딕은 1.0배가 글자 크기의 약 1.73배라
  11pt 본문이 16pt가 아니라 약 25.5pt 간격으로 보인다(실측). 어디서나 같게 보이려면 처음부터
  `auto` 배수(예: 0.93배 ≈ 17.8pt)로 준다. 확인법: 공유 문서를 `…/export?format=docx`로 받아 spacing 비교.
- 렌더 확인 수단이 없을 때는 사용자가 실제로 보는 뷰어(Google Docs 등)를 먼저 물어볼 것. Playwright로
  공유 문서를 열면 줄 간격을 px로 잴 수 있다(100%에서 A4 폭 ≈ 794px, 1px = 0.75pt).

## 유튜브 한국 음악 차트 조사 (2026-10-08)

- 유튜브 공식 `charts.youtube.com`은 검색/페치로 직접 접근이 안 됨. 대체 소스:
  - `kworb.net/youtube/insights/kr_daily.html` — 일간 top 20(스트림 기준), WebFetch로 바로 읽힘
  - `soundcharts.com/en/charts/youtube/south-korea` — 주간 top(조회수)
  - 쇼츠 차트는 더팩트 등 기사 인용으로만 확인 가능
- 유튜브는 **장르별 집계를 공개하지 않음**. "핫한 장르"는 차트 상위곡을 수동 분류해 추정해야 함.
- 서브에이전트는 다른 모델 토큰을 소모함 → 사용자 주간 한도가 낮을 땐 메인 모델이 직접 WebSearch/WebFetch.

## Pinterest 핀 단위 인기 지표: 공식 API 불가, 비공식 PinResource로 가능 (2026-10-09)

- 공식 API v5는 **내 소유 Pin**의 지표와 **키워드 단위** Trends만 제공. 타인 공개 Pin의 저장·반응 수 필드 없음.
  Trends `region` enum에 KR 없음. (OpenAPI 스펙 v5.28.0 직접 파싱으로 확인)
- 핀 상세 페이지 UI의 하트(반응) 수는 **비공식 내부 엔드포인트**로 로그인 없이 조회됨 (HTTP 200 확인):
  ```
  GET https://www.pinterest.com/resource/PinResource/get/
      ?source_url=/pin/{id}/
      &data={"options":{"id":"{id}","field_set_key":"detailed"},"context":{}}
  헤더: X-Requested-With: XMLHttpRequest, X-Pinterest-PWS-Handler: www/pin/[id].js, 데스크톱 UA
  ```
  `resource_response.data` 주요 필드:
  - `reaction_counts` → `{"1": 53}` 형태. 키 `1`이 하트(반응). UI의 하트 수치와 일치.
  - `aggregated_pin_data.aggregated_stats.saves` → 같은 이미지의 **플랫폼 전체 누적 저장 수** (예: 13554). 인기 판별엔 이 값이 핵심.
  - `repin_count` → 이 Pin 사본 하나의 저장 수. 대부분 0이라 단독으로는 무의미.
  - `comment_count`, `share_count`, `created_at`.
- **함정**: 핀 페이지 HTML을 curl로 받으면 셸만 오고 Pin JSON은 없음. 데이터는 위 resource 엔드포인트로 따로 호출해야 함.
- **함정**: Playwright MCP 브라우저는 사용자 로그인 세션을 그대로 씀. 로그인 상태에서는 핀 URL이 난독화 ID(`/pin/ARqL...`)로 리다이렉트됨. 숫자 ID는 비로그인 curl에서 그대로 동작.
- ToS상 무허가 자동 수집은 금지. 소량 수동 조회·연구 용도로만.

## Pinterest 수집기 실측 수치와 서브에이전트 운영 메모 (2026-10-09)

- 프로젝트: `~/projects/pinterest-loop-refs` (`uv run plr run --only <slug>`). 비공식 `BaseSearchResource` + `PinResource` 조합, 로그인 불필요.
- **실측**: 한·영 검색어 각 2페이지(≤100건) → 광고·동영상·1200px 미만 제외 + 서명 중복 제거 후 **장면당 38~76건** 남음.
  상세 호출 2초 간격이라 **장면당 2~4분**. 14장면 100장 수집에 차단·오류 0건. 캐시: 검색 55개, 핀 793개.
- **가로 비율 수율은 7%** (100장 중 7장이 가로비 ≥1.3). 롱폼 가로용이면 비율 필터 없이 받은 뒤 검수에서 고르거나,
  세로 이미지를 아웃페인팅할 전제가 필요.
- `aggregated_stats.saves`가 없는 핀이 장면에 따라 0~47% 섞임 (최근 핀으로 추정). 상위 N개에는 영향 없었지만 "전부 0"이면 응답 형식 변경 의심.
- 검색 결과에는 저장 수가 없고 상세 호출에만 있음. 서명(`image_signature`) 기반 중복 제거는 검색 결과만으로 가능.
- **Agent 도구 함정**: `name`을 붙인 에이전트를 10개쯤 띄운 뒤 `respawn pane failed: fork failed: Device not configured`로 생성 실패.
  `name` 없이 띄우면 백그라운드 모드로 정상 동작하며 `SendMessage`는 agentId로 가능. 결과 도착 알림은 중복으로 오는 경우가 있음.
- 리뷰 루프 수확: 플랜에 완전한 코드를 넣어도 품질 리뷰(opus)가 Task마다 운영상 결함 1~2건을 잡음
  (실패 본문 캐시 오염, 404로 배치 사망, 부분 다운로드 파일 잔존, 미완료 장면 영구 skip). 일회성 배치 도구라도 "재실행했을 때"를 기준으로 리뷰시키는 게 효과적.

## weekly-analytics W41: Workflow 로그가 전체 호출의 61%, 프로브 누수는 `< 60`으로, 커밋 주체는 Workflow 안 (2026-10-10)

- **Workflow 에이전트 로그(`subagents/workflows/*/agent-*.jsonl`)가 이번 주 도구 호출 29,463건 중 17,972건이다.**
  `wk_analytics.py`가 안 읽는 상태로 3주째. 파생 스크립트로 매주 다시 세는 비용이 본 집계 편입보다 커졌다.
  편입 시 W39~W41 위임 비율이 소급 변경되므로 재계산 표를 함께 붙일 것.
- **W40 권고 `active_s == 0 → meta`는 `-private-tmp` 프로브를 못 잡는다.** 프로브 활성이 0이 아니라 수 초(≈5s)다.
  `user_msgs == 0 or active_s < 60`이어야 한다. 이번 주도 수동 보정(real 24 → 21).
- **저장소 커밋 수와 맥 `git commit` 호출 수의 차이는 클라우드가 아니라 Workflow 에이전트 안의 커밋일 수 있다.**
  W41 playlist 커밋 104 / 맥 호출 61인데, Workflow 에이전트 안에서 `git commit` 216회·`gh pr` 44회가 돌았다.
  사각지대 판정 전에 workflow 로그의 Bash `git commit`을 먼저 셀 것(W40의 `Claude` 작성자 기준만으로는 부족).
- **Workflow 이름은 부모 세션 `Workflow` tool_use의 `script` 안 `meta.name` 정규식 또는 `scriptPath` basename으로 복원된다.**
  `resumeFromRunId`는 이번 주 0회. 같은 스크립트를 `scriptPath`로 재호출하는 패턴이 표준이었다(11회·7회).
- **Agent 호출의 `subagent_type`·`model` 인자를 세면 "어떤 역할이 표준이 됐는지"가 바로 보인다.**
  W41: suno-translator 133 · lyrics-reviewer 79 · song-lyric-writer 74, model=opus 214 / 기본값 217.
- **top-level 일별 모델 분포는 전환 계기와 같이 봐야 한다.** 10-08 18:45 dotfiles 커밋(fable 기본값) → 23:39 "토큰 2%" 발화 →
  10-09 100% fable. 커밋 시각은 `git log --date=format-local:`로 볼 것(W40 교훈 재확인).
- 서사 추출은 opus 서브에이전트에 `/tmp/wk41/prompts.txt`(사람 프롬프트 526건, 87KB) + `commits.txt`를 주고 4개 섹션을
  파일로 쓰게 했다. 6분·18 tool uses. **commits.txt를 `head -70`으로 자르면 오후 커밋이 빠진다** — 서브에이전트가 git log를
  다시 봐서 메웠다. 다음엔 자르지 말고 저장소별 전체를 줄 것.
- 이번 주 `<pasted_content>` 28회는 top-level 사람 메시지 중 태그 포함 수로 셌다. W40 12회와 같은 기준.

## weekly-newsletter W41 실행 메모 (2026-10-10)

- **날짜 스니펫은 이번에도 실패했다.** `date -j -f "%G-W%V-%u"`는 macOS에서 빈 문자열을 돌려주고 이후 `-v-2d` 변환까지
  연쇄 실패한다(에러는 나지만 `WEEK_NUM`만 살아 있어 이어 가기 쉬움). 토요일 실행이면 **토요일 = 오늘 - 7일, 금요일 = 오늘 - 1일**로
  직접 계산하는 편이 빠르다. 날짜 확인은 `date -j -f "%Y-%m-%d" "$d" "+%a W%V"`로.
- **입력 소스 상태(W41 기준, 변동 없음)**: dailies 최신 2026-06-29, coffee-time 2026-03-07 → 주간 분석 리포트
  (`analytics/claude-weekly/2026-W41.md`, 44KB)를 메인이 직접 Read. 문서 분석기만 sonnet 서브에이전트 1개(20초, 55K 토큰).
  `find -newermt START ! -newermt NEXT_DAY` + `created_at` 2차 필터로 후보 1건 → 통과 1건, 오탐 0.
- **문서 `id`와 파일명이 다르면 파일명으로 링크한다.** 이번 Suno 문서는 id에 `｜`·`[이거]`가 있고 파일명은 ` — `다.
  `[[id]]`로 걸면 깨진다. Related Notes 작성 후 `grep -o '\[\[[^]|#]*'` → `find -name "$t.md"`로 전수 확인할 것.
- 인용문 원문 확인(`grep -n "힌트"`)은 1회로 끝났다. 서브에이전트가 돌려준 인용은 원문 43행과 일치.
- 스킬 본문 티켓(SubAgent 2 제거·`created_at` 명문화·날짜 스니펫·awk `$1` 치환)은 **5주째 미반영**. 집계 스크립트 Workflow glob은 3주째.

## weekly-newsletter W42 실행 메모 (2026-10-17)

- **서브에이전트를 띄우기 전에 소스 존재부터 확인할 것.** 스킬 본문대로 3개를 병렬로 띄웠더니 dailies·coffee-time
  분석기 2개가 "없음"만 돌려주고 약 9만 토큰을 썼다(상태는 W41과 같다: dailies 06-29, coffee-time 03-07).
  `command ls notes/dailies | tail -1; command ls coffee-time | tail -1` 한 줄이면 판정된다(`ls`는 eza 별칭이라 `grep`과 섞이면 빈 결과).
- **"기술 무관" 문서도 `created_at`을 주간 분석 타임라인과 대조할 것.** 분석기는 색채 강의 5건을 "외부 공유 부적합"으로 분류했다.
  그런데 생성 시각(10-13 01:57~02:02)이 같은 세션의 02:52 색 배합 결정 직전이었다. **결정에 앞선 사전 조사**라는 맥락이
  생기자 기술 교훈(RAW/LOG ↔ 축별 조사 깊이, 컬러 트렌드 ↔ 출처 규칙)으로 옮길 수 있었다. Highlights 절만
  `awk '/^## 1\. Highlights/{on=1;next} on&&/^## 2\./{exit} on'`로 뽑으면 5건을 합쳐 약 6KB다.
- 주간 분석 창은 **토 08:00 ~ 다음 토 08:00**이라 토요일 새벽 작업이 들어 있다. 뉴스레터 기간(토~금)에는
  금요일 항목에 "금요일 밤 연장"으로 접어 넣고, 머리말에 경계를 밝혔다.

## 방송대 객관식 과제: 공식 양식 PDF에 직접 표시하기 (2026-10-11)

- LibreOffice가 없어 docx → PDF 변환이 막혀도 우회할 수 있다. 양식이 Google Docs 공유 링크면
  `…/document/d/<id>/export?format=pdf`로 **교수 원본 양식 그대로의 PDF**를 받고, 그 위에 글자를 얹는다.
- `uv run --no-project --with pymupdf`면 시스템 설치 없이 PyMuPDF를 쓴다. `page.find_tables()`가 병합 셀까지
  셀 좌표를 돌려주므로(병합으로 사라진 칸은 `None`) 행 번호 텍스트로 문항을 확인하고 셀 중앙에 `■`를 넣는다.
- 한글·`■` 글꼴은 `/System/Library/Fonts/Supplemental/AppleGothic.ttf`(단일 TTF)가 임베드된다. `subset_fonts()` 필수.
- 양식의 `이름:` 줄은 뒤에 공백이 길게 붙어 있다. 줄 끝이 아니라 `search_for("이름:")`의 오른쪽 끝에 맞춘다.
- 검증은 `pdftotext -layout` 한 번이면 된다. 행마다 `■` 위치가 열로 보인다. 그 뒤 PNG로 육안 확인.
- `~/Downloads`는 세션 첫 시도에서 `Operation not permitted`가 났다가 다음 턴에 열렸다. 권한 오류는 한 번 더 시도.
- AI 사용 설문은 본인 사실·의견이라 추정하지 말고 AskUserQuestion으로 묻는다(선택지 4개 제한에 맞춰 묶기).

## 방송대 과제 지침: AI 사용 가능 여부 표는 렌더링해서 확인 (2026-10-11)

- 과목마다 생성형 AI 정책이 다름. 경제학의 이해는 허용, 성·사랑·사회(공통형 서평)는 `사용불가`에 ○.
- `pdftotext -layout`만 보면 ○가 어느 칸인지 모호함. `pdftotext -bbox`로 ○의 x좌표를 열 제목 x범위와
  비교하거나 `pdftoppm -png`로 렌더링해 눈으로 확인할 것.
- 지침 2쪽에 `[참고문헌]`이 따로 있을 수 있음. 검색 요약(구글 AI 답변)은 도서 누락·서지 오류가 있었으므로
  지침 원문을 끝 페이지까지 먼저 읽을 것.
- 작성을 시작하기 전에 AI 정책부터 확인하고 사용자에게 알릴 것.
- 지정 도서를 구하는 가장 빠른 길은 방송대 중앙도서관. 로그인 없이 소장 조회가 된다:
  `https://library.knou.ac.kr/search/tot/result?st=KWRD&si=TOTAL&q=<검색어>` (Playwright로 연 뒤 같은 출처 `fetch`로
  여러 권을 한 번에 조회 가능). `[전자책]` 항목의 `URL` 링크는 도서관 로그인 뒤 열린다.
  성·사랑·사회 2026-2 지정 도서 5권은 모두 전자책 소장이었다.
- 밀리의 서재 검색은 로그인 필수라 자동 확인 불가. Google Books API는 WebFetch에서 429. 알라딘 검색 결과 페이지는
  WebFetch로 종이책 `미리보기`·전자책 `미리읽기` 여부까지 읽힌다.
- 지침 표 위의 `<예시> 생성형 인공지능 사용 가능 여부`는 학교 공통 양식 문구다(다른 과목 변경 공지에도 같은 문구).
  "예시라서 무효"가 아니라 ○ 위치가 실제 기준. 과목별 변경은 `2026학년도 2학기 중간과제물 과제명 등 변경 공지(1~5차)`에서 확인.

## 방송대 서평 과제를 Word 파일로 만들기 (2026-10-11)

- 책 본문이 없어도 **예스24 상품 페이지의 `출판사 리뷰`·`책 속으로`에 쪽수가 달린 본문 인용문**이 있다.
  Playwright로 `#infoset_pubReivew`, `#infoset_inBook`, `#infoset_toc`를 읽는다. 인용은 이 원문에 있는 것만 쓰고,
  본문의 큰따옴표 문자열이 원문에 그대로 있는지 스크립트로 대조한다(이번에 14개 전부 일치).
- 방송대 교재 저자·목차는 `press.knou.ac.kr/goods/textBookView.do?condCmdtCode=<ISBN>`. 목차는 숨은 탭 DOM에 있다.
- "한글 160%"는 글자 크기의 160%다. Word에서는 `lineRule=exact`, 11pt면 17.6pt로 고정해야 같은 밀도가 된다.
  맑은 고딕에 배수 1.6을 주면 훨씬 벌어진다. 단 Google Docs는 exact를 지원하지 않는다.
- python-docx: `w:pgNumType`은 `w:pgMar` 바로 뒤에 넣어야 스키마 순서가 맞다. 기본 템플릿의 `w:zoom`에는
  `w:percent`가 없어 검증이 실패하므로 100을 넣는다. docx 스킬 `validate.py`는 `uv run --with defusedxml --with lxml`로 실행.
- 쪽수는 렌더러가 없어 추정만 가능. 30/25/30mm 여백, 11pt, 17.6pt 줄 간격에서 본문 약 1,600자가 1쪽.
- Playwright `filename` 저장은 프로젝트 폴더와 `.playwright-mcp`만 허용된다. 저장 뒤 스크래치패드로 옮긴다.
- 성·사랑·사회 강의안 PDF(1~10강)는 `pdftotext -layout`로 바로 읽힌다(이미지형 아님). 강의 번호와 교재 장 번호·제목이
  일치하므로 교재 쪽수가 없을 때는 장 단위로 인용하고, 쓴 표현이 강의안에 있는지 공백 제거 후 문자열 대조로 확인한다.
  강의안은 교재(2016)보다 최신 내용이 섞여 있으니 참고문헌에 강의 자료를 따로 적는다.
- 방송대 `(온라인 제출용)중간과제물표지.docx`는 별도 표지 쪽이 아니라 **첫 쪽 상단의 머리 블록**이다(제목 줄, 4행 표,
  `- 이하 작성`). 본문은 그 아래에 바로 이어 쓴다. 여백이 위 35, 아래 30, 좌우 20mm라 본문 폭이 170mm로 넓다.
  처음부터 이 양식을 받아 그 안에 쓰면 표지를 따로 만들 필요가 없다. 다음부터는 양식 유무를 먼저 물어볼 것.
- 병합은 양식을 python-docx로 열어 표 4열에 run을 추가하고, 보고서 본문 `w:p`를 deepcopy해 `sectPr` 앞에 넣는다.
  `pStyle`은 두 파일의 styleId가 달라 제거한다(문단에 직접 서식이 있어 모양은 유지됨).
- python-docx의 `Length` 뺄셈 결과는 int라 `.pt`가 없다. EMU를 12700으로 나눈다.

## 방송대 시뮬레이션 중간과제(3.4절 대기행렬): 예제 실행과 결과분석표 (2026-10-11)

- 과제 지침 PDF는 1쪽이고 AI 사용 가능 여부 표가 **없다**. 예제·작성법은 교수 홈페이지에 있고 로그인 없이 `curl`로 읽힌다:
  학습정보 `professor.knou.ac.kr/khkim/8685/subview.do`, 학습상담 `…/8679/subview.do`, 글 본문 `…/bbs/khkim/<게시판>/<글>/artclView.do`,
  첨부 `…/download.do`. 사용자가 주는 `subview.do?enc=…` 링크는 base64로 풀면 `artclView.do` 경로가 나온다.
  학습상담 검색은 `artclList.do`에 `srchColumn=sj&srchWrd=<검색어>` POST.
- 꼭 읽을 글: 학습정보 `과제물관련 예제 프로그램 (C,JAVA, XCODE)`(243582), 학습상담 `(과제물 작성법1·2·3)`(239360, 239359, 525715).
  봉사시간은 **그 고객의 봉사가 시작되는 시각에 새로 뜨는 TPUMP**다(도착 시각의 TPUMP는 앞 고객의 남은 시간 — 가장 흔한 감점).
  출발 = max(도착, 앞 고객 출발) + 봉사, 대기 = max(0, 앞 고객 출발 − 도착). 봉사시간 0이면 1로 표기.
- macOS에서는 예제(`EX3-3 -gcc.C`)를 그대로 쓰면 안 된다. `long`이 8바이트라 난수가 달라지므로 `int`로, `random`은 `random2`로 바꾼다(교수 공지).
  이 난수기는 **32비트 정수 넘침**에 의존한다. clang `-O0`(기본)과 `-fwrapv`는 같은 결과지만 **`-O2`만 주면 결과가 달라진다.** 최적화 없이 컴파일할 것.
- 포팅 검증: 교재 원래 조건(seed 35213, prarr 1/4, mean 4, tlimit 100)으로 돌리면 도착 22, 평균 대기행렬 1.59, 평균 대기시간 7.227이 나와야 한다
  (7강 강의록 32쪽). 단 그 슬라이드의 `TIME 100, ARRIVE 1` 행은 실제 실행(0)과 다르다 — 통계값으로 대조할 것.
- 강의록 PDF(Acrobat PDFMaker for PowerPoint)는 제목만 텍스트이고 코드·표는 이미지다. 강의별 서브에이전트 8개 병렬 전사는 약 3분.
  그러나 이 과제는 3.4절 예제 하나만 쓰므로 **지침을 먼저 받았다면 7강만 봐도 충분했다.** 강의록 일괄 학습 전에 과제 지침부터 확인할 것.
- `/opt/homebrew/bin/soffice`는 있지만 LibreOffice 본체가 없는 껍데기라 실행이 안 된다. docx 확인은 `qlmanage -t -s 1600`(첫 화면 PNG)과
  `textutil -convert txt`(본문 대조)로 대신한다. 쪽 나눔은 확인할 수 없다. 셸에서 `ls`·`rm`은 별칭이라 `/bin/ls`·`/bin/rm`을 쓴다.
- python-docx로 표 테두리를 직접 넣을 때 `w:tblBorders`는 `w:tblLayout`·`w:tblLook` **앞**에 넣어야 스키마 검증을 통과한다.

## 방송대 심리학에게묻다 중간과제(귀인·인지적 오류 자기 분석) (2026-10-11)

- 지침 표는 `사용불가`에 ○(`pdftotext -bbox`로 ○의 x좌표가 `사용불가` 열 안인지 확인). 사용자가 교수 허락을 받았다고 밝힌 뒤 진행했다.
  이런 경우 AI 사용 표기에 "담당 교수의 허락을 받아"를 넣고, 그 문구를 넣을지는 사용자가 정하게 알린다.
- 본인 경험이 재료인 과제는 경험을 지어내지 않는다. 사건·당시 원인 해석·지속성·머릿속 말·감정과 행동·지금의 생각 6가지를 메모로 받고,
  받지 못한 항목(이번에는 "지금의 생각")은 초안에 쓰되 **제안임을 밝혀 사용자가 고치게** 한다.
- 강의안이 없어도 수강 화면의 `강의요약`·`주요용어` 캡처면 개념 정의는 충분하다. 교재 쪽수는 알 수 없으므로 쪽수 인용은 하지 않는다.
- 분량 추정: 표지 양식(좌우 20mm) + 11pt + 17.6pt 고정 줄 간격에서 한 줄 약 45자, 한 쪽 37줄, 표지 블록 약 11줄.
  본문 4,200자(공백 포함) + 소제목 7개 + 참고문헌 + AI 표기가 약 3.6~3.8쪽으로 계산된다. Quick Look 미리보기는 고정 줄 간격을 반영하지 않아 쪽수 확인에 쓸 수 없다.

## macOS 메모리 정리: RSS가 아니라 footprint로 볼 것 (2026-10-13)

- 스왑이 많이 찬 상태에서는 `ps`의 RSS가 실제 점유를 크게 과소 표시한다(`vis serve` RSS 10MB, 실제 4.8GB).
  `top -l 1 -o mem -stats pid,command,mem,cmprs`의 MEM(압축·스왑 포함)으로 순위를 매길 것.
- `vis serve`(vault-intelligence 데몬, 포트 8741)는 유휴 상태에서도 임베딩 모델 때문에 약 4.8GB를 잡는다.
  `~/.claude/hooks/vis-serve.sh`(SessionStart hook)가 health 실패 시 다시 띄우므로 `kill -TERM`으로 꺼도 된다.
  종료까지 약 16초 걸렸다(스왑에서 다시 읽어 오기 때문으로 추정).
- 세션이 띄운 Playwright Chrome은 `browser_close`로 닫으면 프로세스까지 종료된다.
- 디스크 정리(2026-10-15): `rm`이 `trash` alias라 지워도 공간이 안 생긴다. 반드시 `/bin/rm`을 쓸 것.
  `uv cache prune`은 Claude 세션의 serena(`uvx`)가 캐시 잠금을 잡고 있어 300초 대기 후 실패한다.
  세션을 모두 닫고 실행해야 하며, `--force`는 실행 중인 serena 환경을 지울 수 있어 쓰지 않는다.
  ChatGPT(Codex) 앱은 Sparkle 업데이트 zip을 `~/Library/Caches/com.openai.codex/.../Installation/`에 쌓는다.
  실행 중인 Autoupdate 시작 시각과 맞지 않는 예전 폴더는 지워도 된다.
  잠금은 각 세션의 serena(`uv tool uvx ... serena`)가 잡는다. 이 세션 것까지 포함해 serena 프로세스만 TERM하면 세션을 닫지 않고도 prune할 수 있다.
  prune 결과 "Removed 41.7GiB"였지만 실제 여유 공간은 6.2GB만 늘었다. 로컬 스냅샷은 없었다.
  macOS에서 uv가 venv에 패키지를 APFS clone으로 설치해 블록을 공유하기 때문으로 보인다.
  그러니 `du`로 본 uv 캐시 크기를 확보 가능 용량으로 기대하지 말 것.

## weekly-analytics W42: 자동 실행 분석 세션 누수·compaction 요약·자정 분할 (2026-10-17)

- **세 번째 분류 누수: 지난주 `/weekly-claude-analytics` 자동 실행(08:00 시작)이 다음 주 창 첫 세션으로 들어온다.**
  활성 11분이라 `active_s < 600` meta 임계를 넘어 real로 샜다. 자동 실행 스킬 첫 프롬프트는 활성 시간과 무관하게 meta로 볼 것.
- **사람 프롬프트 수에서 compaction 요약("This session is being continued…")을 빼야 한다.** W42 311 → 295(16건).
  W41 526이 같은 기준이었는지는 `/tmp/wk41/`이 사라져 확인 불가 → **파생 스크립트가 /tmp에만 있으면 다음 주 기준 대조가 끊긴다.**
- `wk_union.py`의 per-day는 블록을 **끝나는 날짜에 통째로 귀속**한다(10-10 21:57→10-11 00:35 블록이 10-11로). 일별 병렬 계수는
  자정에서 잘라 다시 계산해야 맞는다(`/tmp/wk42/bin/merge.py`).
- `/model` 전환은 사람 프롬프트에 안 남고 `<local-command-stdout>Set model to … saved as your default` 로그로만 남는다.
  미커밋 `settings.json` model diff의 출처가 이것이었다. 모델 전환 계기는 이 문자열의 timestamp로 찾을 것.
- 원격 커밋 메시지의 "언니 폰 업로드" → 휴대폰이 네 번째 실행면(맥·원격 PC·클라우드에 이어). 세션 지표엔 안 잡힌다.

## 컴퓨터 초기화 전 전 저장소 푸시 점검 절차 (2026-10-21)

- 점검 4축: 미커밋 파일 · **모든 로컬 브랜치**의 upstream 유무와 ahead 수 · stash · 원격 없는 저장소.
  현재 브랜치만 보면 `feat/*` 로컬 전용 브랜치(portfolio 6커밋, playlist 1커밋)를 놓친다.
  `git for-each-ref refs/heads/` 로 전 브랜치를 돌고, upstream 없는 브랜치는 `git branch --merged main`으로 병합 여부 확인.
- **stash는 push 대상이 아니다.** 오래된 stash를 `stash apply`하면 main과 충돌해 커밋이 안 될 수 있다(chalna, 9-30 stash).
  충돌 해결 없이 원본 그대로 보존하려면 stash 커밋 자체를 원격 브랜치로 민다:
  `git push origin stash@{0}:refs/heads/wip/<name>`. 원격 해시 == `git rev-parse stash@{0}` 로 검증.
- 원격 없는 저장소는 `gh repo create <owner>/<name> --private --source=. --remote=origin --push` 한 줄로 생성+추적+푸시.
  푸시 전 `.gitignore`와 `git ls-files -co --exclude-standard | grep -iE 'env|token|secret'` 로 자격증명 유출 확인.
- **gitignore된 자격증명(.env, .youtube/token.json, .tokens.json)은 푸시로 보존되지 않는다.** 초기화 전 별도 백업 목록을 뽑아 보고할 것.
- zsh 함정: `for spec in "a b"; set -- $spec` 은 zsh에서 단어 분리가 안 된다. 함수 인자로 넘기거나 `${=spec}` 사용.
