# Security Policy

이 저장소는 개인 dotfiles 설정을 포함하고 있으며, public 저장소로 안전하게 공개하기 위해 다음 보안 정책을 준수합니다.
(msbaek/dotfiles의 보안 정책을 기반으로 이 저장소에 맞게 조정함)

## 🔒 보안 원칙

### 1. 민감한 정보 제외
- **API 키, 토큰, 비밀번호**: 모든 실제 값은 `.env.*` 파일에 저장하고 `.gitignore`에 제외
- **SSH 키 및 인증서**: `.ssh/`, `.pem`, `.key` 등 모든 인증 파일 제외
- **개인 인증 정보**: 로컬 전용 설정(`settings.local.json` 내 시크릿 등)은 커밋 전 검토

### 2. 템플릿 제공
- 실제 값이 필요한 설정은 `*.example` 파일로 템플릿 제공
- 실제 값은 placeholder로 대체하고 사용법을 주석으로 안내

### 3. 경로 일반화
- 하드코딩된 개인 경로(`/Users/iseong`) 대신 `$HOME`, `~` 사용
- pre-commit 훅(`check-hardcoded-paths.sh`)이 자동 검사

## 🛡️ 보안 도구

### Pre-commit 훅
다음 도구들이 자동으로 민감한 정보 커밋을 방지합니다:

```bash
# 설치
pip install pre-commit detect-secrets
pre-commit install

# baseline 재생성 (false positive 정리 시)
detect-secrets scan --baseline .secrets.baseline
```

로컬 훅: `check-env-files.sh`(실제 .env 차단), `check-hardcoded-paths.sh`(개인 경로 차단),
`check-sensitive-files.sh`(인증서 확장자 차단) — `.claude/hooks/` 참조.

### GitHub Secret Scanning
- Push protection 활성화로 실수 방지 (설정 절차: `GITHUB-SECURITY-SETUP.md`)
- Secret scanning 자동 감지
- Dependabot 보안 알림

## ⚠️ 현재 노출된 정보

### 개인정보 (낮은 위험)
- **GitHub 계정**: zionge2k
- **이메일**: zion.geek.py@gmail.com (커밋 메타데이터)
- **프로젝트 이름**: `.config/cc-projects.list`의 개인 프로젝트 디렉토리명

이 정보들은 일반적으로 공개되어도 보안상 큰 문제가 없는 수준입니다.

## 🚨 금지사항

커밋하지 말아야 할 파일들:
- `.env`, `.env.*` (실제 환경변수 — `.example` 제외)
- `.ssh/config` 등 실제 SSH 설정
- `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.crt`, `*.cer` (인증 파일)
- 실제 API 키나 토큰이 포함된 파일 (MCP 서버 토큰, `settings.local.json`의 시크릿 등)

## 📋 보안 체크리스트

새로운 설정 파일 추가 시 확인사항:

- [ ] 민감한 정보가 포함되어 있지 않은가?
- [ ] 하드코딩된 경로 대신 환경변수를 사용했는가?
- [ ] 필요시 `.example` 템플릿을 제공했는가?
- [ ] `.gitignore`에 실제 설정 파일을 추가했는가?
- [ ] 홈으로 배포되면 안 되는 파일이면 `.stow-local-ignore`에도 추가했는가?
- [ ] pre-commit 훅이 통과하는가?

## 🔍 정기 감사

월 1회 다음 항목을 점검합니다:
- 새로 추가된 설정 파일의 보안성 검토
- `.gitignore` / `.stow-local-ignore` 패턴의 적절성 확인
- GitHub Security 탭의 secret scanning alert 확인
- 외부 종속성(pre-commit 훅 버전 등)의 보안 업데이트 확인

---

이 정책은 dotfiles의 공개성과 보안성의 균형을 맞추기 위해 지속적으로 업데이트됩니다.
