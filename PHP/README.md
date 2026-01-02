# BackgroundErase.NET PHP example (multipart cURL)

Minimal PHP client that uploads an image to BackgroundErase.NET and saves the cutout (PNG with transparency). Implements multipart/form-data using PHP cURL and the header x-api-key to call https://api.backgrounderase.net/v2.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Purchase/upgrade a plan: https://backgrounderase.net/pricing

File in this folder:
- background_removal.php

What it does:
- Sends your input file as field image_file via multipart/form-data
- On HTTP 200, writes the returned PNG bytes to the output path
- Provides helpful error messages for non-200 responses (tries to decode JSON)

## Requirements

- PHP 7.4+ (PHP 8.x recommended)
- PHP cURL extension enabled
- fileinfo extension recommended (for MIME detection)
- OpenSSL/CA certs for HTTPS (standard on most systems)

Verify extensions:
```bash
php -m | grep -E 'curl|fileinfo'
php -v
```

## Install

Option A: Clone only the PHP folder
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set PHP
git checkout main
cd PHP
```

Option B: Export only the PHP folder (no full git history)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/PHP
cd PHP
```

Option C: Copy the single file
- Copy PHP/background_removal.php into your project

## Quick start (CLI)

1) Get an API key
- Sign in: https://backgrounderase.net/account
- If needed, buy/upgrade: https://backgrounderase.net/pricing

2) Download a sample image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

3) Run the script
- You can pass the API key via:
  - Third CLI argument
  - Environment variable BG_ERASE_API_KEY
  - Edit DEFAULT_API_KEY in the script (not recommended for production)

Examples:
```bash
# Using CLI argument
php background_removal.php input.jpg output.png YOUR_API_KEY

# Using env var
export BG_ERASE_API_KEY=YOUR_API_KEY
php background_removal.php input.jpg output.png
```

Expected output:
```
✅ Saved: output.png
```

If something goes wrong, you’ll see a helpful error, e.g.:
```
❌ Request failed (Content-Type: application/json): HTTP 401 — Invalid API key
```

## Using from your PHP code

You can call the function from another PHP script:
```php
<?php
require_once __DIR__ . '/background_removal.php';

$apiKey = getenv('BG_ERASE_API_KEY') ?: 'YOUR_API_KEY';
$src = __DIR__ . '/input.jpg';
$dst = __DIR__ . '/output.png';

try {
    background_removal($src, $dst, $apiKey);
    // $dst now contains the returned PNG with transparency
} catch (Throwable $e) {
    error_log($e->getMessage());
    http_response_code(500);
}
```

Notes:
- Function signature: background_removal(string $src, string $dst, string $apiKey): void
- The function:
  - Validates file existence/readability
  - Detects MIME via fileinfo/mime_content_type (fallback to application/octet-stream)
  - Posts field image_file with CURLFile
  - Sets header x-api-key: YOUR_API_KEY
  - Writes the response body to $dst on HTTP 200

## API specifics

- HTTP method: POST
- URL: https://api.backgrounderase.net/v2
- Headers:
  - x-api-key: YOUR_API_KEY
  - Do not set Content-Type manually; cURL sets the proper multipart boundary
- Body: multipart/form-data with:
  - image_file: your image file (jpg, jpeg, png, webp, heic, etc.)
- Response:
  - 200: Binary PNG bytes (background-removed image, with transparency)
  - Non-200: Often JSON with fields like error, message, or detail

## Common issues and fixes

- 401 Unauthorized
  - Invalid/missing API key. Ensure you set x-api-key correctly or BG_ERASE_API_KEY is exported in your shell.

- 415 Unsupported Media Type
  - Ensure you’re using multipart/form-data and sending field name image_file (the code already does this).

- 400 Bad Request
  - Corrupt or zero-byte input file. Verify the path and that PHP can read it.

- 413 Payload Too Large
  - Image exceeds server limits. Try a smaller image.

- SSL errors (local dev, Windows, WSL)
  - Ensure your PHP has access to CA certificates. On Windows, set curl.cainfo in php.ini to a valid cacert.pem.

- Timeouts
  - Default timeout is 120s in this script. You can adjust CURLOPT_TIMEOUT if needed.

## Security notes

- Don’t hardcode API keys in source for production. Prefer environment variables or secure secrets management.
- Avoid logging sensitive response bodies or full binary payloads.

## Run multiple files (example)

```bash
export BG_ERASE_API_KEY=YOUR_API_KEY
for f in ./inputs/*.{jpg,jpeg,png,webp,heic}; do
  [ -f "$f" ] || continue
  out="./outputs/$(basename "${f%.*}").png"
  php background_removal.php "$f" "$out" || echo "Failed: $f"
done
```

## Support

- Account/billing: https://backgrounderase.net/pricing
- API key management: https://backgrounderase.net/account
- If you open an issue, please include:
  - PHP version (php -v)
  - OS
  - Any error output (redact your API key)