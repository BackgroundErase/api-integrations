# BackgroundErase.NET Lua CLI (BEN2)

A tiny Lua command-line helper that uploads an image to BackgroundErase.NET and saves the cutout (PNG with transparency). It uses multipart/form-data over HTTPS and returns raw PNG bytes.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

What it does:
- Reads an input image from disk
- Sends it to the API as field name image_file
- Saves the returned PNG to the destination path

File in this folder:
- background_removal.lua

Supported input extensions for MIME detection:
- jpg, jpeg, png, gif, bmp, webp, tif, tiff (others fallback to application/octet-stream)

Notes:
- Output is a PNG with transparency (regardless of input format)
- Field name used: image_file
- Auth header: x-api-key: YOUR_API_KEY


## Requirements

- Lua 5.1+ or LuaJIT
- LuaRocks
- LuaSocket and LuaSec (https)
- OpenSSL installed on your system (LuaSec depends on it)
- Internet access

Install the Lua dependencies:
```bash
luarocks install luasocket
luarocks install luasec
```

Quick sanity check:
```bash
lua -e 'require("ssl.https"); require("ltn12"); print("OK")'
```
If this prints OK, you’re ready.


## Get an API key

You need an active plan to call the API:
1) Sign in or create an account: https://backgrounderase.net/account  
2) If needed, purchase/upgrade: https://backgrounderase.net/pricing  
3) Copy your API key from the Account page


## Install this script

Option A: Git sparse-checkout
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Lua
git checkout main
cd Lua
```

Option B: SVN export (download just this folder)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Lua
cd Lua
```

Option C: Copy the single file
- Download/copy background_removal.lua into your project or a working directory


## Usage

Basic usage:
```bash
lua background_removal.lua <src> <dst> [API_KEY]
```
- src: path to your input image (jpg/png/gif/bmp/webp/tif/tiff)
- dst: where to save the result PNG
- API_KEY (optional): your key; if omitted, the script reads BG_ERASE_API_KEY from the environment

Environment variable option:
```bash
export BG_ERASE_API_KEY=YOUR_API_KEY
lua background_removal.lua input.jpg output.png
```

Direct argument option:
```bash
lua background_removal.lua input.jpg output.png YOUR_API_KEY
```

Windows PowerShell example:
```powershell
$env:BG_ERASE_API_KEY="YOUR_API_KEY"
lua background_removal.lua .\input.jpg .\output.png
```

Get a sample image:
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

Exit codes:
- 0 = success (prints “Saved: …”)
- 1 = runtime error (prints a message to stderr)
- 2 = usage error (missing args)


## OS-specific notes

macOS:
- If LuaSec fails to build, install OpenSSL and point LuaRocks to it:
  - brew install openssl@3
  - luarocks install luasec OPENSSL_DIR=$(brew --prefix openssl@3) OPENSSL_LIBDIR=$(brew --prefix openssl@3)/lib

Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y lua5.4 lua5.4-dev luarocks libssl-dev
luarocks install luasocket
luarocks install luasec
```

Windows:
- Install Lua and LuaRocks (e.g., via Chocolatey, Scoop, or Lua for Windows)
- Then:
  - luarocks install luasocket
  - luarocks install luasec
- If LuaSec fails, using MSYS2/MinGW or a prebuilt Lua/LuaRocks distribution with OpenSSL can help


## How it works (quick technical notes)

- Builds a multipart/form-data request with a random boundary
- Sends your image bytes as image_file with the guessed Content-Type based on file extension
- Adds the header x-api-key: YOUR_API_KEY
- On HTTP 200, writes the response body directly to the output file (PNG bytes)
- On non-200, prints an error including HTTP status

API endpoint used:
- POST https://api.backgrounderase.net/v2
- Form field: image_file
- Returns: raw PNG bytes


## Troubleshooting

- “Missing API key. Pass as argv[3] or set BG_ERASE_API_KEY.”
  - Provide your key as the 3rd CLI argument or set BG_ERASE_API_KEY

- HTTPS request failed / SSL errors
  - Ensure LuaSec is installed and that your system has CA certificates
  - On Linux: install ca-certificates
  - On macOS with Homebrew OpenSSL, see notes above
  - Firewalls/SSL intercept proxies can break TLS; try on a different network

- HTTP 401 Unauthorized
  - Invalid or expired API key

- HTTP 4xx/5xx
  - 413: file too large (reduce image size)
  - 415: unsupported media type (try jpg or png)
  - 429: too many requests (plan/limits)
  - 500+: retry or contact support

- File read/write errors
  - Check file paths, permissions, and that dst’s directory exists

- MIME type detection
  - Unknown extensions fall back to application/octet-stream; prefer common image extensions


## Security

- Treat your API key like a password
- Don’t commit keys to version control
- Prefer environment variables for local development and CI


## Extending or embedding

This script is written as a CLI tool. If you want to use it as a module from another Lua file, expose the function by returning it at the end:

- Change the bottom to:
  - return background_removal

Then in your code:
```lua
local background_removal = require("background_removal")
local ok, err = background_removal("input.jpg", "output.png", os.getenv("BG_ERASE_API_KEY"))
assert(ok, err)
```

By default, the script runs its CLI when invoked directly and stays quiet when required.


## Example session

```bash
# 1) Install deps
luarocks install luasocket
luarocks install luasec

# 2) Get an image
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg

# 3) Run (using env var)
export BG_ERASE_API_KEY=YOUR_API_KEY
lua background_removal.lua input.jpg output.png

# 4) Check result
file output.png   # should report “PNG image data”
```

Issues and pull requests are welcome. Please include:
- OS and Lua/LuaRocks versions
- Exact command you ran
- Full error output/logs