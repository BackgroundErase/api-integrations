#!/usr/bin/env bash
# background_removal.sh
# Usage:
#   ./background_removal.sh <src> <dst> [API_KEY]
# Examples:
#   BG_ERASE_API_KEY=your_key ./background_removal.sh ./input.jpg ./output.png
#   ./background_removal.sh ./input.jpg ./output.png your_key

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <src> <dst> [API_KEY]" >&2
  exit 1
fi

SRC="$1"
DST="$2"
API_KEY="${3:-${BG_ERASE_API_KEY:-}}"

if [[ -z "${API_KEY}" ]]; then
  echo "❌ Missing API key. Pass it as arg 3 or set BG_ERASE_API_KEY." >&2
  exit 1
fi

if [[ ! -r "$SRC" ]]; then
  echo "❌ Source file not found/readable: $SRC" >&2
  exit 1
fi

# Detect MIME type (fallback to octet-stream)
if command -v file >/dev/null 2>&1; then
  CTYPE="$(file -b --mime-type "$SRC" || true)"
else
  CTYPE=""
fi
CTYPE="${CTYPE:-application/octet-stream}"

# Optional: ensure output dir exists
mkdir -p "$(dirname "$DST")"

# Do the multipart POST. We set explicit type and filename to mirror your Python example.
curl \
  --fail --silent --show-error \
  -H "x-api-key: ${API_KEY}" \
  -F "image_file=@${SRC};type=${CTYPE};filename=$(basename "$SRC")" \
  "https://api.backgrounderase.net/v2" \
  -o "$DST"

echo "✅ Saved: $DST"
