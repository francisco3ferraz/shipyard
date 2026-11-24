#!/usr/bin/env bash
# Runs both hooks against the shared cases. Exit 0 means every case behaved as expected.
set -uo pipefail

dir=$(dirname "$(readlink -f "$0")")
failed=0

# $1 hook script, $2 cases file, $3 jq filter that turns a case into the hook payload.
test_hook() {
  local passed=0 total=0 case code blocked
  while IFS= read -r case; do
    total=$((total + 1))
    jq -c "$3" <<<"$case" | bash "$dir/$1" 2>/dev/null
    code=$?
    blocked=false
    [[ $code -eq 2 ]] && blocked=true
    if [[ $blocked == "$(jq -r '.blocked' <<<"$case")" ]]; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
      echo "FAIL $1: $case got exit $code"
    fi
  done < <(jq -c '.[]' "$dir/$2")
  echo "$1: $passed/$total passed"
}

test_hook guard.sh guard.cases.json \
  '{tool_name: "Edit", tool_input: {file_path: .file, old_string: (.old // "x"), new_string: .new}}'
test_hook no-push.sh no-push.cases.json \
  '{tool_name: "Bash", tool_input: {command: .command}}'
[[ $failed -eq 0 ]]
