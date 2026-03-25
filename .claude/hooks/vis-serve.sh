#!/bin/bash
# Auto-start vis daemon if not running
# Called by SessionStart hook

if ! curl -s http://127.0.0.1:8741/health >/dev/null 2>&1; then
  nohup vis serve >/tmp/vis-serve.log 2>&1 &
  disown
fi
