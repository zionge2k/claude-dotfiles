# Model-Harness Co-evolution Trap 연구 리포트

**연구일**: 2026-03-30
**연구 주제**: AI 보조 개발에서의 Model-Harness Co-evolution Trap (모델-하네스 공진화 함정)

---

## Executive Summary

Model-Harness Co-evolution Trap은 AI 코딩 어시스턴트의 커스텀 설정(CLAUDE.md, .cursorrules, system prompt)이 모델의 기본 동작과 충돌하거나, 모델 업데이트로 인해 기존 설정이 무효화되거나, 과도한 규칙으로 인해 오히려 성능이 저하되는 현상을 말합니다.

**핵심 발견사항**:
- LLM의 instruction-following 상한선은 약 **150-200개 지침**
- 이 임계값을 초과하면 모든 규칙의 준수율이 균등하게 저하됨
- CLAUDE.md는 코드와 **어텐션 경쟁**을 벌이며, 종종 패배함
- Context compression 시 규칙이 가장 먼저 손실됨
- 모델 업데이트는 잠재적인 breaking change

---

## 1. Search Summary

### 검색 플랫폼 및 범위
- **검색 플랫폼**: Google Web Search
- **검색 쿼리 수**: 15개
- **검색 기간**: 2023-2026년 자료 (2026년 최신 자료 포함)
- **분석 문서 수**: 150+ 웹 페이지, GitHub 이슈, 학술 논문, 기술 블로그

### 주요 검색 영역
1. CLAUDE.md/Cursor rules 유지보수 모범 사례
2. System prompt 충돌 및 모델 행동 변화
3. Instruction following degradation 연구
4. Prompt bloat 안티패턴
5. Configuration drift 및 harness engineering
6. 모델 업데이트에 따른 호환성 문제

---

## 2. Co-evolution Trap의 핵심 메커니즘

### 2.1 Instruction Capacity Limits (지침 용량 한계)

**문제**: LLM은 동시에 처리할 수 있는 지침의 수에 물리적 한계가 있습니다.

**정량적 임계값**:
- **최적 구간**: 150-200개 지침까지 안정적 성능 유지
- **성능 저하 패턴**:
  - **Threshold decay**: Gemini 2.5 Pro, o3 — 150개까지 완벽, 이후 급격히 저하
  - **Linear decay**: GPT-4.1, Claude Sonnet 4 — 점진적 성능 저하
  - **Exponential decay**: GPT-4o, Llama 4 Scout — 빠른 성능 붕괴

**실증 데이터** (IFScale Benchmark):
- 500개 지침 밀도에서 최고 frontier 모델도 **68% 정확도**만 달성
- 임계값 초과 시 **모든 규칙의 준수율이 균등하게 저하**됨

### 2.2 Context Window Attention Competition (컨텍스트 윈도우 어텐션 경쟁)

**문제**: CLAUDE.md 규칙은 실제 코드와 모델의 어텐션을 놓고 경쟁하며, 대부분 패배합니다.

**어텐션 분포 패턴**:
- **U-shaped curve**: 컨텍스트의 시작과 끝 부분이 중간보다 높은 어텐션
- **"Lost in the middle"**: 중간 영역의 정보는 무시되는 경향
- **Primacy & Recency bias**: 초기 system prompt와 최근 대화가 우선권

**실무 영향**:
```
System instructions (CLAUDE.md) + recent conversation + file contents
→ 모두 제한된 어텐션을 놓고 경쟁
→ 희석된 컨텍스트 = 희석된 결과
```

**전달 방식의 한계**:
- CLAUDE.md는 "system-level 강제 설정"이 아니라 **"user message"**로 전달됨
- Claude가 현재 작업과의 관련성을 능동적으로 판단하고, 무관하다고 판단하면 **스킵**

### 2.3 Context Compression & Rule Loss (컨텍스트 압축 및 규칙 손실)

**문제**: 긴 대화 세션에서 컨텍스트 압축 발생 시, 규칙이 가장 먼저 손실됩니다.

**발생 시점**:
- 대화가 **50+ 메시지**에 도달하면 context drift 시작
- 4-5번째 상호작용부터 Claude가 규칙을 무시하기 시작
- 45분 이상 세션 지속 시 초기 지침 손실

**손실 순서**:
1. **최상단의 system prompt/CLAUDE.md 규칙** (최우선 손실)
2. 프로젝트 제약사항
3. 행동 지침
4. 수정 기록 파일 목록

**결과**: 에이전트가 규칙 없이 작업을 계속하며 자신감 있게 규칙 위반 출력 생성

### 2.4 Rule Conflicts & Contradictions (규칙 충돌 및 모순)

**문제**: 여러 소스의 규칙이 상호 충돌하거나 모순될 때, AI는 임의로 하나를 선택합니다.

**충돌 발생 지점**:
1. **Global vs Project-specific**: 전역 지침 vs 프로젝트별 규칙
2. **Root vs Subdirectory**: `.cursorrules` (root) vs `.cursor/rules/*.mdc` (nested)
3. **System prompt vs Custom instructions**: 기본 행동 vs 사용자 지침
4. **Contradictory requirements**: "be brief" + "be comprehensive"

**실제 사례**:
- ChatGPT 사용자가 "URL 포함" 커스텀 지침 설정 → OpenAI system prompt "URL 불포함" 규칙과 충돌
- Cursor에서 중첩 디렉토리의 `.cursorrules` 충돌 시 **마지막에 로드된 규칙이 승리**

### 2.5 Model Update Breaking Changes (모델 업데이트 호환성 문제)

**문제**: 모델 업데이트는 기존 프롬프트 동작을 예측 불가능하게 변경할 수 있습니다.

**업데이트 영향 범위**:
- **Major version** (GPT-3→GPT-4, Claude 2→Claude 3): 프롬프트 재조정 필요
- **Minor version** (GPT-4→GPT-4 Turbo): 호환성 유지 목표이나 보장 안 됨

**실증 사례**:
- 미세조정된 downstream task adapter가 모델 업데이트 후 **negative flips** 경험
  - 이전에 정답이던 케이스가 오답으로 변경
- 성능 지표 개선 우선 → 이전 버전 호환성 낮은 우선순위

**Cursor의 대응**:
- Real-time RL을 통해 **5시간마다** 모델 개선 배포
- 빠른 개선 vs 호환성 딜레마

---

## 3. Prompt Bloat: 안티패턴 분석

### 3.1 정의 및 발생 메커니즘

**Prompt Bloat**: 과도한 컨텍스트나 규칙 추가로 모델이 혼란을 겪는 현상

**발생 패턴**:
1. **과도한 예제**:
   - 11번째, 12번째, 15번째, 20번째 예제 추가
   - 새로운 패턴을 커버하지 않고 기존 예제의 변형만 추가
   - **최적**: 2-6개 예제 (작업 복잡도에 따라)
   - **7번째 예제부터 diminishing returns**

2. **방어적 과잉 명세**:
   - "만약 사용자가 X를 요청하면 Y를 해라" 식의 조건문
   - Edge case 처리를 메인 프롬프트에 하드코딩
   - **해결책**: Routing 및 architecture로 처리

3. **불필요한 장황함**:
   - 하드코딩된 프롬프트는 거의 최적화되지 않음
   - 불필요한 장황함이나 비효율적인 few-shot 예제로 가득
   - 더 높은 토큰 비용 초래

### 3.2 성능 영향

**정량적 저하**:
- 추가 세부사항이 **정확도, 일관성, 관련성 저하**
- LLM은 무관한 정보를 식별할 수 있어도 효과적으로 필터링하지 못함

**200줄 임계값**:
- CLAUDE.md가 **200줄 초과** 시:
  - 중요 규칙이 노이즈에 묻힘
  - Claude가 절반을 무시
  - 컨텍스트 윈도우 예산 낭비

### 3.3 해결 방법

**추상화 원칙**:
- 여러 예제 제공 시, 전체 텍스트 반복 대신 **포맷을 추상화**
- 토큰 사용량 감소하면서 효과 유지

**소프트웨어 개발처럼 취급**:
- Test, version, monitor, refactor
- 정기적인 검토 및 pruning

---

## 4. Harness Engineering: 구조적 해결책

### 4.1 개념 정의

**Harness Engineering**: AI 에이전트를 감싸는 시스템, 제약, 피드백 루프를 설계하여 프로덕션에서 신뢰성 있게 만드는 학문

**하네스 구성요소**:
- 에이전트가 접근할 수 있는 도구
- 안전을 유지하는 가드레일
- 자기 수정을 돕는 피드백 루프
- 인간이 행동을 모니터링하는 관찰 가능성 레이어

### 4.2 Configuration Drift 관리

**Drift 유형**:
1. **AI slop**: 에이전트가 코드베이스의 불균등하거나 최적이 아닌 패턴을 복제
2. **Architectural drift**: 시간이 지나며 아키텍처 일관성 상실
3. **Documentation drift**: 문서와 실제 코드의 불일치

**OpenAI 팀의 해결책**:
- **"Golden principles"**를 코드베이스에 인코딩
- **Background agents**: 주기적으로 편차 스캔, 품질 등급 업데이트, 타겟 리팩토링 PR 생성
- 매주 금요일 "AI slop" 정리 작업 → 자동화된 주기적 cleanup 프로세스

### 4.3 Architectural Constraints (아키텍처 제약)

**핵심 원칙**: 아키텍처 제약이 있어야 속도를 낼 수 있으면서도 품질 저하나 드리프트 방지

**3가지 범주**:
1. **Context engineering**: 언제 컨텍스트를 로드할지
2. **Architectural constraints**: 어떤 도구/액션이 허용되는지
3. **Garbage collection**: 불일치나 아키텍처 제약 위반을 주기적으로 찾는 에이전트

---

## 5. 실무 완화 전략 및 모범 사례

### 5.1 CLAUDE.md 유지보수 프레임워크

#### A. "Compounding Engineering" 원칙

Anthropic 내부 팀이 사용하는 방법:
```
Claude가 실수할 때마다 → CLAUDE.md에 노트 추가
→ 해당 유형의 오류가 영구적으로 방지됨
→ 시간이 지나며 가치가 복리로 증가
```

**주의사항**: 무분별한 추가는 bloat 유발

#### B. 정기적 Pruning (가지치기)

**트리거**:
- 2-3주마다 정기 검토
- Claude가 규칙을 반복적으로 무시할 때
- 200줄 임계값 근접 시

**Pruning 기준**:
```
각 줄마다 질문: "이것을 제거하면 Claude가 실수하는가?"
→ No: 삭제하거나 hook으로 전환
→ Yes: 유지
```

**특정 삭제 대상**:
- Claude가 이미 올바르게 수행하는 지침
- 중복 또는 유사한 규칙
- 프로젝트에 더 이상 관련 없는 오래된 규칙

#### C. 모듈화 전략

**200줄 초과 시**:
```
CLAUDE.md (핵심 규칙만)
├── .claude/rules/testing.md
├── .claude/rules/code-style.md
└── .claude/rules/architecture.md
```

**Progressive Disclosure**:
- 핵심 규칙만 항상 로드
- 컨텍스트별 규칙은 필요 시 `@path` import

**Cursor 마이그레이션**:
```
.cursorrules (deprecated)
→ .cursor/rules/*.mdc (개별 파일)
```
더 나은 조직화, 쉬운 업데이트, 집중된 규칙 관리

### 5.2 충돌 해결 패턴

#### A. 명시적 우선순위 설정

VS Code Copilot 방식:
```
Personal instructions (highest priority)
> Workspace instructions
> System defaults
```

#### B. Instruction Hierarchy

```markdown
# CRITICAL (Must follow)
- 보안 관련 규칙
- 법적/컴플라이언스 요구사항

# HIGH (Should follow)
- 아키텍처 원칙
- 코딩 스타일

# MEDIUM (Prefer)
- 성능 최적화
- 사용자 경험 가이드

# LOW (Suggest)
- 코드 포맷팅 선호도
```

#### C. 충돌 감지 및 중단

프롬프트에 추가:
```
"If your action contradicts a stated constraint,
STOP and flag the conflict.
Do not proceed until a human resolves it."
```

### 5.3 Context Pinning (컨텍스트 고정)

**문제**: Attention decay로 인해 초기 규칙이 희석됨

**해결책**: 매 턴마다 프로젝트 제약을 강제로 재읽도록 engineering

**구현 방법**:
1. **Hook 활용**: 특정 작업 전 CLAUDE.md 재주입
2. **Structured memory**: MEMORY.md를 활용한 세션 간 상태 유지
3. **Periodic reminders**: 대화 중 주기적으로 핵심 규칙 재확인

### 5.4 Testing & Validation Framework

#### A. Promptfoo (OpenAI 인수, MIT 오픈소스)

**기능**:
- 프롬프트, 에이전트, RAG 테스트
- Red teaming/pentesting/취약점 스캔
- GPT, Claude, Gemini, Llama 성능 비교
- CI/CD 통합

**구성요소**:
1. **Test case repository**: 입력 + 평가 기준
2. **Execution engine**: 프롬프트 실행 + rate limit 관리
3. **Evaluation pipeline**: 자동 메트릭 + 선택적 인간 리뷰

#### B. Structured Output & Validation

**2026년 트렌드**:
- JSON validation schema → 반복률 **38.5% → 12.3%** 감소
- OpenAI Structured Outputs API (2025 후반 출시):
  - 토큰 레벨에서 JSON schema 강제
  - 생성 후 검증이 아닌 **생성 자체를 제약**

#### C. 측정 가능한 메트릭

**IFScale Benchmark**:
- 500개 keyword-inclusion 지침
- 비즈니스 리포트 작성 태스크
- 지침 밀도에 따른 성능 저하 측정

**성공 기준**:
- CLAUDE.md 변경 전후 Claude 행동 shift 관찰
- A/B 테스트: 규칙 유무에 따른 결과 비교

### 5.5 Version Control & Rollback

**프롬프트를 코드처럼 취급**:
```bash
git commit -m "feat(claude-md): add TypeScript strict mode enforcement"
git tag claude-md-v1.2.0
```

**Rollback 전략**:
- 모델 업데이트 후 성능 저하 발견 시 이전 CLAUDE.md 버전으로 rollback
- 프로덕션 배포 전 모델 버전을 dependency처럼 관리

**Cursor의 Versioning**:
- Major version (GPT-3→4): 프롬프트 재작성 필요
- Minor version (GPT-4→4 Turbo): 호환성 목표이나 테스트 필수

### 5.6 Elegance Check & Refactoring

**트리거**: 50+ 줄 변경 또는 새로운 추상화 도입 시

**질문**:
```
"더 우아한 방법이 있는가?"
"이 규칙들을 더 적은 수의 원칙으로 통합할 수 있는가?"
"이 규칙이 실제로 동작을 변경하는가?"
```

**리팩토링 시점**:
- Claude가 혼란스러워하거나 규칙을 무시하기 시작할 때
- 200줄 임계값 근접 시
- 팀 멤버가 CLAUDE.md를 이해하기 어려워할 때

---

## 6. 정량적 임계값 및 실무 기준

### 6.1 규칙 수 (Instruction Count)

| 범위 | 상태 | 권장사항 |
|------|------|----------|
| 1-50 | 최적 | 추가 가능 |
| 50-150 | 양호 | 신중하게 추가, 정기 검토 |
| 150-200 | 경고 | 즉시 pruning, 모듈화 고려 |
| 200+ | 위험 | 긴급 리팩토링 필요, 성능 저하 확실 |

### 6.2 파일 길이 (CLAUDE.md)

| 줄 수 | 상태 | 조치 |
|-------|------|------|
| 1-100 | 이상적 | 유지 |
| 100-200 | 허용 | 정기 pruning |
| 200-300 | 주의 | .claude/rules/ 분리 시작 |
| 300+ | 위험 | 즉시 모듈화 |

### 6.3 예제 수 (Few-shot Examples)

| 작업 유형 | 최적 예제 수 | Diminishing Returns 시작 |
|-----------|--------------|--------------------------|
| 짧은 출력 (<100 tokens) | 3-6개 | 7개부터 |
| 중간 출력 (100-500 tokens) | 2-4개 | 5개부터 |
| 긴 출력 (500+ tokens) | 1-3개 | 4개부터 |

### 6.4 세션 길이 (Context Management)

| 메시지 수 | 상태 | 조치 |
|-----------|------|------|
| 1-30 | 안전 | 정상 작업 |
| 30-50 | 주의 | 핵심 규칙 재확인 |
| 50-80 | 경고 | Context pinning 또는 새 세션 |
| 80+ | 위험 | 새 세션 시작 권장 |

### 6.5 검토 주기 (Review Frequency)

| 프로젝트 크기 | CLAUDE.md 검토 주기 | 트리거 |
|---------------|---------------------|--------|
| Small (1-2 devs) | 월 1회 | 새 팀원 온보딩 시 |
| Medium (3-10 devs) | 2주 1회 | Major feature 완료 시 |
| Large (10+ devs) | 주 1회 | 모델 업데이트 시 |

---

## 7. 기술 블로그 및 커뮤니티 인사이트

### 7.1 GitHub Issues 패턴 분석

**Claude Code 주요 이슈**:
- [#19635](https://github.com/anthropics/claude-code/issues/19635): "CLAUDE.md 규칙을 인정했음에도 반복적으로 무시"
- [#34132](https://github.com/anthropics/claude-code/issues/34132): "규칙은 advisory-only이며 강제 메커니즘 없음"
- [#5055](https://github.com/anthropics/claude-code/issues/5055): "사용자 정의 규칙을 반복적으로 위반"
- [#2544](https://github.com/anthropics/claude-code/issues/2544): "필수 규칙이 여러 저장소에서 일관되게 무시됨"

**커뮤니티 발견사항**:
- "200줄의 규칙을 작성했는데 모두 무시당했다"
- "Claude Code가 점점 멍청해지는 느낌" → System prompt architecture trap

### 7.2 실무자들의 패턴

**성공 패턴** ("5 Patterns That Make Claude Code Actually Follow Your Rules"):
1. **Structural elements** (headers, code fences, lists) > prose paragraphs
2. **Explicit formatting** 강조
3. **Context preservation** in compaction 설정
4. **Hook conversion** for deterministic behaviors
5. **Regular pruning** 루틴

**실패 패턴**:
- 제안(suggestion)으로 표현된 규칙 → 지시문(directive)으로 변경 필요
- 여러 디렉토리 레벨의 충돌하는 규칙 (개발자가 잊음)
- 너무 긴 .cursorrules로 핵심 지침이 effective context window 밖으로 밀려남

### 7.3 Expert Opinions

**Armin Ronacher (Flask 창시자)**:
"Agentic coding에서 20+ 시간을 프롬프트 튜닝에 쓰면 diminishing returns 함정에 빠진 것. 대부분의 신뢰성 개선은 architecture에서 나오지 wording에서 나오지 않는다."

**OpenAI Codex Team**:
"하네스 없는 에이전트는 도구가 아니라 실험. 프로덕션 AI의 95%는 모델이 아니라 모델을 감싸는 시스템."

**Nick Babich (UX Planet)**:
"CLAUDE.md는 팀의 집단 지식을 누적하는 compounding asset. 하지만 bloat을 관리하지 않으면 liability로 변한다."

---

## 8. 연구 한계 및 향후 과제

### 8.1 현재 연구의 한계

1. **모델별 차이**:
   - 대부분의 연구가 특정 모델(GPT-4, Claude)에 집중
   - 모델마다 instruction-following 특성이 상이
   - 일반화 가능한 임계값 도출 어려움

2. **측정의 어려움**:
   - Rule compliance를 정량화하는 표준 메트릭 부재
   - 주관적 평가에 의존하는 경우 많음
   - A/B 테스트 비용 높음

3. **진화하는 생태계**:
   - 2026년 3월 기준 자료이며 빠르게 변화 중
   - 새로운 모델 출시마다 패턴 변경 가능
   - 장기 추적 연구 부족

### 8.2 향후 연구 방향

1. **자동화된 Rule Optimization**:
   - CLAUDE.md의 효과성을 자동 측정하는 도구
   - Pruning 후보를 제안하는 AI 어시스턴트
   - Conflict detection 자동화

2. **모델별 Best Practices Database**:
   - GPT-4, Claude, Gemini별 최적 설정
   - 버전별 호환성 매트릭스
   - 마이그레이션 가이드

3. **Harness Engineering 표준화**:
   - 산업 표준 harness 패턴
   - 재사용 가능한 architectural constraints
   - Testing framework 통합

---

## 9. 실행 가능한 Checklist

### 즉시 실행 (Immediate Actions)

- [ ] 현재 CLAUDE.md 줄 수 확인 (200줄 초과 시 pruning)
- [ ] 각 규칙에 대해 "제거 시 실수 발생 여부" 테스트
- [ ] 충돌하는 규칙 쌍 식별 및 해결
- [ ] Instruction hierarchy (CRITICAL/HIGH/MEDIUM/LOW) 명시
- [ ] Git에 CLAUDE.md 커밋 및 태깅

### 단기 실행 (1-2주)

- [ ] .claude/rules/ 모듈화 구조 구축
- [ ] Context pinning hook 구현
- [ ] 2-3주 주기 리뷰 캘린더 설정
- [ ] Promptfoo 또는 유사 테스트 도구 도입 검토
- [ ] 팀 내 CLAUDE.md 리뷰 프로세스 정립

### 중기 실행 (1-3개월)

- [ ] Background cleanup agent 구현 (OpenAI 패턴)
- [ ] Golden principles를 코드베이스에 인코딩
- [ ] A/B 테스트로 규칙 효과성 측정
- [ ] 모델 업데이트 시 regression test 자동화
- [ ] 팀 지식을 CLAUDE.md에 compounding하는 workflow 확립

### 장기 실행 (3개월+)

- [ ] Harness engineering 프레임워크 구축
- [ ] Configuration drift 모니터링 시스템
- [ ] 조직 차원의 AI governance 정책
- [ ] Cross-project best practices 공유 플랫폼
- [ ] 지속적 학습 및 개선 루프

---

## 10. Sources (출처)

### CLAUDE.md Best Practices
- [CLAUDE.md Best Practices | UX Planet](https://uxplanet.org/claude-md-best-practices-1ef4f861ce7c)
- [Best Practices for Claude Code - Claude Code Docs](https://code.claude.com/docs/en/best-practices)
- [CLAUDE.md Complete Guide for Claude Code (2026)](https://www.shareuhack.com/en/posts/claude-code-claude-md-setup-guide-2026)
- [7 Claude Code best practices for 2026 | eesel AI](https://www.eesel.ai/blog/claude-code-best-practices)
- [CLAUDE.md best practices - From Basic to Adaptive | DEV Community](https://dev.to/cleverhoods/claudemd-best-practices-from-basic-to-adaptive-9lm)

### Cursor Rules & Configuration
- [Cursor Problems in 2026: What Users Report](https://vibecoding.app/blog/cursor-problems-2026)
- [Cursor Rules Advanced Guide: Pattern Configuration](https://www.sitepoint.com/cursor-rules-advanced-pattern-configuration-guide/)
- [Cursor Rules: How to Keep AI Aligned | DataCamp](https://www.datacamp.com/tutorial/cursor-rules)
- [Cursor Rules: Best Practices for Developers | Medium](https://medium.com/elementor-engineers/cursor-rules-best-practices-for-developers-16a438a4935c)

### System Prompt & Model Behavior
- [Guide to Writing System Prompts | Sahara AI](https://saharaai.com/blog/writing-ai-system-prompts)
- [How System Prompts Define Agent Behavior](https://www.dbreunig.com/2026/02/10/system-prompts-define-the-agent-as-much-as-the-model.html)
- [System Prompt vs User Prompt | PromptLayer](https://blog.promptlayer.com/system-prompt-vs-user-prompt-a-comprehensive-guide-for-ai-prompts/)
- [Architecting Prompts for Agentic Systems | Medium](https://medium.com/@jbbooth/architecting-prompts-for-agentic-systems-aligning-ai-behavior-with-human-expectations-25b689b3b8f6)

### Instruction Following Degradation
- ["Why Did My AI Agent Ignore Half My Instructions?" | Medium](https://medium.com/tech-ai-made-easy/why-did-my-ai-agent-ignore-half-my-instructions-fde3aea6e9f5)
- [Your AI Agent Forgets Its Rules Every 45 Minutes | DEV Community](https://dev.to/douglasrw/your-ai-agent-forgets-its-rules-every-45-minutes-heres-the-fix-151e)
- [A Field Guide to LLM Failure Modes | Medium](https://medium.com/@adnanmasood/a-field-guide-to-llm-failure-modes-5ffaeeb08e80)

### Prompt Bloat & Anti-patterns
- [Prompt Engineering Without the Bloat | Medium](https://captainnobody1.medium.com/prompt-engineering-without-the-bloat-lessons-from-building-llm-driven-tools-39accc8b2778)
- [The Impact of Prompt Bloat on LLM Output Quality | MLOps Community](https://home.mlops.community/public/blogs/the-impact-of-prompt-bloat-on-llm-output-quality)
- [The rise of prompt ops: Tackling hidden AI costs | VentureBeat](https://venturebeat.com/ai/the-rise-of-prompt-ops-tackling-hidden-ai-costs-from-bad-inputs-and-context-bloat)
- [The Ultimate Guide to Prompt Engineering in 2026 | Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)

### Harness Engineering
- [Harness Engineering: The Missing Layer Behind AI Agents | Louis Bouchard](https://www.louisbouchard.ai/harness-engineering/)
- [Harness Engineering | Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)
- [Harness engineering: leveraging Codex in an agent-first world | OpenAI](https://openai.com/index/harness-engineering/)
- [Skill Issue: Harness Engineering for Coding Agents | HumanLayer](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
- [What Is Harness Engineering? Complete Guide (2026) | NxCode](https://www.nxcode.io/resources/news/what-is-harness-engineering-complete-guide-2026)

### Agentic Coding Configuration
- [agentic-coding-rulebook/best_practices.md | GitHub](https://github.com/obviousworks/agentic-coding-rulebook/blob/main/best_practices.md)
- [A practical guide to Claude Code configuration in 2025 | eesel AI](https://www.eesel.ai/blog/claude-code-configuration)
- [What Is Agentic Coding? Risks & Best Practices | Apiiro](https://apiiro.com/glossary/agentic-coding/)
- [Agentic Coding Recommendations | Armin Ronacher](https://lucumr.pocoo.org/2025/6/12/agentic-coding/)
- [Best Practices for Agentic Coding | Memex](https://docs.memex.tech/in-depth/best-practices/best-practices-for-agentic-coding)

### Claude Code Specific Issues
- [I Wrote 200 Lines of Rules for Claude Code. It Ignored Them All | DEV](https://dev.to/minatoplanb/i-wrote-200-lines-of-rules-for-claude-code-it-ignored-them-all-4639)
- [Claude Code ignores CLAUDE.md rules | GitHub Issue #19635](https://github.com/anthropics/claude-code/issues/19635)
- [Rules are advisory-only | GitHub Issue #34132](https://github.com/anthropics/claude-code/issues/34132)
- [Claude Code Feels Dumber? System Prompt Architecture Trap](https://support.tools/claude-code-system-prompt-behavior-claude-md-optimization-guide/)
- [5 Patterns That Make Claude Code Actually Follow Your Rules | DEV](https://dev.to/docat0209/5-patterns-that-make-claude-code-actually-follow-your-rules-44dh)

### Model Updates & Compatibility
- [LLM Update in Production: When Prompts Fail](https://www.locked.de/llm-update-in-production-when-prompts-fail-and-what-it-means-for-your-applications/)
- [MUSCLE: A Model Update Strategy for Compatible LLM Evolution | Apple ML](https://machinelearning.apple.com/research/model-compatibility)
- [Five Tools for Prompt Versioning | Mirascope](https://mirascope.com/blog/prompt-versioning)
- [Building LLM applications for production | Huyen Chip](https://huyenchip.com/2023/04/11/llm-engineering.html)

### Testing & Validation Frameworks
- [promptfoo: Test your prompts, agents, and RAGs | GitHub](https://github.com/promptfoo/promptfoo)
- [Prompt Testing and Validation Frameworks: Production Guide](https://zenvanriel.com/ai-engineer-blog/prompt-testing-validation-frameworks/)
- [Top 5 Prompt Engineering Tools in 2026 | Getmaxim](https://www.getmaxim.ai/articles/top-5-prompt-engineering-tools-in-2026-2/)
- [8 Best Prompt Engineering Tools in 2026 | Mirascope](https://mirascope.com/blog/prompt-engineering-tools)

### Instruction Compliance Measurement
- [How Many Instructions Can LLMs Follow at Once? | arXiv](https://arxiv.org/html/2507.11538v1)
- [The Stability Trap: Evaluating LLM-Based Instruction Adherence | arXiv](https://arxiv.org/html/2601.11783)
- [How to Measure Instruction-Following in LLMs | Latitude](https://latitude.so/blog/measure-instruction-following-llms)
- [LLM evaluation metrics: Full guide | Braintrust](https://www.braintrust.dev/articles/llm-evaluation-metrics-guide)

### CLAUDE.md Optimization
- [CLAUDE.md: Best Practices from Prompt Learning | Arize](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/)
- [CLAUDE MD High Performance | GitHub Wiki](https://github.com/ruvnet/ruflo/wiki/CLAUDE-MD-High-Performance)
- [claude-md-optimizer | GitHub](https://github.com/wrsmith108/claude-md-optimizer)
- [The CLAUDE.md Memory System - Optimization Guide | SFEIR](https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/optimization/)

### AI Agent Prompt Engineering
- [AI Agent Prompt Engineering: Diminishing Returns | Softcery](https://softcery.com/lab/the-ai-agent-prompt-engineering-trap-diminishing-returns-and-real-solutions)
- [How to build your agent: 11 prompting techniques | Augment Code](https://www.augmentcode.com/blog/how-to-build-your-agent-11-prompting-techniques-for-better-ai-agents)
- [How to prompt your Agent: 8 tips | Augment Code](https://www.augmentcode.com/blog/how-to-prompt-your-agent-8-tips-on-improving-ai-agent-performance)
- [Why AI Agents Break: Field Analysis of Production Failures | Arize](https://arize.com/blog/common-ai-agent-failures/)

### Context Window & Attention
- [What Is the Context Window Limit in Claude Code? | MindStudio](https://www.mindstudio.ai/blog/claude-code-context-window-limit-management)
- [Understanding context windows in Claude Code](https://code.charliegleason.com/understanding-context-windows)
- [Stop Blaming Claude. Your Context Window is the Problem | CloudRepo](https://www.cloudrepo.io/articles/stop-blaming-claude-context-window-optimization)
- [Claude Code: keep the context clean | Medium](https://medium.com/@arthurpro/claude-code-keep-the-context-clean-d4c629ed4ac5)

### Configuration Drift & Model Drift
- [Avoid AI code drift with small steps | Henko.net](https://henko.net/blog/avoid-ai-code-drift-with-small-well-defined-steps/)
- [Why Your AI-Generated Code Gets Worse Over Time | Gigamind](https://gigamind.dev/blog/ai-code-degradation-context-management)
- [Model Drift: What It Is & How To Avoid | Splunk](https://www.splunk.com/en_us/blog/learn/model-drift.html)
- [AI Model Drift & Retraining: Guide for ML System Maintenance | SmartDev](https://smartdev.com/ai-model-drift-retraining-a-guide-for-ml-system-maintenance/)

---

## 11. Conclusion (결론)

Model-Harness Co-evolution Trap은 AI 보조 개발의 숨겨진 핵심 도전 과제입니다. 이 연구를 통해 다음 핵심 사실들이 밝혀졌습니다:

1. **정량적 한계 존재**: LLM은 150-200개 지침까지만 안정적으로 처리 가능
2. **어텐션 경쟁**: CLAUDE.md는 코드와 경쟁하며 종종 패배함
3. **Context compression의 치명성**: 긴 세션에서 규칙이 가장 먼저 손실됨
4. **Bloat의 역설**: 더 많은 규칙 ≠ 더 나은 성능
5. **모델 업데이트 = Breaking change**: 프롬프트를 dependency처럼 버전 관리 필요

**핵심 권고사항**:
- **Pruning을 생활화**: 2-3주마다 정기 검토
- **200줄 임계값 준수**: 초과 시 모듈화
- **Architecture > Wording**: 20시간 프롬프트 튜닝은 diminishing returns
- **Harness engineering 도입**: 프로덕션 AI는 모델보다 하네스가 중요
- **Testing framework 필수**: Promptfoo 등으로 규칙 효과성 측정

이는 일시적 문제가 아니라 **구조적 문제**입니다. 모델이 발전할수록 하네스의 중요성은 더욱 커질 것이며, 지금 투자한 CLAUDE.md 최적화는 시간이 지나며 복리로 가치가 증가할 것입니다.

**마지막 한 줄 요약**:
"더 많은 규칙이 아니라, 더 나은 규칙. 더 긴 프롬프트가 아니라, 더 스마트한 하네스."

---

**연구 수행**: Claude Sonnet 4.5
**연구 의뢰**: iseong
**문서 버전**: 1.0
**최종 업데이트**: 2026-03-30
