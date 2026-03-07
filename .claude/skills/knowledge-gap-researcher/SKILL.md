---
name: knowledge-gap-researcher
description: |
  Discovers knowledge gaps in the Obsidian vault using vis analyze-gaps,
  then researches missing topics via web search and creates summary documents.
  Orchestrates existing tools: vis analyze-gaps, technical-researcher agent, summarize-article command.
  Triggers on: "지식 공백", "knowledge gap", "부족한 주제", "뭘 더 공부해야", "학습 추천"
---

# 지식 공백 연구 파이프라인 스킬

## 개요

Obsidian vault의 **지식 공백(knowledge gap)을 자동으로 발견**하고,
부족한 주제에 대해 외부 자료를 조사하여 vault를 보강하는 파이프라인 스킬.

기존 도구들을 순차 조합하여 실행:
- `vis analyze-gaps` → 공백 발견
- `technical-researcher` 에이전트 → 자료 조사
- `/obsidian:summarize-article` 또는 `/obsidian:summarize-youtube` → 문서화

## 핵심 아키텍처

```
┌─────────────────────────────────────────┐
│  Phase 1: 공백 분석                      │
│  vis analyze-gaps --top-k 20             │
│  → 부족한 주제/약한 연결 영역 식별           │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Phase 2: 사용자 확인                     │
│  - 발견된 공백 목록 제시                    │
│  - 우선순위 협의 (관심 + 업무 연관성)         │
│  - 연구할 주제 1~3개 선택                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Phase 3: 자료 조사                      │
│  - WebSearch로 관련 기술 문서/영상 검색      │
│  - technical-researcher 에이전트 활용       │
│  - 양질의 소스 2~3개 선별                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Phase 4: 문서 생성 및 vault 통합          │
│  - /obsidian:summarize-article 또는       │
│    /obsidian:summarize-youtube 호출        │
│  - vis tag + vis add-related-docs 실행    │
│  - 기존 문서와의 연결 관계 구축              │
└─────────────────────────────────────────┘
```

## 실행 프로세스

### Phase 1: 공백 분석

```bash
# vault 전체 지식 공백 분석
vis analyze-gaps --top-k 20
```

분석 결과를 다음 기준으로 분류:

| 유형 | 설명 | 예시 |
|------|------|------|
| **주제 공백** | 관심 분야인데 문서가 부족한 주제 | "Hexagonal Architecture 문서 2개뿐" |
| **연결 공백** | 문서는 있으나 다른 주제와 연결이 약한 영역 | "Event Sourcing이 CQRS와 연결 안 됨" |
| **깊이 공백** | 개요만 있고 상세 내용이 부족한 주제 | "Modulith 개요만 있고 구현 가이드 없음" |

### Phase 2: 사용자 확인

발견된 공백을 **우선순위 테이블**로 제시:

```markdown
## 발견된 지식 공백

| # | 주제 | 유형 | 현재 문서 수 | 관련 주제 연결 | 추천도 |
|---|------|------|-------------|---------------|--------|
| 1 | Hexagonal Architecture 구현 | 깊이 공백 | 2 | architecture/* | ★★★ |
| 2 | Event Sourcing + CQRS | 연결 공백 | 3+2 | ddd/* | ★★★ |
| 3 | Spring Modulith 실습 | 주제 공백 | 1 | spring/* | ★★☆ |

어떤 주제를 먼저 연구할까요? (번호로 선택, 최대 3개)
```

**자동으로 진행하지 않고 반드시 사용자 확인을 받는다.**

### Phase 3: 자료 조사

선택된 주제에 대해:

1. **WebSearch**로 최신 기술 문서, 블로그, 영상 검색
2. 검색 결과를 **technical-researcher** 에이전트 관점에서 평가:
   - 기술적 깊이
   - 저자/소스 신뢰도
   - 실습 예제 포함 여부
   - 사용자 관심 분야(OOP, TDD, DDD 등)와의 관련성
3. 양질의 소스 **2~3개 선별**하여 사용자에게 제시

```markdown
## 조사 결과: [주제]

| # | 소스 | 유형 | 적합도 | 이유 |
|---|------|------|--------|------|
| 1 | [제목](URL) | 기술 블로그 | ★★★ | 실습 예제 풍부, Spring Boot 기반 |
| 2 | [제목](URL) | YouTube | ★★☆ | 개념 설명 우수, 코드 없음 |

어떤 소스를 정리할까요?
```

### Phase 4: 문서 생성 및 vault 통합

선택된 소스를 기반으로:

1. **URL 유형에 따라 적절한 커맨드 호출**:
   - 기술 문서/블로그 → `/obsidian:summarize-article [URL]`
   - YouTube 영상 → `/obsidian:summarize-youtube [kr|en] [URL]`

2. **문서 생성 후 자동 통합**:
   ```bash
   # 태그 자동 부여
   vis tag "생성된_파일.md"

   # 관련 문서 연결
   vis add-related-docs "생성된_파일.md"
   ```

3. **공백 해소 확인**:
   - `vis related "생성된_파일.md"` 실행하여 기존 문서와 연결 확인
   - 연결이 잘 되었으면 보고, 아직 약하면 추가 자료 조사 제안

## 사용 예시

```
# 기본 사용 — vault 전체 공백 분석
사용자: "지식 공백 분석해줘"

# 특정 분야 지정
사용자: "Architecture 관련해서 부족한 주제 뭐야?"

# 공백 발견 + 즉시 연구
사용자: "부족한 주제 찾아서 자료도 정리해줘"

# 학습 추천
사용자: "다음에 뭘 공부하면 좋을지 추천해줘"
```

## 주의사항

- Phase 2, Phase 3에서 **반드시 사용자 확인**을 받은 후 다음 단계 진행
- 한 세션에서 최대 **3개 주제**만 처리 (컨텍스트 관리)
- 외부 자료 조사 시 **Playwright MCP 우선** 사용 (CLAUDE.md 도구 선호 규칙 준수)
- 생성된 문서는 `003-RESOURCES/` 폴더에 저장 (참고자료이므로)
- vis 명령어 실행 에러 시 건너뛰고 안내
