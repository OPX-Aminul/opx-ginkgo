#!/bin/bash
# Wrapper so `bash scripts/build.sh` works from any directory.
set -euo pipefail
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build.sh" "$@"
