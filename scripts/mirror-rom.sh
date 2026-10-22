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
# SourceForge /download redirects to a mirror; -L follows, --trust-server-auth off
BASENAME="$(basename "$(printf '%s' "$URL" | sed 's|/download$||')")"
echo "==> Downloading (this can take a few minutes)..."
curl -L -o rom.zip "$URL"
echo "==> Downloaded $(ls -la rom.zip | awk '{print $5}') bytes"

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
