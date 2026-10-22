#!/bin/bash
# Mirror a compatible A13 ROM (crDroid 9.15 for ginkgo/willow)
# into a dedicated GitHub release tag so files never vanish.
set -euo pipefail

ROM_URL="${ROM_URL:-}"
ROM_ZIP="${ROM_ZIP:-crdroid-9.15-ginkgo-*.zip}"
ROM_TAG="rom-crdroid-9.15"

if [ -z "$ROM_URL" ]; then
    echo "Usage: ROM_URL=<zip-url> bash scripts/mirror-rom.sh"
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "==> Downloading ROM: $ROM_URL"
curl -fsSL "$ROM_URL" -o rom.zip

echo "==> Publishing release: $ROM_TAG"
gh release create "$ROM_TAG" \
    --title "crDroid 9.15 (A13) mirror - ginkgo/willow" \
    --generate-notes \
    rom.zip
echo "Done: $ROM_TAG"
