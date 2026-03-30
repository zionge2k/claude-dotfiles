# Git Workflow

한글(비-ASCII) 커밋 메시지의 인코딩 깨짐을 방지하기 위한 규칙.

<git_commit_messages>

## 한글 커밋 메시지 작성 규칙

1. 반드시 Write 도구로 임시 파일에 커밋 메시지를 저장
2. `git commit -F <file>`로 파일에서 메시지를 읽어 커밋
3. 커밋 후 임시 파일 삭제

**CRITICAL**: Bash heredoc(`cat << EOF`)이 아닌 Write 도구를 사용할 것. UTF-8 인코딩 보장을 위함.

## Workflow 예시

```
Step 1: Write 도구로 임시 파일 생성
- Tool: Write
- file_path: /tmp/commit-msg-unique.txt
- content: [한글 포함 커밋 메시지]

Step 2: 파일로 커밋
- bash: git add <files> && git commit -F /tmp/commit-msg-unique.txt

Step 3: 정리
- bash: rm /tmp/commit-msg-unique.txt
```

## 커밋 메시지 포맷

```
feat: 한글 커밋 메시지 예제

- 첫 번째 변경사항
- 두 번째 변경사항

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Write 도구를 사용하는 이유

- Write 도구는 UTF-8 인코딩을 네이티브로 보존
- Bash heredoc은 비-ASCII 문자에 유니코드 이스케이프 시퀀스를 생성할 수 있음
- Write 도구가 다양한 셸 설정에서 더 안정적

</git_commit_messages>

<use_commit_skill>

## /commit 스킬 사용 규칙

커밋 생성 시 항상 `/commit` 스킬을 사용할 것.
- 자동 conventional commit 메시지 생성
- 내장 한글 인코딩 안전성 (Write tool 사용)
- `--push`: 커밋 후 자동 push
- `--amend`: 이전 커밋 수정

수동 `git commit`은 `/commit`이 불가능한 환경에서만 허용.

</use_commit_skill>
