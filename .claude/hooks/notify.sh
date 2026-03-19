#!/usr/bin/env bash
# Cross-platform notification script for Claude Code hooks
# Usage: notify.sh "Title" "Message"
#
# On macOS inside tmux: clicking the notification activates Ghostty and
# tmux's client-focus-in hook auto-switches to the originating window/pane.

TITLE="${1:-Claude Code}"
MESSAGE="${2:-Notification}"
SET_GOTO="${3:-}"  # Pass "goto" to enable deep-link (Stop hook only)
TMUX_BIN="/opt/homebrew/bin/tmux"

case "$(uname -s)" in
  Darwin)
    if command -v terminal-notifier &>/dev/null; then
      NOTIFY_ARGS=(-title "$TITLE" -sound default -timeout 30)

      if [ -n "$TMUX" ]; then
        TMUX_TARGET=$("$TMUX_BIN" display-message -p '#{session_name}:#{window_index}.#{pane_index}')
        TMUX_WINDOW_NAME=$("$TMUX_BIN" display-message -p '#{window_name}')
        MESSAGE="$MESSAGE [$TMUX_WINDOW_NAME]"
        # Save target only for Stop hook notifications (deep-link on click)
        [ "$SET_GOTO" = "goto" ] && "$TMUX_BIN" set -g @goto-target "$TMUX_TARGET"
      fi

      NOTIFY_ARGS+=(-activate com.mitchellh.ghostty)
      NOTIFY_ARGS+=(-message "$MESSAGE")
      terminal-notifier "${NOTIFY_ARGS[@]}"
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
