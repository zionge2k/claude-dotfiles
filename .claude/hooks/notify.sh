#!/usr/bin/env bash
# Cross-platform notification script for Claude Code hooks
# Usage: notify.sh "Title" "Message"

TITLE="${1:-Claude Code}"
MESSAGE="${2:-Notification}"

case "$(uname -s)" in
  Darwin)
    if command -v terminal-notifier &>/dev/null; then
      terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound default -timeout 30
    elif command -v osascript &>/dev/null; then
      osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Ping\""
    fi
    ;;
  Linux)
    if command -v notify-send &>/dev/null; then
      notify-send "$TITLE" "$MESSAGE" --expire-time=5000
    fi
    ;;
esac
