# Superpowers Integration

superpowers 플러그인을 활용한 구조화된 개발 워크플로우.

<brainstorming-context>

## Brainstorming 컨텍스트

superpowers:brainstorming 사용 시 자동으로 다음을 반영:
- TDD/OOP/DDD 중심 설계 선호
- 단순성과 실용성 우선 (YAGNI, DRY)
- 복잡한 작업은 2-5분 단위로 분해

</brainstorming-context>

<superpowers-workflow>

## 복잡한 개발 작업 시 순서

1. `/superpowers:brainstorming` - 아이디어 정제, 대안 탐색
2. `/superpowers:writing-plans` - 세부 작업 분해 (파일 경로, 코드, 검증 단계 포함)
3. `/superpowers:executing-plans` - 점진적 실행 (초기 3개 작업 → 피드백 → 자율 진행)

## TDD 강제 원칙

- NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
- 코드를 먼저 작성했다면? 삭제하고 처음부터.

</superpowers-workflow>

<verification-before-completion>

## 작업 완료 전 검증 체크리스트

- [ ] 모든 테스트 통과
- [ ] Plan/todo 문서에 완료 상태 반영
- [ ] main과 변경사항 간 diff 동작 확인
- [ ] "Staff engineer가 승인할 만한가?"
- [ ] 폴더별 INDEX.md progress 업데이트 (resume point, status, task counts)
- [ ] 글로벌 INDEX.md 상태 업데이트 (active/completed/paused) — 존재 시
- [ ] 다음 세션을 위한 컨텍스트 기록
- [ ] Git worktree 격리 확인 (해당 시)

## Recoverability

- 의미 있는 작업 단위마다 커밋
- 항상 롤백 가능한 상태 유지

</verification-before-completion>
