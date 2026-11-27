#!/bin/bash
# Build Stable channel feeds from the signed appcasts archived with each release.
# CRA_SITE_ROOT points to a mounted or local copy of /opt/browser-update/public.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?usage: scripts/promote.sh <version> [--dry-run]}"
VERSION="${VERSION#v}"
[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+)+$ ]] || exit 1
MODE="${2:-}"
case "$MODE" in ''|--dry-run) ;; *) exit 1 ;; esac
SITE="${CRA_SITE_ROOT:?set CRA_SITE_ROOT to the update site public directory}"
ARCHIVE="$SITE/downloads/cra/$VERSION"
if [ -z "${CRA_PROMOTE_UNTESTED:-}" ]; then
  grep -qx 'result: passed' "$ARCHIVE/web-features-arm64.txt" ||
    { echo 'web-features-arm64.txt must record a pass for this release' >&2; exit 1; }
fi
OUT="build/promote"
mkdir -p "$OUT"
for SUFFIX in "" "-intel"; do
  CURRENT="$SITE/cra/appcast$SUFFIX.xml"
  NEWEST="$(python3 - "$CURRENT" <<'PY'
import sys
from xml.etree import ElementTree as ET
print(ET.parse(sys.argv[1]).findtext('./channel/item/{http://www.andymatuschak.org/xml-namespaces/sparkle}shortVersionString') or '')
PY
)"
  [[ "$NEWEST" =~ ^[0-9]+(\.[0-9]+)+$ ]] &&
    [ "$(printf '%s\n%s\n' "$VERSION" "$NEWEST" | sort -V | tail -1)" = "$NEWEST" ] ||
    { echo "No eligible release in $CURRENT" >&2; exit 1; }
  python3 scripts/appcast-feeds.py "$OUT" "$SUFFIX" "$CURRENT" "$NEWEST" \
    "$ARCHIVE/appcast$SUFFIX.xml" "$VERSION"
done
[ "$MODE" != "--dry-run" ] || exit 0
for NAME in appcast.xml appcast-stable.xml appcast-intel.xml appcast-stable-intel.xml; do
  TEMP="$(mktemp "$SITE/cra/.$NAME.XXXXXX")"
  install -m 644 "$OUT/$NAME" "$TEMP"
  mv -f "$TEMP" "$SITE/cra/$NAME"
done
printf '%s\n' "$VERSION" > scripts/stable-version
