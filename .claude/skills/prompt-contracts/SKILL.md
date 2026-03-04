---
name: prompt-contracts
description: |
  Prompt Contracts framework for structured prompt authoring during brainstorming, planning, design, and feature development.
  Enforces Goal/Constraints/Format/Failure Conditions to prevent vibe coding.
  Auto-triggers on: brainstorming, writing-plans, design, feature implementation tasks.
---

# Prompt Contracts Framework

프롬프트를 창작 브리프가 아닌 **법적 계약서처럼** 작성하는 구조화된 접근법.
Claude Code는 점쟁이가 아니라 **계약자(contractor)** — 명확한 계약 없이는 "화장실이 주방에 있는 집"을 받게 된다.

> "60초 더 생각해서 60분 추측 제거"

## 4가지 핵심 구성 요소 (Core Components)

### 1. Goal — "완료"를 테스트 가능하게 정의

Goal의 핵심은 상세함이 아닌 **테스트 가능성(testability)**.
작업 완료 후 **1분 이내에 검증 가능**해야 한다.

**Before (바이브 코딩, Vibe Coding):**
```
> 앱에 구독 시스템 추가해줘
```

**After (계약, Contract):**
```
GOAL: 사용자가 3개 티어(free/pro/team)에 구독하고, 즉시 업/다운그레이드하며,
/settings/billing에서 결제 상태를 볼 수 있는 Stripe 구독 관리를 구현하라.
성공 = 무료 사용자가 Pro에 구독하고, Stripe 대시보드에서 과금을 확인하고,
5초 내에 게이트된 기능에 접근할 수 있는 것.
```

### 2. Constraints — 넘을 수 없는 경계 (Boundaries)

제약(constraints) 없이는 Claude Code가 **기술 스택을 완전히 재발명**해 버린다.
비협상(non-negotiable) 경계를 명시한다.

**Before (바이브 코딩):**
```
> 모범 사례 적용해줘
```

**After (계약):**
```
CONSTRAINTS:
- Convex useQuery for data, no polling, no SWR
- Clerk useUser() for auth check
- Tailwind only — no CSS modules, no styled-components
- Max 150 lines per component file
```

### 3. Output Format — 기대하는 구체적 구조

명시적 포맷(format) 지시 없이는 Claude Code는 **유지보수성(maintainability)이 아닌 속도에 최적화**한다.
파일 위치, 함수 시그니처(function signature), 반환 타입(return type)을 구체적으로 지시한다.

**Before (바이브 코딩):**
```
> 사용자 온보딩 함수 만들어줘
```

**After (계약):**
```
FORMAT:
1. Convex function in convex/users.ts (mutation, not action)
2. Zod schema for input validation in convex/schemas/onboarding.ts
3. TypeScript types exported from convex/types/user.ts
4. Include JSDoc on the public function
5. Return { success: boolean, userId: string, error?: string }
```

### 4. Failure Conditions — 비밀 병기, 가드레일 (Guardrails)

Goal이 당근이라면, Failure Conditions는 채찍.
**"좋은 것"을 정의하는 대신 "나쁜 것"을 명시**한다.

"안전하게 운전해" vs "80 초과 금지, 빨간불 금지, 러시아워에 고속도로 금지"
— 하나는 기도이고, 다른 하나는 내비게이션 시스템이다.

**예시:**
```
FAILURE CONDITIONS:
- Uses useState for data that should be in Convex
- Any component exceeds 150 lines
- Fetches data client-side when it could be server-side
- Uses any UI library besides Tailwind utility classes
- Missing loading and error states
- Missing TypeScript types on any function parameter
```

## 적용 체크리스트 (Application Checklist)

### Brainstorming 시
- [ ] **Goal 도출**: "완료"를 1분 내 검증 가능하게 정의
- [ ] **Constraints 식별**: 기술 스택, 패턴, 금지 항목을 비협상 경계로 명시
- [ ] **Failure Conditions 도출**: "이것이 있으면 수용 불가" 목록 작성
- [ ] 각 설계 접근법에 대해 Goal/Constraints/Failure Conditions 명시

### Planning 시
- [ ] **Plan 전체에 Goal 명시**: 테스트 가능한 성공 기준(success criteria)
- [ ] **Plan 전체에 Constraints 명시**: 비협상 제약 사항
- [ ] **각 작업(task)에 Output Format 명시**: 파일 위치, 함수 시그니처, 반환 타입
- [ ] **각 작업에 Failure Conditions 포함**: "이 조건이면 작업 미완료" 기준

## CLAUDE.md 영구 제약 계층 (Permanent Constraint Layer)

프로젝트별 Constraints를 `CLAUDE.md`에 문서화하여 **영구적 제약 계층(Permanent Constraint Layer)** 으로 활용:

```markdown
# CLAUDE.md — Project Constraints (always active)

## Stack (non-negotiable)
- Frontend: Next.js 14+ App Router, TypeScript strict
- Backend: Convex for real-time data, Supabase for auth + storage
- Styling: Tailwind only — no CSS modules, no styled-components

## Hard Rules
- Never install a new dependency without asking first
- Never modify the database schema without showing the migration plan
- Environment variables go in .env.local, never hardcoded
```

CLAUDE.md 도입 전에는 Claude Code가 스택을 임의로 교체하는 일이 빈번했다.
CLAUDE.md 도입 후에는 세션 간 일관성(cross-session consistency)이 보장된다.

## 핸드셰이크 절차 (Handshake Protocol)

새 세션 시작 시 첫 메시지로 제약 확인을 수행:

```
> Read CLAUDE.md and confirm you understand the project constraints
> before doing anything.
```

이는 코드베이스의 **미란다 권리(Miranda rights)** — Claude Code가 제약을 되풀이하고,
양쪽이 현실에 동의한 후 작업이 시작된다.

## 최소 시작 (Minimum Viable Contract)

복잡한 계약이 부담스럽다면, 다음 3가지만으로 시작:

1. **1 Goal** — 테스트 가능한 성공 기준
2. **1 Constraint** — 가장 중요한 비협상 경계
3. **1 Failure Condition** — 가장 흔한 실패 패턴

이 30초의 투자로 즉각적인 차이를 체감할 수 있다.

## 완전한 프롬프트 계약 예시 (Complete Prompt Contract Example)

```
> Build the /dashboard page.
>
> GOAL: Display user's active projects with real-time updates.
> First meaningful paint under 1 second. User can create, archive,
> and rename projects inline.
>
> CONSTRAINTS: Convex useQuery for data, no polling, no SWR.
> Clerk useUser() for auth check. Redirect to /sign-in if
> unauthenticated. Max 150 lines per component file.
>
> FORMAT: Page component in app/dashboard/page.tsx (server component
> wrapper), client component in components/dashboard/ProjectList.tsx,
> Convex query in convex/projects.ts. Tailwind only.
>
> FAILURE CONDITIONS:
> - Uses useState for data that should be in Convex
> - Any component exceeds 150 lines
> - Fetches data client-side when it could be server-side
> - Uses any UI library besides Tailwind utility classes
> - Missing loading and error states
> - Missing TypeScript types on any function parameter
```
