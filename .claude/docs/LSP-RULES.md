# LSP-First Development

Java 프로젝트(특히 레거시)에서 LSP(JDTLS)를 최우선으로 활용. Grep/Read 전에 항상 LSP를 먼저 시도.

<lsp_enforcement>

**CRITICAL: LSP 도구를 사용할 수 있는 환경에서는 반드시 LSP를 먼저 사용하라. 이것은 선택이 아니라 의무이다.**

## LSP 필수 사용 상황

| 작업 | LSP Operation | Grep/Read 대신 LSP를 써야 하는 이유 |
|------|---------------|--------------------------------------|
| 심볼 정의 찾기 | `goToDefinition` | 정확한 위치, 상속/인터페이스 고려 |
| 참조 추적 | `findReferences` | 모든 사용처를 정확하게 찾음 |
| 타입/문서 확인 | `hover` | IDE 수준의 타입 정보 제공 |
| 파일 구조 파악 | `documentSymbol` | 클래스/메서드 목록을 구조적으로 반환 |
| 인터페이스 구현체 찾기 | `goToImplementation` | 상속 계층 정확히 탐색 |
| 호출 관계 파악 | `incomingCalls` / `outgoingCalls` | 콜 그래프를 정확하게 추적 |
| 워크스페이스 심볼 검색 | `workspaceSymbol` | 프로젝트 전체에서 심볼 검색 |

## Java Legacy Project 규칙 (JDTLS)

- Java 파일 작업 시 LSP가 활성화되어 있으면 **반드시** LSP를 1순위로 사용
- `findReferences`로 변경 영향 범위를 파악한 후에만 리팩토링 진행
- `goToImplementation`으로 인터페이스/추상 클래스의 구현체를 정확히 확인
- `incomingCalls`로 메서드 호출자를 추적하여 변경의 파급 효과 분석
- Legacy 코드의 복잡한 상속 구조는 `goToDefinition` + `goToImplementation` 조합으로 탐색
- 대규모 Java 파일은 `documentSymbol`로 구조 먼저 파악, 필요한 심볼만 선택적으로 Read

## 의사결정 흐름

```
코드 탐색이 필요한가?
├─ 심볼의 정의/참조/구현을 찾는가? → LSP 사용 (MUST)
├─ 파일 구조를 파악하는가? → LSP documentSymbol (MUST)
├─ 호출 관계를 추적하는가? → LSP incomingCalls/outgoingCalls (MUST)
├─ 텍스트 패턴 검색인가? (로그 메시지, 설정값 등) → Grep 허용
└─ 파일 전체 내용이 필요한가? → Read 허용 (단, 500줄 이하)
```

## 금지 패턴

- 클래스/메서드 정의를 Grep으로 찾기 → LSP `goToDefinition` 사용
- 메서드 사용처를 Grep으로 찾기 → LSP `findReferences` 사용
- 인터페이스 구현체를 Grep으로 찾기 → LSP `goToImplementation` 사용
- 대형 Java 파일을 Read로 전체 읽기 → LSP `documentSymbol` → 필요한 심볼만 Read
- 메서드 호출 관계를 Grep으로 추적 → LSP `incomingCalls`/`outgoingCalls` 사용

## 허용 패턴

- 문자열 리터럴, 설정값, 로그 메시지 검색 → Grep
- LSP 서버가 응답하지 않거나 미지원 파일 → Grep/Read fallback
- 500줄 이하 소규모 파일 전체 읽기 → Read
- 비-Java 파일 (XML, properties, YAML 등) → Grep/Read

## LSP 미응답 시 Fallback 절차

1. LSP 호출 시도 (필수)
2. 에러 또는 타임아웃 발생 시 사용자에게 보고
3. 사용자 승인 후 Grep/Read로 대체

</lsp_enforcement>
