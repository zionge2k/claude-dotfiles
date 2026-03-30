#!/usr/bin/env bash
# Stop hook: 세션 종료 시 기본 메트릭 수집
# 매 세션 종료 시 실행되어 추이 분석 가능한 로그를 축적

METRICS_FILE="$HOME/.claude/session-metrics.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d')

# 오늘 실행된 Bash 명령 수
CMD_LOG="$HOME/.claude/bash-command-log.txt"
if [ -f "$CMD_LOG" ]; then
  CMD_COUNT=$(grep -c "^\[$TODAY" "$CMD_LOG" 2>/dev/null || echo 0)
else
  CMD_COUNT=0
fi

# Git 변경 통계 (현재 디렉토리가 git repo인 경우)
if git rev-parse --is-inside-work-tree &>/dev/null; then
  GIT_STAT=$(git diff --stat 2>/dev/null | tail -1 | sed 's/^ *//')
  [ -z "$GIT_STAT" ] && GIT_STAT="clean"
else
  GIT_STAT="not-a-repo"
fi

echo "[$TIMESTAMP] cmds=$CMD_COUNT git=\"$GIT_STAT\"" >> "$METRICS_FILE"
