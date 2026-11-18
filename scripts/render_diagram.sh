#!/usr/bin/env bash
# Render one .asy diagram to PDF+PNG and publish the complete artifact set.
#
#   scripts/render_diagram.sh name.asy destination_folder
#
# Requires: asy, a rasterizer (pdftoppm by default), mktemp, flock or shlock.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <diagram.asy> <destination_folder>" >&2
  exit 2
fi

SRC="$1"
DEST="$2"

[ -f "$SRC" ] || { echo "not a file: $SRC" >&2; exit 2; }
case "$SRC" in
  *.asy) ;;
  *) echo "source must end in .asy: $SRC" >&2; exit 2 ;;
esac

command -v asy >/dev/null 2>&1 || { echo "asy not found" >&2; exit 3; }
RASTER="${PDFTOPPM:-pdftoppm}"
command -v "$RASTER" >/dev/null 2>&1 || { echo "rasterizer not found: $RASTER" >&2; exit 3; }

# Validate/create the destination before rendering.
mkdir -p -- "$DEST" || exit 1
DEST_ABS="$(cd -- "$DEST" && pwd -P)" || exit 1
NAME="$(basename -- "$SRC" .asy)"

# Serialize renders to the same destination. Lock lives in a private temp dir,
# never at a caller-controlled path. Lock failures stop the render.
LOCKROOT="$(mktemp -d)" || exit 1
LOCK="$LOCKROOT/render.lock"
LOCK_FD=9
if command -v flock >/dev/null 2>&1; then
  : > "$LOCK"
  eval "exec ${LOCK_FD}>\"$LOCK\""
  flock "$LOCK_FD" || { rm -rf "$LOCKROOT"; exit 1; }
  LOCK_KIND=flock
elif command -v shlock >/dev/null 2>&1; then
  LINK="$LOCKROOT/render.slock"
  i=0
  until shlock -f "$LINK" -p $$; do
    i=$((i+1)); [ "$i" -ge 50 ] && { rm -rf "$LOCKROOT"; exit 1; }
    sleep 0.1
  done
  LOCK_KIND=shlock
else
  echo "no supported lock tool (flock/shlock)" >&2
  rm -rf "$LOCKROOT"; exit 3
fi

# Version guard: never let an older render overwrite a newer published one.
VERSION_FILE="$DEST_ABS/.render-version"
request_version="$(date +%s%N)"
if [ -f "$VERSION_FILE" ]; then
  published_version="$(cat "$VERSION_FILE" 2>/dev/null || echo 0)"
  case "$published_version" in ''|*[!0-9]*) published_version=0 ;; esac
  if [ "$request_version" -le "$published_version" ]; then
    echo "a newer render of $NAME already exists; refusing to publish stale output" >&2
    exit 1
  fi
fi

cleanup_lock() {
  [ "${LOCK_KIND:-}" = shlock ] && rm -f "$LOCKROOT/render.slock"
  rm -rf "$LOCKROOT"
}
trap cleanup_lock EXIT

# Stage everything in a private directory created BESIDE the destination so
# the final rename is same-filesystem and atomic.
STAGE="$(mktemp -d -p "$DEST_ABS" .render-stage.XXXXXX)" || exit 1
PUBLISHED=0
cleanup_stage() {
  if [ "$PUBLISHED" -eq 0 ]; then
    echo "render failed; staged artifacts preserved at: $STAGE" >&2
  else
    rm -rf "$STAGE"
  fi
}
trap 'cleanup_stage; cleanup_lock' EXIT

# Stage the source and its regular, size-bounded sibling dependencies.
cp -- "$SRC" "$STAGE/$NAME.asy" || exit 1
srcdir="$(cd -- "$(dirname -- "$SRC")" && pwd -P)"
for dep in "$srcdir"/*.asy; do
  [ -e "$dep" ] || continue
  [ "$(basename -- "$dep")" = "$NAME.asy" ] && continue
  [ -f "$dep" ] && [ ! -L "$dep" ] || { echo "rejecting non-regular dependency: $dep" >&2; exit 1; }
  [ "$(wc -c < "$dep")" -le 1048576 ] || { echo "dependency too large: $dep" >&2; exit 1; }
  cp -- "$dep" "$STAGE/" || exit 1
done

# Compile and rasterize inside the staging directory.
( cd "$STAGE" && asy -f pdf -- "$NAME.asy" ) || exit 1
"$RASTER" -png -r 200 -singlefile -- "$STAGE/$NAME.pdf" "$STAGE/$NAME" || exit 1
[ -s "$STAGE/$NAME.pdf" ] && [ -s "$STAGE/$NAME.png" ] || exit 1

# Publish the whole set via one atomic directory rename. Move any previous
# artifacts into the staged directory first so the swap is all-or-nothing.
for ext in asy pdf png; do
  [ -e "$DEST_ABS/$NAME.$ext" ] && mv -- "$DEST_ABS/$NAME.$ext" "$STAGE/old-$NAME.$ext"
done
if mv -- "$STAGE" "$DEST_ABS/.rendered-$NAME"; then
  STAGE="$DEST_ABS/.rendered-$NAME"
  for ext in asy pdf png; do
    [ -e "$STAGE/$NAME.$ext" ] && mv -- "$STAGE/$NAME.$ext" "$DEST_ABS/"
  done
  printf '%s\n' "$request_version" > "$VERSION_FILE"
  rm -rf "$STAGE"
  PUBLISHED=1
else
  exit 1
fi

echo "published: $DEST_ABS/$NAME.asy, $NAME.pdf, $NAME.png"
