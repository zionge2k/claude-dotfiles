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
