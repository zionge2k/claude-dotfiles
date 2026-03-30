# Work Patterns

프로젝트 시작 전 반드시 plan mode를 사용. API/SDK/라이브러리 사용 시 CONTEXT7 MCP 도구로 올바른 사용법을 검증한 후 진행.

<work_patterns>

## Plan Folder Structure

- 새 작업 시작 시 `PROJECT_ROOT/.claude/plans/YYYY-MM-DD-kebab-case-topic/` 폴더를 생성한다.
  - 날짜: 작업 시작일
  - topic: Claude가 작업 내용에서 3~5단어 kebab-case 이름을 자동 생성
  - 예: `.claude/plans/2026-02-14-plan-folder-isolation/`
- 폴더 안에 plan 파일과 `INDEX.md`를 저장한다.
- 작업 진행에 따라 plan을 업데이트한다.

## 폴더별 INDEX.md

해당 작업의 상태를 관리하는 파일. 세션 시작 시 이 파일로 resume.

```
# Plan: 작업 제목
Created: YYYY-MM-DD
Status: active|completed|paused

## Progress
- [x] 완료된 작업
- [ ] 미완료 작업

## Resume Point
구체적인 재개 지점 (파일명, 단계 번호, 남은 작업)

## Files
- plan-file.md — 설명
```

- "resume point"는 새 세션에서 즉시 작업을 재개할 수 있을 정도로 구체적이어야 함

## 글로벌 INDEX.md

경로: `PROJECT_ROOT/.claude/plans/INDEX.md`
폴더 목록과 한줄 요약만 관리 (참고용)

```
# Plans Index
Last updated: YYYY-MM-DD

## Active
- [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약

## Completed
- [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약 | completed: YYYY-MM-DD

## Paused
- [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약 | reason
```

- plan 폴더 생성/완료/일시정지 시마다 업데이트

## Backward Compatibility

- 기존 루트의 랜덤 이름 plan 파일(`.claude/plans/*.md`)은 그대로 유지
- 날짜 폴더가 없는 프로젝트에서는 기존 방식으로 동작

</work_patterns>
