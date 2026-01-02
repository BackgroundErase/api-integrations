# BackgroundErase.NET C (libcurl) CLI

A minimal, single-file C client for BackgroundErase.NET that uploads an image and saves the cutout (PNG with transparency) to disk.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

File in this folder:
- background_removal.c

## Get an API key

- Create an account or sign in: https://backgrounderase.net/account
- If needed, purchase a plan: https://backgrounderase.net/pricing
- Copy your API key from your account page

## Get this code

Option A: Git (sparse checkout)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set C
git checkout main
cd C
```

Option B: SVN export
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/C
cd C
```

Optional: sample input image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

## Requirements

- A C compiler (GCC/Clang/MSYS2 MinGW/Visual Studio)
- libcurl with SSL/TLS
  - Linux: install via your package manager (e.g., libcurl4-openssl-dev)
  - macOS: system libcurl usually works; Homebrew curl also works
  - Windows:
    - MSYS2 MinGW: pacman -S mingw-w64-x86_64-curl
    - Or use vcpkg to install curl for MSVC

## Build

The file includes a one-line build hint at the top. Common setups:

- Linux (Debian/Ubuntu example)
```bash
sudo apt-get update
sudo apt-get install -y build-essential libcurl4-openssl-dev
gcc -o bgremove background_removal.c -lcurl
```

- macOS (Apple Clang + system curl)
```bash
gcc -o bgremove background_removal.c -lcurl
```
If you installed curl via Homebrew:
```bash
brew install curl
CPPFLAGS="$(pkg-config --cflags libcurl)" LDFLAGS="$(pkg-config --libs libcurl)" \
gcc -o bgremove background_removal.c $CPPFLAGS $LDFLAGS
```

- Windows (MSYS2 MinGW)
```bash
pacman -S --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-curl
# Open "MSYS2 MinGW 64-bit" shell
x86_64-w64-mingw32-gcc -o bgremove.exe background_removal.c -lcurl
```

## API key setup

The program looks for an API key in this order:
1) Command-line argument 3 (explicit): ./bgremove <src> <dst> <API_KEY>
2) Environment variable: BACKGROUND_ERASE_API_KEY
3) Compiled-in default: DEFAULT_API_KEY macro

Ways to provide the key:

- Command-line
```bash
./bgremove input.jpg out.png YOUR_API_KEY
```

- Environment variable
```bash
export BACKGROUND_ERASE_API_KEY=YOUR_API_KEY
./bgremove input.jpg out.png
```
Windows (PowerShell)
```powershell
$env:BACKGROUND_ERASE_API_KEY="YOUR_API_KEY"
.\bgremove.exe input.jpg out.png
```

- Compile-time default (avoid committing real keys)
```bash
gcc -DDEFAULT_API_KEY="\"YOUR_API_KEY\"" -o bgremove background_removal.c -lcurl
./bgremove input.jpg out.png
```

Security tip: Prefer env var or CLI for local testing; avoid committing API keys to source control.

## Usage

Basic:
```bash
# Build
gcc -o bgremove background_removal.c -lcurl

# Run (env var or CLI arg)
BACKGROUND_ERASE_API_KEY=YOUR_API_KEY ./bgremove input.jpg out.png
# or
./bgremove input.jpg out.png YOUR_API_KEY

# On success:
# ✅ Saved: out.png
```

Exit codes:
- 0 = success
- 1 = runtime or HTTP error
- 2 = usage error (missing args or API key)

## What it does

- Uploads your image via multipart/form-data under field name image_file
- Sets the MIME type based on the file extension (png, jpg/jpeg, gif, webp, bmp, tif/tiff, heic, heif; otherwise application/octet-stream)
- Sends header x-api-key: YOUR_API_KEY
- Disables HTTP 100-continue delays (adds Expect:)
- On HTTP 200, writes the binary response to the destination file (PNG with transparency)
- On non-200, prints the HTTP status and the server’s response to stderr

Defaults:
- Endpoint: https://api.backgrounderase.net/v2
- User-Agent: bgremove-c/1.0
- Connect timeout: 15s
- Total timeout: 300s

## Programmatic use from C

You can call the function directly from your code:
```c
int background_removal(const char *src, const char *dst, const char *api_key);
/* Returns 0 on success; nonzero on failure. */
```

Or use the built-in CLI behavior in main():
```bash
./bgremove <src_image> <dst_output> [API_KEY]
```

## Troubleshooting

- Missing libcurl at link time
  - Install development headers (e.g., libcurl4-openssl-dev on Linux)
  - Ensure pkg-config and link flags are correctly set if using a non-system curl

- SSL/CERT errors
  - Make sure your curl/SSL installation has up-to-date CA certificates
  - On Windows, prefer MSYS2 MinGW or vcpkg-built curl with SSL enabled

- HTTP 401 Unauthorized
  - Check the API key value and where it’s sourced from (CLI/env/DEFAULT_API_KEY)

- HTTP 402 Payment Required
  - You may be out of credits or need a paid plan: https://backgrounderase.net/pricing

- HTTP 400/415
  - Input may be invalid or unsupported; verify the file path and extension

- HTTP 413
  - Image too large; try a smaller image

- HTTP 429
  - Rate limit reached; back off and retry later

- Proxy settings
  - libcurl honors standard env vars like HTTP_PROXY/HTTPS_PROXY if set

- Windows paths
  - Quote paths with spaces: ".\bgremove.exe" "C:\path with spaces\in.jpg" out.png

## Notes

- Supported input extensions for MIME detection: png, jpg, jpeg, gif, webp, bmp, tif, tiff, heic, heif
- Output is the processed image bytes returned by the API (typically PNG with transparency)
- The program only writes the output file when the HTTP status is 200

## Example session

```bash
# Get sample image
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg

# Build
gcc -o bgremove background_removal.c -lcurl

# Run
export BACKGROUND_ERASE_API_KEY=YOUR_API_KEY
./bgremove input.jpg out.png

# Result
# ✅ Saved: out.png
```

Issues and pull requests are welcome. When reporting an issue, please include:
- Your OS and compiler version
- libcurl version and how it was installed
- Exact command you ran and full output (including HTTP status)
- A minimal reproduction if possible