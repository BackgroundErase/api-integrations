# BEN2 Zig API Client (CLI) — Background Removal

A minimal one-file Zig CLI that uploads an image to BackgroundErase.NET and saves the returned cutout (PNG with transparency).

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

This tool:
- Sends a single image as multipart/form-data (field name: image_file)
- Accepts JPG/PNG/WEBP/BMP/GIF (others fallback to application/octet-stream)
- Writes the API’s PNG response to the destination path on success

---

## Requirements

- Zig 0.11+ (tested on recent Zig; if you hit breaking stdlib changes on very new Zig, see the Troubleshooting section)
- Internet access
- System CA certificates installed (Linux typically needs the ca-certificates package)
- macOS, Linux, or Windows

---

## Get the code

Option A: Clone just the Zig folder using sparse checkout
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Zig
git checkout main   # or replace 'main' with the repo's default branch if different
cd Zig
```

Option B: Export the Zig folder via SVN bridge
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Zig
cd Zig
```

You should now have background_removal.zig in this directory.

---

## Get an API key

- Sign in or create an account: https://backgrounderase.net/account
- If needed, purchase/upgrade a plan: https://backgrounderase.net/pricing
- Copy your API key from your account page

---

## Build

Zig build (ReleaseSafe recommended):
```bash
zig build-exe background_removal.zig -O ReleaseSafe
```

This produces an executable named background_removal (background_removal.exe on Windows).

---

## Configure the API key

This CLI supports 3 ways to provide the API key (highest precedence wins):

1) CLI argument (recommended)
2) Env var BG_ERASE_API_KEY
3) Hardcoded DEFAULT_API_KEY in the source file

Examples:

- CLI argument:
```bash
./background_removal ./input.jpg ./output.png YOUR_API_KEY
```

- Environment variable (bash/zsh/fish):
```bash
export BG_ERASE_API_KEY=YOUR_API_KEY
./background_removal ./input.jpg ./output.png
```

- Environment variable (Windows PowerShell):
```powershell
$env:BG_ERASE_API_KEY="YOUR_API_KEY"
.\background_removal.exe .\input.jpg .\output.png
```

- Hardcoded default (edit background_removal.zig, set DEFAULT_API_KEY):
```zig
const DEFAULT_API_KEY = "YOUR_API_KEY_HERE";
```
Note: Do not commit real keys to source control.

---

## Quick test

Get a sample image:
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

Run (using CLI argument):
```bash
./background_removal ./input.jpg ./output.png YOUR_API_KEY
```

If successful:
- Exit code 0
- output.png is saved in the working directory
- Console prints:
  ✅ Saved: ./output.png

On error:
- Non-zero exit
- Prints HTTP status and any error payload from the API

---

## Usage

The program requires:
- src: path to the input image
- dst: path to save the output PNG
- [API_KEY]: optional third arg (otherwise use env var or default)

Help/usage (printed when arguments are missing):
```
Usage:
  background_removal <src> <dst> [API_KEY]

API key precedence: CLI arg > BG_ERASE_API_KEY env var > hardcoded default
```

---

## How it works

- POST https://api.backgrounderase.net/v2
- Headers:
  - x-api-key: YOUR_API_KEY
  - Content-Type: multipart/form-data; boundary=...
- Form:
  - image_file: the uploaded image (filename and MIME set based on extension)
- Success (HTTP 200): raw PNG bytes with transparency are returned
- Error (non-200): prints status and raw response

MIME detection by extension:
- .jpg, .jpeg → image/jpeg
- .png → image/png
- .webp → image/webp
- .bmp → image/bmp
- .gif → image/gif
- Fallback → application/octet-stream

Upload/read caps:
- Input file read cap: 100 MB
- Response read cap: 100 MB

Note on memory:
- The program builds the multipart body in memory; for very large files, memory usage will be roughly input size + minimal overhead.

---

## Platform notes

- Linux: ensure system CAs are installed (e.g., apt-get install ca-certificates, yum install ca-certificates).
- macOS: system keychain is used by default.
- Windows: uses system trust store.

---

## Troubleshooting

- TLS/Certificate error on Linux:
  - Install/update CA bundle: e.g., apt-get install ca-certificates
- 401/403 Unauthorized:
  - Ensure x-api-key is correct, not expired, and tied to a valid plan
- Empty or unexpected output:
  - Check that your input path exists and is readable
  - Confirm output path is writable
- Zig compile errors on very new Zig versions:
  - Zig’s stdlib APIs can change. If you see http/tls API changes:
    - Try Zig 0.11–0.15
    - Or open an issue with your Zig version and build errors

---

## Integrating into your project

- You can copy background_removal.zig into your repo and adapt:
  - Change the field name or endpoint if needed
  - Stream large files instead of buffering in memory
  - Add CLI flags for timeouts or advanced options
- For programmatic use in Zig:
  - Lift the code in main() into a reusable function that accepts the image bytes and returns PNG bytes or an error

---

## Notes

- The tool saves PNG with transparency; if you request output.png, ensure your viewer supports alpha to see the cutout correctly.
- The file extension informs MIME type; if uploading a buffer with an arbitrary name, choose an extension that matches the content type.
- This example keeps things simple and synchronous. For production usage, consider:
  - Timeouts and retries
  - Better error handling and structured error parsing
  - Streaming multipart instead of buffering to reduce peak memory usage

---

## File list

- background_removal.zig — The complete CLI tool (single file)