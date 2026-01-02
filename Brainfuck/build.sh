#!/usr/bin/env bash
set -euo pipefail

# Load API key
set -a
source .env
set +a

# Ensure systemf is built
( cd systemf && make build )

ABS_IMG_PATH="$(readlink -f assets/input.jpg)"
OUT_PATH="out/output.png"

mkdir -p bf out

# Generate Brainfuck
./scripts/genbf.py "$API_KEY" "$ABS_IMG_PATH" "$OUT_PATH" > bf/main.bf

echo "Generated bf/main.bf"
