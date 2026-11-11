#!/usr/bin/env bash
# Installs the design-preflight skill for Claude Code and/or OpenAI Codex.
# Run ./install.sh --help for options.

set -euo pipefail

SKILL_NAME="design-preflight"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills/$SKILL_NAME"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Targets (default: every agent found on this machine):
  --claude           Install for Claude Code
  --codex            Install for OpenAI Codex
  --all              Install for both

Where:
  (default)          For your user, in every project
                       Claude Code: ~/.claude/skills/design-preflight
                       Codex:       ~/.codex/skills/design-preflight
  --project <path>   Only for one repository (copied into <path>/.claude/skills
                     and/or <path>/.codex/skills, so it can be committed)

How:
  (default)          Symbolic link to this folder, so `git pull` updates the skill
  --copy             Copy the files instead
  --force            Replace an existing design-preflight install

Other:
  --uninstall        Remove the skill from the chosen targets
  -h, --help         Show this help

Environment overrides:
  CLAUDE_SKILLS_DIR  Claude Code skills folder (default ~/.claude/skills)
  CODEX_SKILLS_DIR   Codex skills folder (default $CODEX_HOME/skills or ~/.codex/skills)
EOF
}

want_claude=0
want_codex=0
mode="link"
project=""
force=0
action="install"

while [ $# -gt 0 ]; do
  case "$1" in
    --claude) want_claude=1 ;;
    --codex) want_codex=1 ;;
    --all) want_claude=1; want_codex=1 ;;
    --copy) mode="copy" ;;
    --force) force=1 ;;
    --uninstall) action="uninstall" ;;
    --project)
      [ $# -ge 2 ] || { echo "error: --project needs a path" >&2; exit 1; }
      project="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: skill not found at $SRC" >&2
  exit 1
fi

# No target given: pick the agents that are installed.
if [ "$want_claude" -eq 0 ] && [ "$want_codex" -eq 0 ]; then
  if [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; then want_claude=1; fi
  if [ -d "${CODEX_HOME:-$HOME/.codex}" ] || command -v codex >/dev/null 2>&1; then want_codex=1; fi
  if [ "$want_claude" -eq 0 ] && [ "$want_codex" -eq 0 ]; then
    echo "No Claude Code or Codex install found; installing for both."
    want_claude=1
    want_codex=1
  fi
fi

if [ -n "$project" ]; then
  if [ ! -d "$project" ]; then
    echo "error: project folder not found: $project" >&2
    exit 1
  fi
  project="$(cd "$project" && pwd)"
  # A link would point outside the repository and break for teammates.
  mode="copy"
  claude_dir="$project/.claude/skills"
  codex_dir="$project/.codex/skills"
else
  claude_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
  codex_dir="${CODEX_SKILLS_DIR:-${CODEX_HOME:-$HOME/.codex}/skills}"
fi

# True when the path is (or links to) a design-preflight skill, so we never remove anything else.
is_our_skill() {
  [ -f "$1/SKILL.md" ] && grep -Eq "^name: *\"?$SKILL_NAME\"?\$" "$1/SKILL.md"
}

install_to() { # agent-label skills-dir
  local label="$1" dir="$2" dest="$2/$SKILL_NAME"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(cd "$dest" 2>/dev/null && pwd -P)" = "$(cd "$SRC" && pwd -P)" ] && [ "$mode" = "link" ]; then
      echo "$label: already linked at $dest"
      return 0
    fi
    if [ "$force" -ne 1 ]; then
      echo "$label: $dest already exists. Use --force to replace it." >&2
      return 1
    fi
    if ! is_our_skill "$dest"; then
      echo "$label: $dest is not a design-preflight skill; not replacing it." >&2
      return 1
    fi
    rm -rf "$dest"
  fi

  mkdir -p "$dir"
  if [ "$mode" = "link" ]; then
    ln -s "$SRC" "$dest"
    echo "$label: linked $dest -> $SRC"
  else
    cp -R "$SRC" "$dest"
    chmod +x "$dest"/scripts/*.sh
    echo "$label: copied to $dest"
  fi
}

uninstall_from() { # agent-label skills-dir
  local label="$1" dest="$2/$SKILL_NAME"
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "$label: not installed at $dest"
    return 0
  fi
  if [ -L "$dest" ] || is_our_skill "$dest"; then
    rm -rf "$dest"
    echo "$label: removed $dest"
  else
    echo "$label: $dest is not a design-preflight skill; not removing it." >&2
    return 1
  fi
}

status=0
if [ "$action" = "install" ]; then
  chmod +x "$SRC"/scripts/*.sh
  if [ "$want_claude" -eq 1 ]; then install_to "Claude Code" "$claude_dir" || status=1; fi
  if [ "$want_codex" -eq 1 ]; then install_to "Codex" "$codex_dir" || status=1; fi
  if [ "$status" -eq 0 ]; then
    echo
    echo "Done. Start a new agent session, then try:"
    [ "$want_claude" -eq 1 ] && echo "  Claude Code: /design-preflight ABC-123"
    [ "$want_codex" -eq 1 ] && echo "  Codex:       \$design-preflight ABC-123   (or ask: \"run a design preflight on ABC-123\")"
  fi
else
  if [ "$want_claude" -eq 1 ]; then uninstall_from "Claude Code" "$claude_dir" || status=1; fi
  if [ "$want_codex" -eq 1 ]; then uninstall_from "Codex" "$codex_dir" || status=1; fi
fi
exit "$status"
