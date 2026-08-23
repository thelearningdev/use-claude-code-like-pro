#!/usr/bin/env bash
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

if echo "$cmd" | grep -qE '(uv add|pip install|poetry add)'; then
  echo "Blocked: dependencies are a deliberate decision. Ask first." >&2
  exit 2
fi
exit 0
