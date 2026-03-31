---
name: claude-updates
description: |
  Fetch the latest Claude Code changelog, translate and summarize it in Korean, then save as an Obsidian document.
allowed-tools: playwright
disable-model-invocation: true
---

# Claude Code Changelog Summary

Claude Code의 최신 changelog를 가져와서 번역/정리하여 Obsidian 문서를 생성합니다.

## 작업 프로세스

1. **Changelog 페이지 접근**
   - Playwright로 `https://docs.anthropic.com/en/docs/claude-code/changelog` 접근
   - browser_navigate → browser_snapshot으로 전체 내용 확보
   - 페이지가 길면 스크롤하여 추가 내용 확보 (browser_press_key: PageDown → browser_snapshot 반복)

2. **최신 변경사항 추출**
   - 가장 최근 릴리스 항목을 식별 (날짜 + 버전 기준)
   - **최신 1개 릴리스만 추출** (전체 이력 X)
   - 이전에 이미 정리한 버전인지 확인: `~/Documents/zion-vault/003-RESOURCES/` 에서 "Claude Code" + 해당 버전 제목의 파일이 있으면 사용자에게 알리고 중단

3. **번역 및 문서 생성**
   - 아래 `## 문서 번역 규칙`에 따라 내용을 정리
   - **저장 경로**: `~/Documents/zion-vault/003-RESOURCES/`
   - 파일명: `Claude Code {version} Changelog.md` (예: `Claude Code v1.0.35 Changelog.md`)

4. **후처리**
   ```bash
   vis tag "저장된_파일경로.md"
   vis add-related-docs "저장된_파일경로.md"
   ```

## yaml frontmatter

```yaml
id: "Claude Code {version} Changelog"
aliases: "Claude Code {version} 변경사항"
tags:
  - tools/claude-code/changelog
  - tools/claude-code/updates
  - tools/ai-tools/release-notes
author: anthropic
created_at: {현재 시각 YYYY-MM-DD HH:mm}
related: []
source: https://docs.anthropic.com/en/docs/claude-code/changelog
```

## 문서 번역 규칙

```
대상 독자:
- 25년 이상 경력의 한국 소프트웨어 개발자
- Claude Code를 주요 개발 도구로 적극 활용 중
- 영어 문서를 빠르게 읽기 어려움
- 업데이트의 실용적 영향(내 워크플로우에 어떤 변화가 있는가)에 관심

번역 지침:
- 기술 용어는 첫 언급 시 영어 원문 병기
- 직역보다 자연스러운 한국어 표현 우선
- 코드 예시는 원문 그대로 유지

문서 구조:

## 1. 핵심 요약
- 이번 릴리스의 가장 중요한 변경 3-5개를 bullet으로 요약
- 각 항목에 "왜 중요한가" 한 줄 추가

## 2. 상세 변경사항
- changelog의 각 섹션(Features, Fixes, Improvements 등)을 그대로 번역
- 각 항목마다 실제 사용 시 어떤 영향이 있는지 간략한 코멘트 추가
- 코드 예시가 있으면 반드시 포함

## 3. 내 워크플로우 영향 분석
- 현재 사용 중인 스킬, 훅, 설정에 영향을 줄 수 있는 변경사항 식별
- 필요한 조치(설정 변경, 스킬 업데이트 등) 제안
- 새로 활용 가능한 기능이 있으면 구체적 활용법 제시

주의사항:
- 원문에 없는 정보를 추가하지 말 것
- 불확실한 부분은 명시적으로 표시
- 모든 코드 예시를 빠짐없이 포함
```
