#!/usr/bin/env bash
set -euo pipefail

API_KEY="${API_KEY:-$(grep -Eo 'API_KEY=.+$' .env | cut -d= -f2-)}"
: "${API_KEY:?Missing API_KEY (set .env or export API_KEY)}"

SRC_ABS="$(readlink -f "${1:-assets/input.jpg}")"
OUT_ABS="$(readlink -f "${2:-out/output.png}")"
BF_FILE="${BF_FILE:-bf/trigger.bf}"

[[ -f "$SRC_ABS" ]] || { echo "Missing image: $SRC_ABS" >&2; exit 1; }
mkdir -p "$(dirname "$OUT_ABS")"

# 1) Run a Brainfuck file (doesn't stream bytes; just demonstrates BF ran)
if command -v bf >/dev/null 2>&1; then
  bf "$BF_FILE" >/dev/null || true
else
  echo "Warning: 'bf' interpreter not found; skipping BF step." >&2
fi

# 2) Let curl handle HTTPS + multipart properly
curl -fsS \
  -H "x-api-key: ${API_KEY}" \
  -F "image_file=@${SRC_ABS}" \
  https://api.backgrounderase.net/v2 \
  -o "$OUT_ABS"

echo "✅ Saved: $OUT_ABS"
