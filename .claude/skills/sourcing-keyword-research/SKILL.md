---
name: sourcing-keyword-research
description: Autonomous keyword research for Domeggook wholesale set product sourcing. AI autonomously discovers optimal search keywords and exclusion filters per component, presenting only the final summary for user approval before updating collect_set_data.py. Triggers on "sourcing keyword", "keyword research", "set sourcing", "component keywords", or when user provides set name with component list.
---

# 소싱 키워드 리서치

도매꾹 API를 사용하여 세트 상품의 구성품별 최적 검색 키워드와 노이즈 제외 필터를 발굴하는 자율 워크플로우.

## 핵심 원칙

**AI가 데이터 기반으로 자율 판단하고, 최종 반영만 사용자 승인을 받는다.**

| 단계 | 의사결정 주체 | 이유 |
|------|-------------|------|
| 키워드 선택 | AI 자율 | 검색 결과 수, 카테고리 적합도, 노이즈 비율로 판단 가능 |
| 제외 필터 적용 | AI 자율 | 세트 컨텍스트 기반 노이즈 분류는 명확한 기준 존재 |
| 최종 스크립트 반영 | **사용자 승인** | 코드 변경이므로 최종 확인 필요 |

## 입력 형식

### 단건 모드 (기본)

사용자가 다음 정보를 제공한다:
- **세트명**: 예) "봄단정 외출 세트"
- **구성품 목록**: 예) 화장품 파우치, 휴대용 빗, 접이식 거울
- **상품명** (선택): 예) "봄 여행 파우치 세트"

### 배치 모드

`/sourcing-keyword-research batch` 또는 `/sourcing-keyword-research batch xlsx`로 호출.
사용자가 입력 파일(@멘션)을 제공한다. 지원 형식: `.md`, `.csv`, `.xlsx`.
상세 워크플로우는 하단 [Batch Mode](#batch-mode) 참조.

## 워크플로우

### Phase 1: 구성품별 키워드 자동 선정

**모든 구성품을 병렬로 진행한다.** 구성품 간 의존성이 없으므로 순차 처리할 이유가 없다.

#### 1-1. 초기 검색어 생성

구성품명에서 자연스러운 검색 키워드 후보 3~5개를 생성한다.
예) "휴대용 빗" → "휴대용 빗", "미니 빗", "접이식 빗", "여행용 빗", "포켓 빗"

#### 1-2. API 검색 실행 (병렬)

`scripts/search_keywords.py`를 사용하여 각 키워드 후보의 검색 결과 수를 확인한다.
독립적인 키워드 검색은 병렬로 실행하여 속도를 높인다.

```bash
python3 ~/.claude/skills/sourcing-keyword-research/scripts/search_keywords.py "검색어" --size 5
```

결과에서 `totalItems` (전체 검색 결과 수)와 상위 5개 상품명을 확인한다.

#### 1-3. 상위 상품 상세 조회 (카테고리 확인)

검색 결과 상위 2~3개 상품의 상세정보를 조회하여 카테고리를 확인한다.

```bash
python3 ~/.claude/skills/sourcing-keyword-research/scripts/search_keywords.py --detail {item_no}
```

#### 1-4. AI 키워드 선정 기준

다음 기준으로 키워드를 자율 선정한다:

1. **카테고리 적합도** (최우선) — 상위 상품의 카테고리가 구성품 의도와 일치하는가
2. **노이즈 비율** — 상위 5개 중 세트 컨텍스트에 맞지 않는 상품 비율
3. **검색 결과 수** — 너무 적으면(5건 미만) 소싱 선택지 부족, 너무 많으면(200건 초과) 노이즈 증가
4. **세트 컨텍스트 조화** — 세트명/상품명의 톤과 키워드의 뉘앙스 일치

**자동 제외 기준:**
- 검색 결과 0건인 키워드
- 상위 5개 중 노이즈 비율 80% 이상인 키워드
- 카테고리가 완전히 다른 키워드 (예: 텀블러 검색에 가방만 나오는 경우)

### Phase 2: 노이즈 분석 및 제외 필터 자동 적용

키워드가 선정되면, 해당 키워드의 검색 결과에서 노이즈 패턴을 자동 분석한다.

#### 2-1. 노이즈 패턴 분석

선정된 키워드로 `--size 20`으로 검색하여 상품명 20개를 가져온다:
- 세트 컨텍스트에 맞지 않는 상품들의 공통 키워드를 추출한다
- 패턴별로 그룹화한다

```bash
python3 ~/.claude/skills/sourcing-keyword-research/scripts/search_keywords.py "선정된 키워드" --size 20
```

#### 2-2. 노이즈 판단 기준

상품이 "노이즈"인지는 **세트 컨텍스트**(세트명, 상품명, 구성품 용도)를 기준으로 판단한다:
- 세트의 톤/용도와 맞지 않는 상품 (예: "외출 세트"에 산업용 제품)
- 구성품의 물리적 특성과 맞지 않는 상품 (예: "휴대용 빗"에 대형 빗자루)
- 카테고리가 의도와 크게 다른 상품
- 같은 노이즈 패턴이 2건 이상 발견되면 제외 필터로 추가

### Phase 3: 최종 확인 및 스크립트 업데이트

모든 구성품의 키워드와 제외 필터가 확정되면:

#### 3-1. 최종 요약 제시 (사용자 승인 필요)

```
=== 최종 키워드 설정 요약 ===

세트명: 봄단정 외출 세트
출력파일: 봄단정외출세트_소싱데이터_v2.csv

| 구성품 | 검색 키워드 | 제외 필터 | 선정 근거 |
|--------|-----------|----------|----------|
| 화장품파우치 | 화장품 파우치, 메이크업 파우치 | (없음) | 카테고리 일치, 노이즈 적음 |
| 휴대용빗 | 휴대용 빗, 미니 빗 | 빗자루, 고데기, ... | 카테고리 일치, 검색 결과 적절 |
| 손거울 | 손거울, 콤팩트 거울 | 탁상, LED, 벽걸이, ... | 카테고리 일치, 휴대용 적합 |

→ 이 설정으로 collect_set_data.py를 업데이트할까요? (Y/N)
```

**이 단계에서만 사용자 승인을 대기한다.**

#### 3-2. collect_set_data.py 업데이트

사용자가 승인하면 다음 섹션을 업데이트한다:

설정은 `set_config.py`에 분리되어 있다. **이 파일만 업데이트한다** (`collect_set_data.py`는 수정하지 않는다):

1. **SET_NAME** — 세트명
2. **OUTPUT_FILENAME** — 출력 CSV 파일명 (예: `{세트명_공백제거}_소싱데이터_v2.csv`)
3. **COMPONENTS** 딕셔너리 — 구성품명(공백제거) → 키워드 리스트
4. **EXCLUDE_FILTERS** 딕셔너리 — 구성품명 → 제외 키워드 리스트

파일 위치: `references/api-guide.md`의 `collect_set_data.py Location` 참조.

#### 3-3. keyword_research_log.md에 결과 기록

`set_config.py` 업데이트 후, 같은 프로젝트 디렉토리의 `keyword_research_log.md`에 리서치 결과를 추가한다.
기존 기록 아래에 새 세트 섹션을 append한다. 기록 항목:

- 세트명, 상품명, 출력파일, 날짜
- 구성품별 키워드 설정 테이블 (키워드, 제외 필터, 선정 근거)
- 제외된 키워드 후보 테이블 (키워드, 결과 수, 제외 사유)
- 실행 결과 요약 (매칭 판매자 수, 수집 상품 수)

## 참고 자료

- API 파라미터 및 응답 구조: `references/api-guide.md`
- 검색 헬퍼 스크립트: `scripts/search_keywords.py`

## 구성품명 명명 규칙

- COMPONENTS 키: 공백 제거한 한글 (예: "화장품파우치", "휴대용빗")
- 검색 키워드 값: 자연어 (공백 포함, 예: "화장품 파우치")

## 주의사항

- 구성품별 키워드 검색은 병렬로 진행한다 (구성품 간 의존성 없음)
- 검색 결과가 0건인 키워드는 자동으로 제외한다
- API 호출 간 0.3초 딜레이를 유지한다 (bash 호출 시 `sleep 0.3` 또는 스크립트 내부 처리)
- 카테고리가 의도와 크게 다른 경우 해당 키워드를 자동 제외하고 근거를 기록한다
- 최종 요약에서 각 키워드의 **선정 근거**를 반드시 명시한다

## Batch Mode

배치 모드는 여러 세트를 파일 입력으로 한 번에 처리한다.

### 호출 방식

```
/sourcing-keyword-research batch        # 세트별 CSV 출력
/sourcing-keyword-research batch xlsx   # 세트별 CSV + 통합 xlsx
```

사용자가 입력 파일을 @멘션으로 제공한다. 지원 형식: `.md`, `.csv`, `.xlsx`

### 입력 파싱

```bash
uv run ~/.claude/skills/sourcing-keyword-research/scripts/read_batch_input.py <input_file>
```

JSON 배열로 `set_name`, `product_name`, `components`를 반환한다.

### 배치 처리 워크플로우

1. **입력 파싱** — `read_batch_input.py`로 JSON 변환
2. **세트별 순차 반복:**
   a. Phase 1-2: 기존 키워드 리서치 워크플로우 그대로 실행
   b. Phase 3: `set_config.py` 자동 업데이트 (**승인 없이 진행**)
   c. `collect_set_data.py` 실행 → 세트별 CSV 생성
   d. `keyword_research_log.md` 기록
   e. **에러 발생 시** → 에러 내역 기록, 해당 세트 스킵, 다음 세트로 진행
3. **전체 완료 후:**
   a. `xlsx` arg가 있으면 → `merge_to_xlsx.py`로 CSV 통합
   b. 최종 요약 테이블 출력

### collect_set_data.py 실행

```bash
cd /Users/iseong/projects/domeggook-product-sourcing && python3 collect_set_data.py
```

### xlsx 통합 출력

```bash
uv run ~/.claude/skills/sourcing-keyword-research/scripts/merge_to_xlsx.py \
  -o /Users/iseong/projects/domeggook-product-sourcing/batch_소싱데이터_YYYY-MM-DD.xlsx \
  --names "세트A,세트B,..." \
  세트A_소싱데이터_v2.csv 세트B_소싱데이터_v2.csv ...
```

### 에러 처리

- API 에러, 적합 키워드 없음 등 → 해당 세트 스킵
- 최종 요약에 실패 세트와 원인 명시

### 최종 요약 형식

```
=== 배치 처리 결과 ===

| # | 세트명 | 상태 | CSV | 비고 |
|---|--------|------|-----|------|
| 1 | 봄나들이 세트 | ✅ 성공 | 봄나들이세트_v2.csv | 판매자 12명, 상품 156개 |
| 2 | 여름쿨링 세트 | ❌ 실패 | - | 미니선풍기: 적합 키워드 없음 |

통합 파일: batch_소싱데이터_2026-03-09.xlsx (1개 시트)
```

### 배치 모드 주의사항

- 배치 모드에서도 API 호출 간 0.3초 딜레이를 유지한다
- 세트 간 전환 시 `set_config.py`를 덮어쓰므로, 이전 세트의 CSV가 정상 생성되었는지 확인 후 진행
- `product_name`이 비어있으면 `set_name`을 사용한다
