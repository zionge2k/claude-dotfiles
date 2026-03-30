# Tool Preferences

검색 및 탐색 작업에 선호하는 도구 목록.

<tool_preferences>

## 도구 선택 기준

| Task | Tool | Reason |
|------|------|--------|
| Syntax-aware search | `sg --lang <lang> -p '<pattern>'` | 구조적 매칭에 최적화 |
| Text search | `rg` (ripgrep) | grep보다 빠름, .gitignore 존중 |
| File finding | `fd` | find보다 빠르고 직관적 |
| Web content | Playwright MCP 우선 | 동적/인증 콘텐츠 지원, Cloudflare 우회 |
| **코드 탐색 (Java)** | **LSP (JDTLS) 필수** | **정의/참조/구현/호출 관계를 정확하게 탐색** |
| Large files (>500줄) | Serena/LSP symbolic tools | Read보다 효율적 |

## Web Content 규칙

- 1순위: Playwright MCP (`browser_navigate` → `browser_snapshot`)
- 2순위: WebFetch (정적 public 페이지만)
- 금지: fetch/bash curl/wget (렌더링 불가, 403 차단)

## File Reading 안전 규칙

- 1000줄 초과 파일: `offset`/`limit` 파라미터 사용
- Edit 전: `old_string` 고유성 확인

</tool_preferences>
