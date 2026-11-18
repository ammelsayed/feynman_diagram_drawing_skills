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

# Exact frontmatter name match: only a SKILL.md whose `name:` is exactly
# feynman-diagram counts as this skill (whitespace after ':' allowed).
is_our_skill() {
  local d="$1"
  [ -f "$d/SKILL.md" ] && grep -Eq '^name:[[:space:]]*feynman-diagram[[:space:]]*$' "$d/SKILL.md"
}

# Cross-platform lock: flock on Linux, shlock on macOS, best-effort elsewhere.
acquire_lock() {
  LOCK_FD=9
  if command -v flock >/dev/null 2>&1; then
    : > "$LOCK_PATH"                             # file inside our private tmpdir
    eval "exec ${LOCK_FD}>\"$LOCK_PATH\""
    flock "$LOCK_FD" || return 1
    LOCK_KIND=flock
  elif command -v shlock >/dev/null 2>&1; then
    local link="$LOCK_PATH.maclock" i=0
    while ! shlock -f "$link" -p $$; do
      i=$((i+1)); [ "$i" -ge 50 ] && return 1
      sleep 0.1
    done
    LOCK_KIND=shlock
  else
    LOCK_KIND=none
  fi
}
release_lock() {
  if [ "${LOCK_KIND:-none}" = shlock ]; then rm -f "$LOCK_PATH.maclock"; fi
}

# All temporary work is cleaned by one handler. No persistent lock file is
# created in dry-run mode (no lock needed when nothing is mutated).
TMPROOT="$(mktemp -d)"
cleanup() {
  [ -n "${TMPROOT:-}" ] && rm -rf "$TMPROOT"
  release_lock
}
trap cleanup EXIT

if [ "$DRY" -eq 0 ]; then
  LOCK_PATH="$TMPROOT/install.lock"
  acquire_lock || { say "Could not acquire install lock" >&2; exit 1; }
fi

# Uninstall never needs source: handle it before any clone.
if [ "$UNINSTALL" -eq 1 ]; then
  say "Uninstalling Feynman diagram drawing skills"
  for entry in "${TARGETS[@]}"; do
    label="${entry%%|*}"; dir="${entry##*|}"
    for s in "${SKILLS[@]}"; do
      target="$dir/$s"
      if [ -e "$target" ] && { [ -f "$target/$MARKER" ] || is_our_skill "$target"; }; then
        run rm -rf "$target"
        say "  removed  $label  $s"
      elif [ -e "$target" ]; then
        say "  kept     $label  $s (unmanaged content)"
      fi
    done
  done
  exit 0
fi

# Source: trust a local checkout only when this is a real script file sitting
# next to skills/. Piped `bash` has no such file; a bare relative name resolves
# against the current directory. Never trust the CWD otherwise.
SELF_PATH=""
case "$0" in
  */*) [ -f "$0" ] && SELF_PATH="$(cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P)/$(basename -- "$0")" ;;
  *)   [ -f "$PWD/$0" ] && SELF_PATH="$PWD/$0" ;;   # e.g. invoked as `bash install.sh`
esac
if [ -n "$SELF_PATH" ] && [ -f "$(dirname -- "$SELF_PATH")/skills/feynman-diagram/SKILL.md" ]; then
  SRC="$(dirname -- "$SELF_PATH")/skills"
else
  say "Fetching skills from $REPO ..."
  git clone --depth 1 --quiet "$REPO" "$TMPROOT/repo"
  SRC="$TMPROOT/repo/skills"
fi

# Stage the whole set once, on the same filesystem as the destinations where
# possible. Validation happens before touching any live directory.
STAGE="$TMPROOT/stage"
mkdir -p "$STAGE"
for s in "${SKILLS[@]}"; do
  cp -R "$SRC/$s" "$STAGE/$s"
  printf '%s\n' 'Installed by feynman_diagram_drawing_skills/install.sh' > "$STAGE/$s/$MARKER"
done

installed=0
for entry in "${TARGETS[@]}"; do
  label="${entry%%|*}"; dir="${entry##*|}"
  parent="$(dirname "$dir")"
  if [ "$label" != "Agent Skills (universal)" ] && [ ! -d "$parent" ]; then
    continue
  fi

  run mkdir -p "$dir"
  for s in "${SKILLS[@]}"; do
    dest="$dir/$s"
    if [ -e "$dest" ]; then
      if [ -f "$dest/$MARKER" ] || is_our_skill "$dest"; then
        # Already installed: leave the live copy in place. No move, no delete,
        # no rollback window. Users update via --uninstall then install.
        say "  kept      $label  $s (already installed; uninstall first to replace)"
        continue
      fi
      say "  skipped   $label  $s (unmanaged content)"
      continue
    fi
    # Fresh install: a failed copy removes the partial destination; there is no
    # prior data to lose and no backup to corrupt.
    if [ "$DRY" -eq 1 ]; then
      say "  [dry-run] cp -R $STAGE/$s -> $dest"
    elif ! cp -R "$STAGE/$s" "$dest"; then
      rm -rf "$dest"
      say "  ERROR: failed to install $label/$s" >&2
      exit 1
    fi
    say "  installed  $label  ->  $dest"
    installed=$((installed + 1))
  done
done

if [ "$installed" -eq 0 ] && [ "$DRY" -eq 0 ]; then
  say "No new installs. Installed agents already have the skill, or no supported agent was found."
fi

say ""
say "Done. $installed new skill installs. Restart the agent, or run its reload command."
