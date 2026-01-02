# BackgroundErase.NET Bash/Shell client

Minimal Bash script to remove image backgrounds via the BackgroundErase.NET v2 API. Uploads a single image and saves the returned PNG (with transparency).

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

## Requirements
- Bash (#!/usr/bin/env bash)
- curl
- file (optional, for MIME detection; falls back to application/octet-stream)
- macOS or Linux (WSL also works)

## Install

Option A: Download just the script
```bash
curl -L -o background_removal.sh \
  https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/Bash-Shell/background_removal.sh
chmod +x background_removal.sh
```

Option B: Sparse-checkout this folder
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Bash-Shell
git checkout main
cd Bash-Shell
chmod +x background_removal.sh
```

Option C: Export with SVN
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Bash-Shell
cd Bash-Shell
chmod +x background_removal.sh
```

Optional: sample input image
```bash
curl -L -o input.jpg \
  https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

## Usage

Environment variable (recommended)
```bash
BG_ERASE_API_KEY=YOUR_API_KEY \
  ./background_removal.sh ./input.jpg ./output.png
```

Or pass the API key as arg 3
```bash
./background_removal.sh ./input.jpg ./output.png YOUR_API_KEY
```

Script usage
```text
./background_removal.sh <src> <dst> [API_KEY]
- <src> path to input image (jpg/png/heic/webp/etc.)
- <dst> path to save the returned PNG (directory will be created if needed)
- [API_KEY] optional; if omitted, the script reads BG_ERASE_API_KEY
```

What it does
- Validates inputs and API key
- Detects MIME type via `file` (if available), else uses application/octet-stream
- Sends multipart/form-data with field name image_file
- Saves the API response to <dst> (PNG with transparency)

## Notes
- Supported input types: jpg, jpeg, png, heic, webp, and others (MIME fallback still works)
- The API returns raw PNG bytes on success
- The script is quiet by default but fails on HTTP errors (curl --fail --silent --show-error)

## Troubleshooting
- Missing API key: set BG_ERASE_API_KEY or provide arg 3
- Source file not found/readable: check path and permissions
- Common HTTP errors:
  - 401/403: invalid key or no access to API
  - 413: file too large (check your plan limits)
  - 415: unsupported media type (ensure input is a valid image)
  - 429: rate/credit limit exceeded
- Increase verbosity: edit the curl line to add -v (verbose) if needed
- Install `file` if MIME detection is missing (e.g., on minimal containers)

## Examples

Basic run
```bash
BG_ERASE_API_KEY=YOUR_API_KEY \
  ./background_removal.sh input.jpg output.png
```

Batch a folder
```bash
export BG_ERASE_API_KEY=YOUR_API_KEY
for f in ./in/*.jpg; do
  base="$(basename "$f" .jpg)"
  ./background_removal.sh "$f" "./out/${base}.png"
done
```

CI usage (GitHub Actions snippet)
```bash
- name: Remove background
  run: |
    chmod +x ./Bash-Shell/background_removal.sh
    BG_ERASE_API_KEY=${{ secrets.BEN2_API_KEY }} \
      ./Bash-Shell/background_removal.sh ./input.jpg ./output.png
```

Security tip: never commit your API key. Use environment variables or CI secrets.