#!/usr/bin/env bash
# Install the feynman-diagram drawing skill into every AI agent found on this machine.
#
#   curl -fsSL https://raw.githubusercontent.com/ammelsayed/feynman_diagram_drawing_skills/main/install.sh | bash
#
# or, from a clone:
#
#   ./install.sh              # install
#   ./install.sh --dry-run    # show what would happen
#   ./install.sh --uninstall  # remove
set -euo pipefail

REPO="https://github.com/ammelsayed/feynman_diagram_drawing_skills.git"
DRY=0
UNINSTALL=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) printf 'Unrecognized option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

# Agent skill directories, in the order we report them.
# Each entry: "Label|path"
TARGETS=(
  "Claude Code|$HOME/.claude/skills"
  "Codex|$HOME/.codex/skills"
  "OpenCode|$HOME/.config/opencode/skills"
  "Cursor|$HOME/.cursor/skills"
  "zcode|$HOME/.zcode/skills"
  "DSH|$HOME/.dsh/skills"
  "WorkBuddy|$HOME/.workbuddy/skills"
  "Agent Skills (universal)|$HOME/.agents/skills"
)

SKILLS=(feynman-diagram)

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# Uninstall never needs source files: handle it before any clone.
if [ "$UNINSTALL" -eq 1 ]; then
  say "Uninstalling Feynman diagram drawing skills"
  for entry in "${TARGETS[@]}"; do
    label="${entry%%|*}"; dir="${entry##*|}"
    for s in "${SKILLS[@]}"; do
      target="$dir/$s"
      if [ -e "$target" ]; then
        # Only remove a directory we own: require our marker file.
        if [ -f "$target/.feynman-diagram-installer" ]; then
          run rm -rf "$target"
          say "  removed  $label  $s"
        else
          say "  kept     $label  $s (not installed by this installer)"
        fi
      fi
    done
  done
  exit 0
fi

# Resolve the source. A piped installer has no local checkout: $0 is often
# "bash" or "/dev/stdin", so only trust a local source when the script is a
# real file that sits next to skills/. Never trust the caller's CWD.
SRC=""
SELF="$(cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P)/$(basename -- "$0")" || SELF=""
if [ -f "$SELF" ] && [ -f "$(dirname -- "$SELF")/skills/feynman-diagram/SKILL.md" ]; then
  SRC="$(dirname -- "$SELF")/skills"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  say "Fetching skills from $REPO ..."
  git clone --depth 1 --quiet "$REPO" "$TMP/repo"
  SRC="$TMP/repo/skills"
fi

# Stage every destination first, then swap. This prevents a failed/interrupted
# copy from leaving a missing or partial live skill, and avoids interleaved
# concurrent installs landing in nested directories.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
for s in "${SKILLS[@]}"; do
  cp -R "$SRC/$s" "$STAGE/$s"
  printf '%s\n' 'Installed by feynman_diagram_drawing_skills/install.sh' > "$STAGE/$s/.feynman-diagram-installer"
done

installed=0
for entry in "${TARGETS[@]}"; do
  label="${entry%%|*}"; dir="${entry##*|}"
  parent="$(dirname "$dir")"

  # The universal target is valid even if ~/.agents does not exist yet.
  if [ "$label" != "Agent Skills (universal)" ] && [ ! -d "$parent" ]; then
    continue
  fi

  run mkdir -p "$dir"
  for s in "${SKILLS[@]}"; do
    dest="$dir/$s"
    backup=""
    if [ -e "$dest" ]; then
      if [ ! -f "$dest/.feynman-diagram-installer" ]; then
        say "  skipped   $label  $s (existing data not managed by this installer)"
        continue
      fi
      backup="$(mktemp -d)/$(basename -- "$dest")"
      mkdir -p "$(dirname -- "$backup")"
      run mv "$dest" "$backup"     # preserve a restore point
    fi
    if ! run cp -R "$STAGE/$s" "$dest"; then
      [ -n "$backup" ] && mv "$backup" "$dest"
      say "  ERROR: failed to install $label/$s; previous version restored" >&2
      exit 1
    fi
    say "  installed  $label  ->  $dest"
    installed=$((installed + 1))
  done
done

if [ "$installed" -eq 0 ]; then
  say "No supported agent found. Create one of these directories and re-run:"
  for entry in "${TARGETS[@]}"; do say "  ${entry##*|}"; done
  exit 1
fi

say ""
say "Done. $installed skill installs. Restart the agent, or run its reload command."
