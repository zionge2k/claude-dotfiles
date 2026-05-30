# Proficiency Map

> 사용자(zionge2k) 숙련도 맵. **역해석**: 효율("전문가 지루하게 마라")이 아니라
> **학습 커리큘럼 지도**다. 낮은 숙련 = 버릴 영역이 아니라 **교육 에너지를 쏟을 영역**.
>
> 시드 출처: 2026-05-30 인터뷰(8문항). 점수 없음 — band + keywords만.
> 갱신: 엔진 없이 수동(또는 `/wrap-up`에 한 줄). 자동 분류기 도입 안 함.

## band 의미 (역해석)

| band | 응답 보정 |
|---|---|
| `peer-level` | 기초 설명 생략, 동료로 대함, 결론·트레이드오프 위주. ★Insight는 "왜 이 선택"에만. |
| `normal` | 능숙하나 가끔 리마인드/확인. 균형 잡힌 깊이. |
| `deep-teach` | **여기 집중.** ★Insight 밀도↑, "왜"를 깊게, code contribution(5~10줄 핵심 로직) 적극 요청. |

**전역 선호: ★Insight 밀도 최우선** — deep-teach가 아니어도 통찰은 아끼지 않는다.

## peer-level (기초 생략)

- **OOP/객체지향 설계**
  `다형성` `캡슐화` `상속` `SOLID` `응집도/결합도` `디자인 패턴` `책임 분리(SRP)` `의존성 역전` `인터페이스 설계`

## normal (균형)

- **TDD/테스트**
  `Red-Green-Refactor` `테스트 더블(mock/stub/spy)` `테스트 목록` `경계값` `TPP` `테스트 격리` `given-when-then`
- **Java/Spring Boot**
  `DI/IoC` `Bean` `JPA/Hibernate` `트랜잭션` `@RestController` `Spring Security` `gradle/maven`
- **리팩토링/클린코드**
  `Tidying` `Composed Method` `code smell` `Extract Method` `Guard Clause` `명명`

## deep-teach (교육 에너지 집중 + ★Insight 밀도↑ + code contribution 요청)

- **함수형/동시성/시스템**
  `FP(map/filter/fold)` `불변성` `모나드/펑터` `순수함수` `async/await` `동시성(goroutine/coroutine/thread)` `락/뮤텍스` `메모리 모델` `저수준 시스템`
- **프론트엔드/React/UI**
  `React` `hooks(useState/useEffect)` `상태관리` `컴포넌트 설계` `CSS/레이아웃` `리렌더링` `TypeScript` `번들러` `접근성`
- **AI/LLM 앱 개발**
  `Claude API` `프롬프트 캐싱` `에이전트/tool use` `컨텍스트 관리` `임베딩/RAG` `스트리밍` `토큰/비용` `MCP`
- **인프라/DevOps/클라우드**
  `Docker` `Kubernetes` `CI/CD` `IaC(Terraform)` `배포 전략` `AWS/GCP` `모니터링/관측성` `네트워킹`
- **데이터/SQL/분석**
  `쿼리 최적화` `인덱스` `조인/윈도우 함수` `실행 계획` `BigQuery` `데이터 모델링` `집계/분석`
- **Claude Code 메타**
  `플러그인` `스킬(progressive disclosure)` `훅(PreToolUse 등)` `서브에이전트` `settings.json` `MCP 통합` `슬래시 커맨드`
- **Obsidian/PKM**
  `vault` `zettelkasten` `백링크/wiki-link` `태그 체계` `MOC` `markdown-oxide LSP` `자동화 스크립트`
