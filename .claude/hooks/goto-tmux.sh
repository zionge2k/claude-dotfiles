#!/usr/bin/env bash
# Navigate to a specific tmux session:window.pane and activate Ghostty.
#
# Called by:
#   1. tmux client-focus-in hook (no args — reads @goto-target option)
#   2. Direct invocation: goto-tmux.sh <session:window.pane>

TMUX_BIN="/opt/homebrew/bin/tmux"
LOCATION="${1:-}"

# Focus-in hook mode: read and IMMEDIATELY clear tmux option
if [ -z "$LOCATION" ]; then
  LOCATION=$("$TMUX_BIN" show -gv @goto-target 2>/dev/null) || exit 0
  [ -z "$LOCATION" ] && exit 0
  # Clear before switching — prevents double-fire
  "$TMUX_BIN" set -gu @goto-target 2>/dev/null
fi

# Parse session:window.pane
SESSION="${LOCATION%%:*}"
WINDOW_PANE="${LOCATION#*:}"
WINDOW="${WINDOW_PANE%%.*}"
PANE="${WINDOW_PANE#*.}"

if "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
  "$TMUX_BIN" select-window -t "${SESSION}:${WINDOW}" 2>/dev/null
  [ "$PANE" != "$WINDOW" ] && "$TMUX_BIN" select-pane -t "${SESSION}:${WINDOW}.${PANE}" 2>/dev/null
fi

# Activate Ghostty only when called directly
if [ -n "$1" ]; then
  osascript -e 'tell application "Ghostty" to activate' 2>/dev/null
fi
