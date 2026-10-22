#!/bin/bash
# Mirror a crDroid A13 build for Redmi Note 8 / 8T (ginkgo) into a dedicated
# GitHub release so the ROM never vanishes.
#
# Usage:
#   bash scripts/mirror-rom.sh                 # auto-detect latest A13 build
#   ROM_URL=https://.../...zip bash scripts/mirror-rom.sh
set -euo pipefail

DEVICE="${DEVICE:-ginkgo}"
VERSION_CODE="${VERSION_CODE:-9}"     # crDroid 9 = Android 13
ROM_TAG="${ROM_TAG:-rom-crdroid-9-a13-${DEVICE}}"
ROM_DIR="/tmp/crdroid-rom"
mkdir -p "$ROM_DIR"
cd "$ROM_DIR"

if [ -n "${ROM_URL:-}" ]; then
    URL="$ROM_URL"
else
    echo "==> Detecting latest crDroid A13 ($DEVICE) download URL"
    # Build page: https://crdroid.net/<device>/<version>
    PAGE="$(curl -sL -A "Mozilla/5.0" "https://crdroid.net/${DEVICE}/${VERSION_CODE}")"
    URL="$(printf '%s' "$PAGE" | grep -oE 'https://sourceforge.net/projects/crdroid/files/[^"]+\.zip/download' | head -1)"
    if [ -z "$URL" ]; then
        echo "ERROR: could not detect crDroid zip URL from build page" >&2
        exit 1
    fi
fi

echo "==> Using URL: $URL"
BASENAME="$(basename "$(printf '%s' "$URL" | sed 's|/download$||')")"

echo "==> Downloading (this can take a few minutes)..."
curl -L -A "Mozilla/5.0" --connect-timeout 30 -o rom.zip "$URL"

# Validate: abort if we did not get a real zip (SF sometimes returns a 403 page)
CT="$(curl -sIL -A "Mozilla/5.0" "$URL" | grep -i '^content-type:' | tail -1)"
SIZE="$(stat -c%s rom.zip 2>/dev/null || echo 0)"
echo "==> Downloaded size: $SIZE bytes ; Content-Type: $CT"

# Sanity: accept only application/zip or application/octet-stream and > 10MB
case "$CT" in
    *zip*|*octet-stream*) : ;;
    *) echo "ERROR: unexpected Content-Type ($CT) — not a zip"; exit 1 ;;
esac
if [ "$SIZE" -lt 10485760 ]; then
    echo "ERROR: downloaded file too small ($SIZE bytes) — likely an error page" >&2
    echo "--- first 200 bytes ---"; head -c 200 rom.zip; echo
    exit 1
fi

# Rename to the official filename for clarity
mv -f rom.zip "${BASENAME}"

echo "==> Publishing release: $ROM_TAG"
gh release view "$ROM_TAG" -R "$REPO" >/dev/null 2>&1 || \
  gh release create "$ROM_TAG" --repo "$REPO" \
    --title "crDroid 9.x A13 - ${DEVICE} (ROM mirror)" \
    --generate-notes
gh release upload "$ROM_TAG" "${BASENAME}" --repo "$REPO" --clobber
echo "==> ROM attached to https://github.com/${REPO}/releases/tag/${ROM_TAG}"

# Optionally add a TWRP recovery mirror
if [ -n "${TWRP_URL:-}" ]; then
    echo "==> Downloading TWRP recovery"
    curl -sLo twrp.img "$TWRP_URL"
    gh release upload "$ROM_TAG" twrp.img --repo "$REPO" --clobber
fi
