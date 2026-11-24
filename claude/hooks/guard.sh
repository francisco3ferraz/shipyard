#!/usr/bin/env bash
# PreToolUse hook. Blocks new code that skips tests or swallows errors.
# Exit 2 sends stderr back to Claude and cancels the edit.
# A line containing "guard-ok: <reason>" is allowed, so real exceptions must state their why.
# Rules live in guard.patterns, shared with guard.ps1.
set -euo pipefail

dir=$(dirname "$(readlink -f "$0")")
payload=$(cat)
tool=$(jq -r '.tool_name' <<<"$payload")
path=$(jq -r '.tool_input.file_path // ""' <<<"$payload")

# Prose quotes these patterns legitimately, and the rule and case files hold them on purpose.
if grep -qiE '\.(md|mdx|txt|rst|patterns)$|\.cases\.json$' <<<"$path"; then exit 0; fi

case "$tool" in
  Write)
    new=$(jq -r '.tool_input.content' <<<"$payload")
    old=$([[ -f "$path" ]] && cat "$path" || true)
    ;;
  Edit)
    new=$(jq -r '.tool_input.new_string' <<<"$payload")
    old=$(jq -r '.tool_input.old_string' <<<"$payload")
    ;;
  MultiEdit)
    new=$(jq -r '.tool_input.edits[].new_string' <<<"$payload")
    old=$(jq -r '.tool_input.edits[].old_string' <<<"$payload")
    ;;
  *) exit 0 ;;
esac

# Only judge lines this edit adds, so existing code can still be edited around.
added=$(grep -vxFf <(tr -d '\r' <<<"$old") <(tr -d '\r' <<<"$new") | grep -v 'guard-ok:' || true)
[[ -n "${added//[[:space:]]/}" ]] || exit 0

hits=""
while IFS=$'\t' read -r label pattern; do
  [[ -z "$label" || "$label" == \#* ]] && continue
  match=$(grep -Pzoi -m1 -- "$pattern" <<<"$added" | tr '\0\n' '  ' | head -c 120 || true)
  [[ -n "$match" ]] && hits+="- $label: ${match% }"$'\n'
done <"$dir/guard.patterns"
[[ -n "$hits" ]] || exit 0

cat >&2 <<EOF
Blocked: this edit to $path
$hits
Errors must fail loudly and failing tests must be fixed, not skipped.
Fix the code instead. If this really is right, put "guard-ok: <reason>" on that line and tell the user why.
EOF
exit 2
