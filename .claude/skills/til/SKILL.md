---
name: til
description: Transform Obsidian vault content into a portfolio TIL (Today I Learned) post for ~/log publication.
argument-hint: "[vault-file-path|topic-keyword] [dev|design|product|ai-tools]"
disable-model-invocation: true
---

# Portfolio TIL 발행 - $ARGUMENTS

Obsidian vault의 학습 자료를 포트폴리오(`~/projects/portfolio/content/blog/`)에 맞는 MDX 글로 변환합니다.
사용자는 관리 감독관(supervisor) 역할 — Claude가 초안을 작성하고, 사용자가 검토·승인합니다.

## 인수 처리

```bash
FIRST_ARG=$(echo "$ARGUMENTS" | awk '{print $1}')
SECOND_ARG=$(echo "$ARGUMENTS" | awk '{print $2}')

# 카테고리 판별
VALID_CATEGORIES="dev design product ai-tools"

if echo "$VALID_CATEGORIES" | grep -qw "$SECOND_ARG"; then
    CATEGORY="$SECOND_ARG"
    SOURCE="$FIRST_ARG"
elif echo "$VALID_CATEGORIES" | grep -qw "$FIRST_ARG"; then
    CATEGORY="$FIRST_ARG"
    SOURCE=""
else
    CATEGORY=""
    SOURCE="$FIRST_ARG"
fi
```

## 소스 수집 (Phase 1)

### 인수가 파일 경로인 경우
- vault 경로: `~/Documents/zion-vault/`
- 상대 경로이면 vault 기준으로 해석 (예: `000-SLIPBOX/DRY와 Information Hiding은 다르다.md`)
- Read 도구로 파일 내용 읽기
- vis search로 관련 문서 2-3개 추가 수집하여 맥락 보강

### 인수가 키워드인 경우
- `vis search "키워드"` 또는 Grep으로 vault 내 관련 문서 검색
- 후보 목록(최대 5개)을 사용자에게 제시
- 사용자가 선택한 파일을 소스로 사용

### 인수가 없는 경우
- 오늘/어제 수정된 vault 파일 중 TIL 후보 제안
- `find ~/Documents/zion-vault -name "*.md" -type f -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} \; | grep "$(date +%Y-%m-%d)\|$(date -v-1d +%Y-%m-%d)"`
- 후보를 사용자에게 제시

---

## 카테고리 판별 (Phase 2)

### 인수로 카테고리가 지정된 경우
- 해당 카테고리 사용, 판별 건너뛰기

### 자동 판별 (카테고리 미지정 시)

**1차: Obsidian 태그 매핑**

| Obsidian 태그 패턴 | → category |
|-------------------|------------|
| `oop/`, `patterns/`, `principles/`, `architecture/`, `refactoring/`, `clean-code/` | `design` |
| `AI/tools/`, `AI/mcp/`, `AI/agents/`, `AI/prompt/`, `AI/claude/` | `ai-tools` |
| `marketing/`, `seo/`, `geo/`, `product/`, `business/`, `sourcing/` | `product` |
| 그 외 기술 태그 (`java/`, `spring/`, `docker/`, `react/`, `git/` 등) | `dev` |

**2차: 콘텐츠 키워드 (태그 불충분 시)**

| 키워드 | → category |
|--------|------------|
| APoSD, 디자인 패턴, Information Hiding, 모듈, 캡슐화, SOLID, 추상화, 결합도, 응집도 | `design` |
| Claude Code, MCP, LLM, 프롬프트, 에이전트, GPT, Copilot, AI 도구 | `ai-tools` |
| 마케팅, ROAS, 광고, SEO, GEO, 스마트스토어, 소싱, 전환율, CTR | `product` |
| 특정 언어/프레임워크/인프라 (Java, Spring, React, Docker, K8s, CI/CD) | `dev` |

**3차: 행동 테스트 (여전히 모호한 경우)**
- "이 글이 주로 다루는 것은?"
  - **어떻게** 만드는가 (구현 방법) → `dev`
  - **왜** 이렇게 설계해야 하는가 (원칙/철학) → `design`
  - **무엇을** 팔고/알리는가 (마케팅/기획) → `product`
  - **어떤 AI 도구**를 어떻게 활용하는가 → `ai-tools`

### 판별 결과 보고

사용자에게 다음 형식으로 보고하고 확인 받기:

```
📂 카테고리: design
📌 판별 근거: Obsidian 태그 `oop/encapsulation`, `patterns/information-hiding` → design
📄 소스: 000-SLIPBOX/DRY와 Information Hiding은 다르다.md

이 카테고리로 진행할까요? (다른 카테고리를 원하시면 말씀해주세요)
```

---

## 글 작성 (Phase 3)

### 어체 규칙 (필수 — 모든 글에 동일 적용)

**종결어미: 한다체 (평서형)**
- ✅ "~한다", "~이다", "~했다", "~된다", "~있다"
- ❌ "~합니다", "~입니다" (경어체)
- ❌ "~해요", "~이에요" (구어체)
- ❌ "~하겠습니다", "~알아보겠습니다" (서론 금지)

**문체 특성:**
- 직입 화법 — 서론/인사 없이 바로 본론
- 간결하고 압축적 — 불필요한 수식어 제거
- 테이블 적극 사용 (비교, 매핑, 분류)
- **볼드**로 핵심 한 줄 강조
- Bad/Good 또는 Before/After 코드 비교
- 인용(>) 활용하여 핵심 메시지 부각

**예시:**
```
❌ "이 글에서는 DRY와 Information Hiding의 차이에 대해 알아보겠습니다."
✅ "DRY와 Information Hiding은 다르다. DRY는 증상을 치료하고, Information Hiding은 원인을 치료한다."
```

### 카테고리별 글 구조

#### dev (실무 문제 해결)
```
## 시나리오
(어떤 상황에서 작업 중이었는지)

## 문제 / 발견
(에러 메시지, 예상치 못한 동작)

## 원인 / 이유
(왜 이 문제가 발생했는지 — 테이블, 코드로 설명)

## 해결 / 핵심 포인트
(해결 방법 — Before/After 코드)

## 코드
(완전한 코드 예시)

## 참고
(관련 문서 링크, 추가 팁)
```

#### design (설계 원칙/패턴)
```
## 출발점
(어떤 오해 또는 질문에서 시작했는지)

## 핵심 구분
(테이블로 개념 비교 — 이것 vs 저것)

## 왜 중요한가
(실무에서 이 구분이 왜 의미 있는지)

## 실무 적용
(Bad/Good 코드 예시로 원칙 적용)

## 판단 기준
(언제 A를 쓰고 언제 B를 쓰는지 — 구체적 신호)

## 핵심 정리
(3-5줄 불릿으로 요약)
```

#### product (마케팅/기획/비즈니스)
```
## [개념]이란
(정의 — 한 문장으로)

## 동작 원리
(어떻게 작동하는지 — 단계별)

## [개념]의 영역
(분류/유형 — 테이블 또는 h3 섹션)

## 실전 적용
(구체적 도구/방법 — 코드나 설정 예시)

## 참고
(공식 문서, 도구 링크)
```

#### ai-tools (AI 도구 활용)
```
## 문제
(기존에 어떤 불편/한계가 있었는지)

## 해결책
(어떤 도구/기능이 이를 해결하는지)

## 사용법
(단계별 설명 — 코드/설정/명령어)

## 핵심 정리
(불릿으로 요약)
```

### 콘텐츠 변환 규칙

1. **위키링크 제거**: `[[APoSD Ch.5]]` → "APoSD Ch.5" (일반 텍스트)
2. **Obsidian 전용 문법 제거**: callout, dataview 등
3. **코드 예시 보강**: vault 원본에 코드가 부족하면 Bad/Good 비교 예시 추가
4. **외부 독자 관점**: 내부 학습 메모를 "다른 개발자가 읽어도 이해할 수 있는" 글로 재작성
5. **vault의 핵심 인사이트 유지**: 원본의 핵심 통찰은 반드시 포함
6. **기술 용어**: 첫 등장 시 영어 병기 — "정보 은닉(Information Hiding)"

---

## MDX 프론트매터

```yaml
---
title: "글 제목"
description: "1-2줄 설명 (검색 결과에 표시됨)"
date: "YYYY-MM-DD"
tags: ["tag1", "tag2", "tag3"]
category: "dev|design|product|ai-tools"
published: true
---
```

- **title**: 명확하고 구체적. 50자 내외.
- **description**: 글의 핵심을 1-2문장으로. 150자 내외.
- **date**: 발행일 (오늘 날짜)
- **tags**: 소문자, 하이픈 연결. 2-5개.
- **category**: 4개 중 하나.
- **published**: true

---

## 저장 및 검증 (Phase 4)

### 파일명 생성
```
YYYY-MM-DD-kebab-case-slug.mdx
```
- 날짜: 오늘
- slug: 제목에서 핵심 단어 2-5개 추출, 영문 kebab-case
- 예: `2026-03-21-dry-vs-information-hiding.mdx`

### 저장 경로
```
~/projects/portfolio/content/blog/YYYY-MM-DD-slug.mdx
```

### 저장 후 검증
```bash
cd ~/projects/portfolio && pnpm build
```
빌드 성공 확인 후 사용자에게 결과 보고.

### 결과 보고 형식
```
✅ 포트폴리오 TIL 발행 완료

📄 파일: content/blog/2026-03-21-dry-vs-information-hiding.mdx
📂 카테고리: design
🏷️ 태그: information-hiding, dry, aposd
📊 빌드: 성공

미리보기: pnpm dev → http://localhost:3000/log/2026-03-21-dry-vs-information-hiding
```

---

## 전체 흐름 요약

```
1. 소스 수집      → vault 파일 읽기 + 관련 문서 수집
2. 카테고리 판별  → 태그/키워드 기반 추론 → 사용자 확인
3. 초안 작성      → 어체 규칙 + 카테고리별 구조 적용
4. 사용자 검토    → 초안을 사용자에게 제시 → 수정 요청 반영
5. 저장 및 검증   → MDX 저장 → pnpm build 확인
```

**핵심 원칙:**
- 사용자는 감독관이다. 초안을 제시하고 승인을 받는다.
- 어체는 한다체. 예외 없음.
- 카테고리별 구조를 반드시 따른다.
- vault 원본의 핵심 인사이트는 반드시 유지한다.
