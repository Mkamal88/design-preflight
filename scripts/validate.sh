#!/usr/bin/env bash
# Checks the skill before a release: frontmatter, description length,
# referenced files and plugin manifests. Used by CI; safe to run locally.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT/skills/design-preflight"
SKILL="$SKILL_DIR/SKILL.md"

# Codex limits descriptions to 500 characters; Claude Code allows 1024.
MAX_DESCRIPTION_CHARS=500

errors=0
fail() { echo "FAIL: $1"; errors=$((errors + 1)); }
ok() { echo "ok:   $1"; }

[ -f "$SKILL" ] || { echo "FAIL: $SKILL missing"; exit 1; }

[ "$(head -n 1 "$SKILL")" = "---" ] && ok "frontmatter starts the file" || fail "SKILL.md must start with ---"

name="$(sed -n '2,10p' "$SKILL" | grep -E '^name:' | head -n 1 | sed -E 's/^name: *"?([^"]*)"?$/\1/')"
[ "$name" = "design-preflight" ] && ok "name is design-preflight" || fail "name is '$name', expected design-preflight"

description="$(sed -n '2,10p' "$SKILL" | grep -E '^description:' | head -n 1 | sed -E 's/^description: *//')"
length="$(printf '%s' "$description" | wc -m | tr -d ' ')"
if [ -z "$description" ]; then
  fail "description missing"
elif [ "$length" -gt "$MAX_DESCRIPTION_CHARS" ]; then
  fail "description is $length characters (max $MAX_DESCRIPTION_CHARS)"
else
  ok "description is $length characters"
fi

# Every references/... or scripts/... path named in SKILL.md exists.
for ref in $(grep -oE '(references|scripts)/[A-Za-z0-9_.-]+\.(md|sh)' "$SKILL" | sort -u); do
  [ -f "$SKILL_DIR/$ref" ] && ok "$ref exists" || fail "$ref is referenced but missing"
done

for script in "$SKILL_DIR"/scripts/*.sh "$ROOT/install.sh"; do
  [ -x "$script" ] && ok "$(basename "$script") is executable" || fail "$script is not executable"
done

for json in "$ROOT/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json"; do
  if python3 -m json.tool "$json" >/dev/null 2>&1; then ok "$(basename "$json") is valid JSON"; else fail "$json is not valid JSON"; fi
done

echo
if [ "$errors" -gt 0 ]; then
  echo "$errors check(s) failed."
  exit 1
fi
echo "All checks passed."
