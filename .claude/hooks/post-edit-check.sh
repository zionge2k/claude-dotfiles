#!/usr/bin/env bash
# PostToolUse hook: Edit/Write 후 JSON/YAML 문법 자동 검증
# stdin: {"tool_name":"Edit","tool_input":{"file_path":"...","old_string":"...","new_string":"..."}}
# stdout으로 에러 메시지 출력 시 Claude에게 전달됨

INPUT=$(cat)

if command -v jq &>/dev/null; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  exit 0
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

case "$FILE" in
  *.json)
    if ! jq . "$FILE" > /dev/null 2>&1; then
      echo "⚠️ JSON syntax error in: $FILE"
    fi
    ;;
  *.yaml|*.yml)
    if command -v python3 &>/dev/null; then
      if ! python3 -c "import yaml; yaml.safe_load(open('$FILE'))" 2>/dev/null; then
        echo "⚠️ YAML syntax error in: $FILE"
      fi
    fi
    ;;
esac

exit 0
