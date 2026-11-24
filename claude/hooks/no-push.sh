#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks anything that sends work to a remote.
# Exit 2 sends stderr back to Claude and cancels the command. You push yourself.
# Rules live in no-push.patterns, shared with no-push.ps1.
set -euo pipefail

dir=$(dirname "$(readlink -f "$0")")
command=$(jq -r '.tool_input.command // ""')

while IFS=$'\t' read -r label pattern; do
  [[ -z "$label" || "$label" == \#* ]] && continue
  match=$(grep -Pzoi -m1 -- "$pattern" <<<"$command" | tr '\0\n' '  ' || true)
  if [[ -n "$match" ]]; then
    echo "Blocked: this command $label (\`${match% }\`). Only the user pushes or publishes. Tell them it's ready." >&2
    exit 2
  fi
done <"$dir/no-push.patterns"
exit 0
