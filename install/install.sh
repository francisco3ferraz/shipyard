#!/usr/bin/env bash
# Links Shipyard into your user-level Claude Code config on Linux. Safe to re-run.
# Links, not copies, so /retrospective and /add-language edit this repo directly.
# Usage: ./install.sh [claude dir, default ~/.claude]
set -euo pipefail

claude_dir=${1:-$HOME/.claude}
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
settings="$claude_dir/settings.json"
memory="$claude_dir/CLAUDE.md"

for tool in jq git grep; do
  command -v "$tool" >/dev/null || { echo "Missing $tool. Install it and re-run." >&2; exit 1; }
done
echo x | grep -qP 'x' || { echo "Your grep lacks -P. Install GNU grep and re-run." >&2; exit 1; }

link() {
  if [[ -L "$1" && "$(readlink "$1")" == "$2" ]]; then return; fi
  if [[ -e "$1" || -L "$1" ]]; then echo "$1 already exists and is not a link to $2. Move it aside and re-run." >&2; exit 1; fi
  ln -s "$2" "$1"
}

backup="$claude_dir/backups/shipyard-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup" "$claude_dir/skills"
for f in "$settings" "$memory"; do [[ -f "$f" ]] && cp "$f" "$backup/"; done

# Drop links into this repo whose target is gone, so renames and moves don't leave dead links.
for l in "$claude_dir"/* "$claude_dir"/skills/*; do
  if [[ -L "$l" && "$(readlink "$l")" == "$root"/* && ! -e "$l" ]]; then rm "$l"; fi
done
link "$claude_dir/shipyard" "$root"
for skill in "$root"/skills/*/; do
  skill=${skill%/}
  link "$claude_dir/skills/$(basename "$skill")" "$skill"
done
link "$claude_dir/agents" "$root/agents"
chmod +x "$root"/hooks/*.sh

# The import sits between markers so a re-run replaces it instead of appending twice.
# Older installs used workflow markers, so match both and write the shipyard ones.
block=$'<!-- shipyard:begin -->\n@~/.claude/shipyard/rules/CLAUDE.md\n<!-- shipyard:end -->'
touch "$memory"
if grep -qE '<!-- (shipyard|workflow):begin -->' "$memory"; then
  BLOCK="$block" awk '
    /<!-- (shipyard|workflow):begin -->/ { print ENVIRON["BLOCK"]; skip = 1; next }
    /<!-- (shipyard|workflow):end -->/ { skip = 0; next }
    !skip
  ' "$memory" >"$memory.tmp"
else
  { [[ -s "$memory" ]] && cat "$memory" && echo; echo "$block"; } >"$memory.tmp"
fi
mv "$memory.tmp" "$memory"

# Dependency installs ask first. Pushing is denied, and the no-push hook catches what deny rules miss.
[[ -f "$settings" ]] || echo '{}' >"$settings"
jq --slurpfile rules "$here/permissions.json" --arg hooks "$claude_dir/shipyard/hooks" '
  def hook($matcher; $script): {matcher: $matcher, hooks: [{type: "command", command: "bash \"\($hooks)/\($script)\""}]};
  .permissions.ask = ((.permissions.ask // []) as $e | $e + ($rules[0].ask - $e))
  | .permissions.deny = ((.permissions.deny // []) as $e | $e + ($rules[0].deny - $e))
  | .hooks.PreToolUse = ([(.hooks.PreToolUse // [])[] | select(any(.hooks[]?; .command | test("(guard|no-push)\\.(ps1|sh)")) | not)]
      + [hook("Write|Edit|MultiEdit"; "guard.sh"), hook("Bash"; "no-push.sh")])
' "$settings" >"$settings.tmp"
mv "$settings.tmp" "$settings"

echo "Shipyard linked into $claude_dir. Backup in $backup. Restart Claude Code."
