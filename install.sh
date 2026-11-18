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
MARKER='.feynman-diagram-installer'

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# All temporary work (clone, staging, backups) is cleaned by ONE handler.
TMPROOT="$(mktemp -d)"
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT
LOCK="$TMPROOT/install.lock"

# Uninstall needs no source: handle it before any clone. Serialize per user.
if [ "$UNINSTALL" -eq 1 ]; then
  exec 9>"$HOME/.feynman_skills.lock"
  flock 9
  say "Uninstalling Feynman diagram drawing skills"
  for entry in "${TARGETS[@]}"; do
    label="${entry%%|*}"; dir="${entry##*|}"
    for s in "${SKILLS[@]}"; do
      target="$dir/$s"
      if [ -e "$target" ]; then
        # Remove our installs (marker present) AND legacy marker-less installs
        # that look like ours (SKILL.md with our name in frontmatter).
        if [ -f "$target/$MARKER" ] || grep -q 'name: feynman-diagram' "$target/SKILL.md" 2>/dev/null; then
          run rm -rf "$target"
          say "  removed  $label  $s"
        else
          say "  kept     $label  $s (unmanaged content)"
        fi
      fi
    done
  done
  exit 0
fi

# Source resolution: trust a local checkout ONLY when invoked as a real script
# file next to skills/. `bash`/`/dev/stdin` from a piped install never qualify.
SELF_PATH=""
case "$0" in
  /*|.?*) [ -f "$0" ] && SELF_PATH="$(cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P)/$(basename -- "$0")" ;;
esac
if [ -n "$SELF_PATH" ] && [ -f "$(dirname -- "$SELF_PATH")/skills/feynman-diagram/SKILL.md" ]; then
  SRC="$(dirname -- "$SELF_PATH")/skills"
else
  say "Fetching skills from $REPO ..."
  git clone --depth 1 --quiet "$REPO" "$TMPROOT/repo"
  SRC="$TMPROOT/repo/skills"
fi

# Stage the whole skill set once.
STAGE="$TMPROOT/stage"
mkdir -p "$STAGE"
for s in "${SKILLS[@]}"; do
  cp -R "$SRC/$s" "$STAGE/$s"
  printf '%s\n' 'Installed by feynman_diagram_drawing_skills/install.sh' > "$STAGE/$s/$MARKER"
done

# Serialize install operations too (same lock file as uninstall).
exec 9>"$HOME/.feynman_skills.lock"
flock 9

installed=0
for entry in "${TARGETS[@]}"; do
  label="${entry%%|*}"; dir="${entry##*|}"
  parent="$(dirname "$dir")"
  # The universal target is created even if ~/.agents does not exist yet.
  if [ "$label" != "Agent Skills (universal)" ] && [ ! -d "$parent" ]; then
    continue
  fi

  run mkdir -p "$dir"
  for s in "${SKILLS[@]}"; do
    dest="$dir/$s"
    backup=""
    if [ -e "$dest" ]; then
      # Our installs (marker) and legacy marker-less copies of this skill are
      # both managed and safe to replace; anything else is left alone.
      if [ ! -f "$dest/$MARKER" ] && ! grep -q 'name: feynman-diagram' "$dest/SKILL.md" 2>/dev/null; then
        say "  skipped   $label  $s (unmanaged content)"
        continue
      fi
      if [ "$DRY" -eq 0 ]; then
        backup="$TMPROOT/backup-$installed-$s"
        mv "$dest" "$backup"      # atomic rename: no window without the skill
      fi
    fi
    if [ "$DRY" -eq 1 ]; then
      say "  [dry-run] cp -R $STAGE/$s -> $dest"
    elif ! cp -R "$STAGE/$s" "$dest"; then
      # Failed copy: clear any partial destination, then restore the backup.
      rm -rf "$dest"
      [ -n "$backup" ] && mv "$backup" "$dest"
      say "  ERROR: failed to install $label/$s; previous state restored" >&2
      exit 1
    else
      [ -n "$backup" ] && rm -rf "$backup"   # success: drop the backup now
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
