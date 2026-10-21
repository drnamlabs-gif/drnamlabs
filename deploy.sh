#!/usr/bin/env bash
#
# Publish drnamlabs.com.
#
#   ./deploy.sh            # build, back up what is live, upload
#   ./deploy.sh --dry-run  # show what would change, upload nothing
#
# Touches only /var/www/drnamlabs. The same host also serves
# theta.bunnyquant.com, bunnyquant.com and bunnyquant.vn from sibling
# directories; nothing here goes near them, and no service is restarted
# because nginx serves this site as static files.

set -euo pipefail

HOST=theta-server
WEB_ROOT=/var/www/drnamlabs
BACKUP_ROOT=/var/www/drnamlabs_backups
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }

dry=""
if [[ "${1:-}" == "--dry-run" ]]; then
  dry="--dry-run"
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

if [[ -z "$dry" ]]; then
  stamp="$(date +%Y%m%d_%H%M%S)"
  say "Backing up the live site to $BACKUP_ROOT/$stamp"
  ssh "$HOST" "mkdir -p '$BACKUP_ROOT/$stamp' && cp -a '$WEB_ROOT/.' '$BACKUP_ROOT/$stamp/' 2>/dev/null || true"
fi

say "Uploading to $HOST:$WEB_ROOT"
# --delete so a file dropped from a build stops being served.
rsync -az --delete $dry --itemize-changes dist/ "$HOST:$WEB_ROOT/"

if [[ -z "$dry" ]]; then
  ssh "$HOST" "chown -R root:root '$WEB_ROOT' && find '$WEB_ROOT' -type d -exec chmod 755 {} + && find '$WEB_ROOT' -type f -exec chmod 644 {} +"

  say "Verifying"
  for p in / /research/ /publications/ /bunnyquant/ /book/ /favicon.svg; do
    code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "https://drnamlabs.com$p")
    printf '  %-18s %s\n' "$p" "$code"
    [[ "$code" == "200" ]] || { echo "  ^ expected 200" >&2; }
  done
fi

say "Done"
