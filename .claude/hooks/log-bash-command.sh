#!/usr/bin/env bash
# PreToolUse hook: Bash 명령어를 타임스탬프와 함께 로깅
# stdin: {"tool_name":"Bash","tool_input":{"command":"...","description":"..."}}

LOG_FILE="$HOME/.claude/bash-command-log.txt"

INPUT=$(cat)

# jq가 없으면 raw로 저장
if command -v jq &>/dev/null; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // "unknown"' 2>/dev/null)
  DESC=$(echo "$INPUT" | jq -r '.tool_input.description // ""' 2>/dev/null)
else
  CMD="$INPUT"
  DESC=""
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ -n "$DESC" ] && [ "$DESC" != "null" ]; then
  echo "[$TIMESTAMP] $CMD — $DESC" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] $CMD" >> "$LOG_FILE"
fi
