#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
cwd=$(echo "$input" | jq -r '.cwd // "."')

log_dir="${cwd}/.claude"
[[ -d "$log_dir" ]] || exit 0
printf '%s %s\n' "$(date -Is)" "$cmd" >> "${log_dir}/bash-commands.log"

exit 0