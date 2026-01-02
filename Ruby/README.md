# BEN2 Ruby API Client (background_removal.rb)

A minimal Ruby client for BackgroundErase.NET v2. Upload an image, get back a PNG with transparency (background removed).

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

## Quick start

1) Get an API key
- Sign in: https://backgrounderase.net/account
- Ensure you’re on a business plan: https://backgrounderase.net/pricing

2) Get the Ruby script
- See Install below (git sparse-checkout or svn export), or copy background_removal.rb into your project.

3) Run it on an image
```bash
# Fetch a sample image (optional)
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg

# Edit background_removal.rb and set API_KEY = "YOUR_API_KEY"
# Then run:
ruby background_removal.rb input.jpg output.png
```
If successful, you’ll see “Saved: output.png” (PNG with transparency).

## Requirements

- Ruby 2.6+ (tested with 2.7, 3.x)
- OpenSSL enabled for your Ruby (most installs have this)
- CA certificates installed on your system so TLS verification works

Notes:
- macOS/Homebrew, Linux, and Windows RubyInstaller builds typically include OpenSSL. If you see “certificate verify failed,” see Troubleshooting.

## Install

Option A: Clone this repo’s Ruby folder
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Ruby
git checkout main
cd Ruby
```

Option B: Export just the Ruby folder
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Ruby
cd Ruby
```

Option C: Copy the single file
- Copy Ruby/background_removal.rb into your project or working directory.

## Configuration

API key (required)
- Edit the file and set:
  - API_KEY = "YOUR_API_KEY_HERE"
- Or call the method with a key:
  - background_removal("input.jpg", "output.png", api_key: "YOUR_API_KEY")
- Recommended: keep keys out of source control. You can use an env var and pass it in:
```bash
export BEN2_API_KEY="YOUR_API_KEY"
ruby -e 'require "./background_removal"; background_removal("input.jpg","output.png", api_key: ENV.fetch("BEN2_API_KEY"))'
```
(Optional) You can also tweak the script to default to ENV["BEN2_API_KEY"] if you prefer.

TLS/CA certificates
- The script verifies TLS and tries common CA bundle locations via build_cert_store.
- You can override with standard env variables:
  - SSL_CERT_FILE=/path/to/cacert.pem
  - SSL_CERT_DIR=/path/to/certs_dir

## Usage

Command line
```bash
ruby background_removal.rb input.jpg output.png
# defaults: input.jpg -> output.png if args omitted
```

As a library in your own Ruby code
```ruby
require_relative "./background_removal"

# Using constant API_KEY set in the file:
background_removal("input.jpg", "output.png")

# Passing the key explicitly:
background_removal("input.jpg", "output.png", api_key: "YOUR_API_KEY")
```

Behavior
- Input field name is image_file (multipart/form-data).
- Output is written to the path you provide (PNG bytes with transparency).
- On success (HTTP 200), the script saves the file.
- On error (non-200), it prints the HTTP status and response body to STDERR.

Supported input types (MIME auto-detected by extension)
- jpg, jpeg → image/jpeg
- png → image/png
- webp → image/webp
- bmp → image/bmp
- gif → image/gif
- tif, tiff → image/tiff
- heic → image/heic
- others → application/octet-stream

Timeouts
- open_timeout: 30s
- read_timeout: 120s
- You can change these in the file if needed.

TLS
- Server certificate is verified (VERIFY_PEER).
- The script builds a cert store from system defaults and common bundle locations.
- If your OpenSSL is unusual, you can optionally force modern TLS by uncommenting:
  - http.min_version = OpenSSL::SSL::TLS1_2_VERSION

## Examples

Download a sample image and run:
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
ruby background_removal.rb input.jpg output.png
```

Use HEIC input (if you have a .heic file on disk):
```bash
ruby background_removal.rb photo.heic cutout.png
```

Call from Ruby with an env var key:
```bash
export BEN2_API_KEY="YOUR_API_KEY"
ruby -e 'require "./background_removal"; background_removal("input.jpg","cutout.png", api_key: ENV.fetch("BEN2_API_KEY"))'
```

## Tips

- Keep your API key secret (env vars > hardcoding).
- Large photos: uploading very large images takes time; consider pre-resizing if appropriate for your workflow.
- Result is always PNG with transparency; name your output accordingly (e.g., .png).

## Troubleshooting

Authentication errors
- 401/403: Check your API key and that your plan is active.

Invalid request / Unsupported media type
- 400/415: Ensure you’re sending a valid image and the field name is image_file (the script already does this).
- Filenames inform MIME detection; if there’s no extension, it falls back to application/octet-stream.

TLS / certificate verify failed
- macOS (Homebrew):
  - brew install ca-certificates
  - brew install openssl@3
  - Try setting SSL_CERT_FILE to a known bundle, e.g.:
    - /opt/homebrew/etc/ca-certificates/cert.pem
    - /opt/homebrew/etc/openssl@3/cert.pem
- Ubuntu/Debian:
  - sudo apt-get update && sudo apt-get install -y ca-certificates
  - sudo update-ca-certificates
- Windows (RubyInstaller):
  - Use the RubyInstaller with MSYS2 and SSL support.
  - Set SSL_CERT_FILE to a cacert.pem if needed.
- Corporate proxy/SSL inspection can break verification; consult your IT for a custom CA and set SSL_CERT_FILE/SSL_CERT_DIR accordingly.

Network timeouts
- Increase open_timeout/read_timeout in the script if your network is slow.

## File reference

background_removal.rb
- guess_mime(path): maps file extensions to MIME types.
- build_cert_store: builds a robust OpenSSL::X509::Store using system defaults, SSL_CERT_FILE/SSL_CERT_DIR if set, and common bundle locations.
- background_removal(src, dst, api_key:): sends a multipart/form-data POST to https://api.backgrounderase.net/v2 with the image under image_file; saves the returned PNG.
- CLI entrypoint: ruby background_removal.rb input.jpg output.png

Issues and PRs are welcome. Please include:
- Ruby version and OS
- Exact command used
- Full error output/logs
- Whether you’re behind a proxy and any SSL_CERT_* settings