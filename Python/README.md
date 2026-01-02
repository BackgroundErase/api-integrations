# BEN2 Python API Client (single-file) for BackgroundErase.NET

A minimal Python script that uploads an image to BackgroundErase.NET, removes the background via the v2 API, and saves the transparent PNG to disk.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

This client uses only the Python standard library (no external dependencies).

## Quick start

1) Get an API key
- Create an account or sign in: https://backgrounderase.net/account
- If needed, purchase a plan: https://backgrounderase.net/pricing

2) Download this Python folder (one of the options below)

Option A: Git sparse checkout (only the Python folder)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Python
git checkout main   # or replace 'main' with the repo's default branch if different
cd Python
```

Option B: Subversion export (no git metadata)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Python
cd Python
```

3) Put your API key in the script
- Open background_removal.py and replace:
  - API_KEY = "YOUR_API_KEY"
  with your actual key.

4) Get a sample input image (or use your own)
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

5) Run the script
```bash
python3 background_removal.py
```

- On success you’ll see:
  - ✅ Saved: ./output.png
- The output is a PNG with transparency.

## Files

- background_removal.py
  - Minimal function background_removal(src, dst) that:
    - Detects content type from file extension
    - Builds a multipart/form-data POST with field name image_file
    - Sends to https://api.backgrounderase.net/v2 with x-api-key header
    - Writes the returned PNG bytes to the destination path

Default paths in the script:
- INPUT_PATH = "./input.jpg"
- OUTPUT_PATH = "./output.png"

Edit these to suit your files, or import and call the function from your own code.

## Requirements

- Python 3.8+ (uses only standard library: http.client, os, uuid, mimetypes)
- Network access to https://api.backgrounderase.net

No third-party packages are required.

## Configuration

API key
- Required header: x-api-key: YOUR_API_KEY
- In this script, set the API_KEY constant:
  - API_KEY = "YOUR_API_KEY"
- Keep your API key secret. Do not commit it to public repos.

Base URL
- https://api.backgrounderase.net/v2 (no change needed)

MIME type detection
- Determined via mimetypes.guess_type(filename) from the file extension.
- Common supported inputs: jpg, jpeg, png, heic, webp
- If detection fails, the script falls back to application/octet-stream
- Tip: Ensure your file extension matches the image type.

## Programmatic usage (import into your own code)

You can import the function and call it from another module:

```python
from background_removal import background_removal, API_KEY

# Optionally set API_KEY dynamically (e.g., from env var)
# import os; background_removal.API_KEY = os.getenv("BEN2_API_KEY", API_KEY)

background_removal("path/to/photo.jpg", "path/to/output.png")
```

The function will:
- POST the image as multipart form field image_file
- Save a PNG with transparency at the destination path on HTTP 200
- Print status and any error text for non-200 responses

## What the API returns

- On success: raw PNG bytes (with transparency)
- On error: non-200 HTTP status and a JSON or text message in the response body

This script prints:
- ✅ Saved: <path> on success
- ❌ <status> <reason> <message> on failure

## Common issues and troubleshooting

- 401 Unauthorized
  - Check your API key is set correctly and active. Business plan may be required.
  - Generate/manage at https://backgrounderase.net/account

- 400/415 Bad Request or Unsupported Media Type
  - Ensure the input file exists and is a valid image.
  - Use a proper file extension (e.g., .jpg, .png, .heic, .webp) so MIME detection works.

- 413 Payload Too Large
  - The input image may exceed plan or endpoint limits. Try a smaller image.

- 429 Too Many Requests
  - You may have hit rate/plan limits. Wait or upgrade your plan.

- 5xx Server errors
  - Temporary server issue. Retry after a short delay.

- Proxy/Firewall/SSL issues
  - Ensure your environment allows HTTPS to api.backgrounderase.net

## Notes and tips

- File paths
  - Use absolute paths if running from a different working directory.
  - On Windows, prefer raw strings or forward slashes: r"C:\path\to\file.jpg" or "C:/path/to/file.jpg"

- Multiple files
  - Loop over your files and call background_removal for each source/destination pair.

- Output format
  - Always PNG (with transparency). Use the .png extension for the destination.

- Privacy
  - Don’t hardcode or commit your API key. Consider environment variables or a config file.

## Reference: Script contents

background_removal.py:
```python
import http.client, os, uuid, mimetypes

API_KEY = "YOUR_API_KEY"

def background_removal(src, dst):
    fname = os.path.basename(src)
    ctype = mimetypes.guess_type(src)[0] or "application/octet-stream"
    boundary, CRLF = "----%s" % uuid.uuid4().hex, "\r\n"

    with open(src, "rb") as f: data = f.read()

    body = (
        f"--{boundary}{CRLF}"
        f'Content-Disposition: form-data; name="image_file"; filename="{fname}"{CRLF}'
        f"Content-Type: {ctype}{CRLF}{CRLF}"
    ).encode() + data + f"{CRLF}--{boundary}--{CRLF}".encode()

    headers = {
        "Content-Type": f"multipart/form-data; boundary={boundary}",
        "x-api-key": API_KEY,
        "Content-Length": str(len(body))
    }

    conn = http.client.HTTPSConnection("api.backgrounderase.net")
    conn.request("POST", "/v2", body=body, headers=headers)
    resp = conn.getresponse()
    out = resp.read()

    if resp.status == 200:
        with open(dst, "wb") as f: f.write(out)
        print("✅ Saved:", dst)
    else:
        print("❌", resp.status, resp.reason, out.decode(errors="ignore"))
    conn.close()

INPUT_PATH = "./input.jpg"
OUTPUT_PATH = "./output.png"

background_removal(INPUT_PATH, OUTPUT_PATH)
```

Tip: If you prefer, you can read the API key from an environment variable. Replace the API_KEY line with:
```python
import os
API_KEY = os.getenv("BEN2_API_KEY", "YOUR_API_KEY")
```

## Support

- Account, billing, and API keys: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing
- Report issues with this integration: open an issue or PR in the repository, including:
  - Python version
  - OS/environment
  - Exact error output and steps to reproduce