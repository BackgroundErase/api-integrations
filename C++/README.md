# BEN2 C++ API Client (single-file, libcurl)

Minimal C++17 client for BackgroundErase.NET. Upload an image, receive a cutout (PNG with transparency), and save it locally.

- API endpoint: https://api.backgrounderase.net/v2
- Field name: image_file (multipart/form-data)
- Response: PNG bytes on success (HTTP 200)
- Get your API key: https://backgrounderase.net/account
- Plans: https://backgrounderase.net/pricing

Requirements
- C++17 compiler (GCC 9+, Clang 10+, MSVC 2019+ recommended)
- libcurl with SSL/TLS enabled
- Internet access to api.backgrounderase.net

Files
- background_removal.cpp (single-file CLI)

Get the code (this folder only)
Option A: Git sparse checkout
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set C++
git checkout main
cd C++
```

Option B: SVN export
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/C++
cd C++
```

Get an API key
- Sign in: https://backgrounderase.net/account
- If needed, buy/upgrade a plan: https://backgrounderase.net/pricing
- Copy your API key (you’ll pass it via env var, CLI arg, or compile-time default)

Build

Linux (Debian/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install -y build-essential libcurl4-openssl-dev
g++ -std=c++17 background_removal.cpp -lcurl -o background_removal
# If using very old GCC (< 9), append: -lstdc++fs
```

Linux (Fedora/RHEL/CentOS)
```bash
sudo dnf install -y gcc-c++ libcurl-devel
g++ -std=c++17 background_removal.cpp -lcurl -o background_removal
```

macOS
- Option A (works on most setups):
```bash
g++ -std=c++17 background_removal.cpp -lcurl -o background_removal
```
- Option B (use Homebrew curl explicitly; recommended if you hit SSL issues):
```bash
brew install curl pkg-config
g++ -std=c++17 background_removal.cpp $(pkg-config --cflags --libs libcurl) -o background_removal
```

Windows

Option A: Visual Studio + vcpkg
1) Install vcpkg and integrate with VS (https://vcpkg.io)
```powershell
vcpkg install curl[ssl] --triplet x64-windows
```
2) Build from “x64 Native Tools Command Prompt for VS”:
- If vcpkg is integrated with MSBuild, create a simple VS project and add background_removal.cpp. Add “curl[ssl]” via vcpkg and build.
- Or compile on the command line (replace VCPKG_ROOT):
```bat
set VCPKG=%VCPKG_ROOT%\installed\x64-windows
cl /std:c++17 /EHsc background_removal.cpp /I %VCPKG%\include ^
  /link /LIBPATH:%VCPKG%\lib libcurl.lib ws2_32.lib wldap32.lib Crypt32.lib Normaliz.lib
```

Option B: MSYS2 MinGW (UCRT64 shown; MINGW64 similar)
```bash
pacman -S --needed mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-curl
g++ -std=c++17 background_removal.cpp -lcurl -o background_removal
```

Optional: CMake build
Create CMakeLists.txt:
```cmake
cmake_minimum_required(VERSION 3.15)
project(background_removal CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(CURL REQUIRED)
add_executable(background_removal background_removal.cpp)
target_link_libraries(background_removal PRIVATE CURL::libcurl)
```
Build:
```bash
cmake -S . -B build
cmake --build build --config Release
```

Run

1) Get a test image:
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

2) Provide your API key (choose one):
- Environment variable:
  - Linux/macOS: export BG_ERASE_API_KEY="YOUR_KEY"
  - Windows (cmd): set BG_ERASE_API_KEY=YOUR_KEY
  - Windows (PowerShell): $env:BG_ERASE_API_KEY="YOUR_KEY"
- CLI argument: background_removal input.jpg output.png YOUR_KEY
- Compile-time default: set kDefaultApiKey in background_removal.cpp

3) Run the tool:
```bash
# if key in env
./background_removal input.jpg output.png

# or passing key explicitly
./background_removal input.jpg output.png YOUR_API_KEY
```

Expected output on success:
✅ Saved: output.png

Program help / exit codes
- Usage:
  background_removal <source_image> <dest_image> [API_KEY]
  (or set environment variable BG_ERASE_API_KEY)

- Exit codes:
  - 0: success
  - 1: bad args / missing API key / source file missing
  - 2: HTTP/libcurl error (see stderr for details)

What the code does
- Sends a multipart/form-data POST to https://api.backgrounderase.net/v2
  - Field name: image_file
  - Filename and MIME type inferred from your input’s extension
- Adds header: x-api-key: YOUR_KEY
- Disables Expect: 100-continue for wider proxy compatibility
- On HTTP 200, writes raw response bytes to the output path (PNG with transparency)
- On errors, prints HTTP status and the response body (if any)

Notes and tips
- Supported inputs: Common raster formats (jpg, jpeg, png, webp, gif, bmp, tif, tiff). Unknown extensions fall back to application/octet-stream.
- Output is PNG with transparency regardless of input format; name your output file output.png.
- Security: Passing API keys via CLI can expose them to local process lists. Prefer environment variables for local development and secret managers in production.
- Timeouts/retries: The sample keeps libcurl defaults. You can add, for example:
  - curl_easy_setopt(curl, CURLOPT_TIMEOUT, 60L);
  - curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 10L);

Troubleshooting
- 401 Unauthorized:
  - Check you’re using the correct API key and that your subscription is active.
- SSL or “no SSL backend” errors:
  - Ensure libcurl is built with SSL (OpenSSL/Schannel/etc.). On Linux, use libcurl4-openssl-dev. On macOS, prefer Homebrew curl. On Windows, use vcpkg curl[ssl].
- linker errors about filesystem:
  - Use -std=c++17. On very old GCC (< 9) also add -lstdc++fs.
- HTTP 413 (payload too large):
  - Use a smaller image or compress before upload.
- 415 Unsupported Media Type:
  - Ensure the input file extension matches the actual format so MIME guessing is correct.
- Proxies/firewalls:
  - Honor system proxy envs (HTTP_PROXY/HTTPS_PROXY). Removing Expect: 100-continue (already in code) helps with some proxies.

API links
- Dashboard, API key: https://backgrounderase.net/account
- Pricing: https://backgrounderase.net/pricing
- Endpoint used here: https://api.backgrounderase.net/v2

Contributing
- Issues and PRs are welcome. Please include:
  - OS and version
  - Compiler and version
  - libcurl version (run curl --version or curl-config --version)
  - Exact build command and output logs