#!/usr/bin/env bash
# SessionStart hook — gathers context from 3 sources and injects it as additionalContext.
# Adapted from msbaek/dotfiles (.codex/hooks/session-start-context.sh).
# Sources:
#   1. Active plans — global .claude/plans/INDEX.md "## Active" section (upstream
#      convention) AND date folders (YYYY-MM-DD-*) whose INDEX.md says "Status: active"
#      (this repo's convention, see CLAUDE.md "when starting a new session")
#   2. Current month journal (~/.claude/journals/YYYY-MM.journal.md), last 15 lines
#   3. Project ai-learnings.md, first 20 lines
# Every source is optional — missing files are silently skipped.

set +e

PARTS=()

# Source 1a: global INDEX.md "## Active" section
INDEX="$PWD/.claude/plans/INDEX.md"
if [ -f "$INDEX" ]; then
  ACTIVE=$(awk '/^## Active/{flag=1; next} /^## /{flag=0} flag' "$INDEX" 2>/dev/null | sed '/^[[:space:]]*$/d' | head -10)
  if [ -n "$ACTIVE" ]; then
    PARTS+=("### Active Plans (.claude/plans/INDEX.md)")
    PARTS+=("$ACTIVE")
    PARTS+=("")
  fi
fi

# Source 1b: date folders with per-folder INDEX.md marked "Status: active"
ACTIVE_DIRS=""
for idx in "$PWD"/.claude/plans/20[0-9][0-9]-*/INDEX.md; do
  [ -f "$idx" ] || continue
  if grep -qiE '^Status:[[:space:]]*active' "$idx" 2>/dev/null; then
    ACTIVE_DIRS="${ACTIVE_DIRS}- $(basename "$(dirname "$idx")")
$(head -10 "$idx" | sed 's/^/  /')
"
  fi
done
if [ -n "$ACTIVE_DIRS" ]; then
  PARTS+=("### Active Plan Folders (.claude/plans/YYYY-MM-DD-*)")
  PARTS+=("$ACTIVE_DIRS")
  PARTS+=("")
fi

# Source 2: current month journal
JOURNAL="$HOME/.claude/journals/$(date +%Y-%m).journal.md"
if [ -f "$JOURNAL" ]; then
  RECENT=$(tail -15 "$JOURNAL" 2>/dev/null)
  if [ -n "$RECENT" ]; then
    PARTS+=("### Recent Journal (last 15 lines, $(basename "$JOURNAL"))")
    PARTS+=("$RECENT")
    PARTS+=("")
  fi
fi

# Source 3: project learnings
LEARNINGS="$PWD/ai-learnings.md"
if [ -f "$LEARNINGS" ]; then
  LRN=$(head -20 "$LEARNINGS" 2>/dev/null)
  if [ -n "$LRN" ]; then
    PARTS+=("### Project Learnings (ai-learnings.md, head 20)")
    PARTS+=("$LRN")
    PARTS+=("")
  fi
fi

if [ ${#PARTS[@]} -eq 0 ]; then
  echo '{}'
  exit 0
fi

OUTPUT="## SessionStart auto context"
for p in "${PARTS[@]}"; do
  OUTPUT="${OUTPUT}
${p}"
done

if [ ${#OUTPUT} -gt 4000 ]; then
  OUTPUT="${OUTPUT:0:4000}
... (truncated at 4KB)"
fi

ESCAPED=$(printf '%s' "$OUTPUT" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))" 2>/dev/null)

if [ -z "$ESCAPED" ]; then
  echo '{}'
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ${ESCAPED}
  }
}
EOF
