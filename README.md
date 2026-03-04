# Claude Code Dotfiles

Claude Code 개인 설정 파일 관리 레포지토리.
macOS와 Arch Linux에서 동일한 Claude Code 환경을 빠르게 구성합니다.

## Quick Start

```bash
git clone https://github.com/iseong/claude-dotfiles ~/claude-dotfiles
cd ~/claude-dotfiles
./install.sh
```

## What's Included

| 경로 | 설명 |
|------|------|
| `.claude/CLAUDE.md` | 글로벌 지시사항 (코딩 원칙, 워크플로우) |
| `.claude/settings.json` | 환경변수, 훅, 플러그인, 스피너 설정 |
| `.claude/keybindings.json` | 키바인딩 |
| `.claude/agents/` | 커스텀 에이전트 24개 |
| `.claude/commands/` | 슬래시 커맨드 (obsidian, augmented, tdp) |
| `.claude/skills/` | 직접 만든 스킬 9개 |
| `.claude/hooks/` | 알림 훅, 보안 검사 스크립트 |
| `.claude/docs/` | Java 가이드, 스킬 가이드, 스니펫 |

## Install Options

```bash
./install.sh                # 전체 설치 (deps + dotfiles + plugins)
./install.sh --no-plugins   # 플러그인 제외 (dotfiles만)
./install.sh --plugins-only # 플러그인만 설치
```

## Cross-Platform

| 기능 | macOS | Arch Linux |
|------|-------|------------|
| 패키지 관리 | Homebrew | pacman |
| 알림 | terminal-notifier / osascript | notify-send (libnotify) |
| 터미널 | Warp, Ghostty, Kitty | Ghostty, Kitty |
| 심링크 | GNU Stow | GNU Stow |

## What's NOT Included

다음 파일은 `.gitignore`로 제외됩니다:

- `.credentials.json` — OAuth 토큰 (자동 생성됨)
- `settings.local.json` — 로컬 퍼미션
- `plugins/` — 플러그인 캐시 (`install.sh --plugins-only`로 재설치)
- `projects/`, `debug/`, `history.jsonl` — 런타임 데이터
- 외부 설치 스킬 (gh, jira, backlog-md 등) — 플러그인으로 관리

## Customization

### 하드코딩된 경로

`obsidian-ops-team` 에이전트들이 `~/Documents/zion-vault/` 경로를 참조합니다.
Obsidian vault 경로가 다르면 해당 파일들을 수정하세요:

```bash
grep -rl "zion-vault" .claude/agents/
```
