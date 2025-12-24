#!/usr/bin/env bash
set -euo pipefail

# stdin: JSON with .tool_input.command
cmd=$(jq -r '.tool_input.command // ""')

# Block list (add as needed)
deny_patterns=(
  'rm\s+-rf\s+/'
  'git\s+reset'
  'git\s+.*(-f|--force)'
)

for pat in "${deny_patterns[@]}"; do
  if echo "$cmd" | grep -Eiq "$pat"; then
    echo "Blocked command: matches denied pattern '$pat'. Use a safer alternative or explain why it's necessary." 1>&2
    exit 2
  fi
done

exit 0