#!/usr/bin/env bash
# Claude Code Hook for Desktop Notifications (cross-platform)

TOOL_NAME="${CLAUDE_HOOK_TOOL_NAME:-Unknown Tool}"
TIMESTAMP=$(date '+%H:%M:%S')

~/.claude/hooks/notify.sh "Claude Code Activity" "Tool: $TOOL_NAME ($TIMESTAMP)"

echo "[$(date)] Tool called: $TOOL_NAME" >> /tmp/claude-hook.log
