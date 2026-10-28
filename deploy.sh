#!/usr/bin/env bash
#
# Publish drnamlabs.com.
#
#   ./deploy.sh            # build, upload, swap in, keep the old site as a backup
#   ./deploy.sh --dry-run  # build, then list files that would be added / removed
#
# Needs only bash, ssh, tar and curl — all present on macOS, Linux, WSL and
# Git Bash for Windows. There is deliberately no rsync: it is the one tool a
# Windows machine does not have.
#
# How it works: dist/ is streamed as a tar over ssh into a staging directory
# beside the web root, checked, and then swapped in with two renames. The
# previous site is not copied but renamed into the backup directory, so a
# deploy is both atomic enough (two renames, milliseconds apart) and
# instantly reversible.
#
# Touches only /var/www/drnamlabs (+ its .incoming sibling and the backups).
# The same host also serves theta.bunnyquant.com, bunnyquant.com and
# bunnyquant.vn from sibling directories; nothing here goes near them, and no
# service is restarted because nginx serves this site as static files.

set -euo pipefail

HOST=theta-server
WEB_ROOT=/var/www/drnamlabs
STAGE="$WEB_ROOT.incoming"
BACKUP_ROOT=/var/www/drnamlabs_backups
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }

dry=""
if [[ "${1:-}" == "--dry-run" ]]; then
  dry=1
  say "DRY RUN — nothing will be written"
fi

say "Building"
cd "$ROOT"
npm run build

# Guard: never publish a CV that still carries red TODO markers.
if [[ -f dist/CV.pdf ]] && command -v pdftotext >/dev/null 2>&1; then
  if pdftotext dist/CV.pdf - 2>/dev/null | grep -q 'TODO:'; then
    echo "REFUSING TO DEPLOY: public/CV.pdf still contains [TODO] placeholders." >&2
    exit 1
  fi
fi

[[ -f dist/index.html ]] || { echo "REFUSING TO DEPLOY: dist/index.html is missing." >&2; exit 1; }
local_count=$(find dist -type f | wc -l | tr -d ' ')

if [[ -n "$dry" ]]; then
  say "Comparing dist/ with $HOST:$WEB_ROOT (file names only, not contents)"
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  (cd dist && find . -type f | LC_ALL=C sort) > "$tmp/local"
  ssh "$HOST" "cd '$WEB_ROOT' && find . -type f | LC_ALL=C sort" > "$tmp/remote"
  echo "  would add:";    LC_ALL=C comm -23 "$tmp/local" "$tmp/remote" | sed 's/^/    + /'
  echo "  would remove:"; LC_ALL=C comm -13 "$tmp/local" "$tmp/remote" | sed 's/^/    - /'
  say "Done (dry run)"
  exit 0
fi

stamp="$(date +%Y%m%d_%H%M%S)"

say "Uploading $local_count files to $HOST:$STAGE"
# COPYFILE_DISABLE stops macOS tar adding ._ AppleDouble files; ustar keeps the
# archive free of extended headers that GNU tar on the server would warn about.
COPYFILE_DISABLE=1 tar --format=ustar -cf - -C dist . \
  | ssh "$HOST" "rm -rf '$STAGE' && mkdir -p '$STAGE' && tar -xf - -C '$STAGE' --no-same-owner"

say "Checking the upload, then swapping it in"
# The old site is renamed to $BACKUP_ROOT/$stamp; if the second rename fails it
# is put straight back.
ssh "$HOST" bash -s -- "$WEB_ROOT" "$STAGE" "$BACKUP_ROOT" "$stamp" "$local_count" <<'REMOTE'
set -euo pipefail
web="$1"; stage="$2"; backups="$3"; stamp="$4"; expect="$5"

[[ "$web" == /var/www/drnamlabs && "$stage" == /var/www/drnamlabs.incoming ]] \
  || { echo "unexpected paths, refusing" >&2; exit 1; }

got=$(find "$stage" -type f | wc -l)
[[ "$got" -eq "$expect" ]] || { echo "staged $got files, expected $expect — not swapping" >&2; exit 1; }
[[ -f "$stage/index.html" ]] || { echo "staged site has no index.html — not swapping" >&2; exit 1; }

chown -R root:root "$stage"
find "$stage" -type d -exec chmod 755 {} +
find "$stage" -type f -exec chmod 644 {} +

mkdir -p "$backups"
mv "$web" "$backups/$stamp"
if ! mv "$stage" "$web"; then
  mv "$backups/$stamp" "$web"
  echo "swap failed; previous site restored" >&2
  exit 1
fi
echo "  previous site kept at $backups/$stamp"
REMOTE

say "Verifying"
fail=0
for p in / /research/ /publications/ /bunnyquant/ /book/ /portfolio/ /favicon.svg; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "https://drnamlabs.com$p")
  printf '  %-18s %s\n' "$p" "$code"
  [[ "$code" == "200" ]] || { echo "  ^ expected 200" >&2; fail=1; }
done
[[ "$fail" -eq 0 ]] || { echo "Some routes failed. Roll back with: ssh $HOST 'mv $WEB_ROOT $WEB_ROOT.bad && mv $BACKUP_ROOT/$stamp $WEB_ROOT'" >&2; exit 1; }

say "Done"
