# BackgroundErase.NET Perl API Client (CLI)

Minimal Perl script to remove image backgrounds via the BackgroundErase.NET v2 API. Upload an image and save the returned PNG (with transparency) to disk.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

This repo/folder contains:
- background_removal.pl — a small CLI tool using LWP to call the API

## Quick start

1) Get an API key
- Create an account or sign in: https://backgrounderase.net/account
- Ensure your plan includes API access: https://backgrounderase.net/pricing

2) Get the script
Option A: Sparse checkout from the monorepo
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Perl
git checkout main
cd Perl
```

Option B: SVN export (no git history)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Perl
cd Perl
```

3) Install dependencies
- Perl 5.16+ recommended
- Modules: LWP::UserAgent, HTTP::Request::Common, LWP::MediaTypes, File::Basename (core)

Option A: Install to your user dir (recommended; works with the script’s use lib)
```bash
perl -MCPAN -e 'install App::cpanminus'   # if cpanm is not installed yet
cpanm --local-lib=~/perl5 LWP::UserAgent HTTP::Request::Common LWP::MediaTypes
```

Option B: System packages (example for Debian/Ubuntu)
```bash
sudo apt-get update
sudo apt-get install -y libwww-perl liblwp-protocol-https-perl libhttp-message-perl
```

Option C: Windows (Strawberry Perl)
- Open “Perl (command line)” or PowerShell
- Install cpanm if needed: cpan App::cpanminus
- Then: cpanm LWP::UserAgent HTTP::Request::Common LWP::MediaTypes

Note: The script includes:
use lib "$ENV{HOME}/perl5/lib/perl5";
This helps Perl find modules installed with --local-lib=~/perl5 (no shell config needed).

4) Set your API key in the environment
- macOS/Linux (bash/zsh):
```bash
export BG_ERASE_API_KEY="YOUR_API_KEY"
```
- macOS/Linux (fish):
```fish
set -x BG_ERASE_API_KEY "YOUR_API_KEY"
```
- Windows (PowerShell, for current session):
```powershell
$env:BG_ERASE_API_KEY = "YOUR_API_KEY"
```
- Windows (CMD, for current session):
```cmd
set BG_ERASE_API_KEY=YOUR_API_KEY
```
- Windows (persist for your account):
```powershell
setx BG_ERASE_API_KEY "YOUR_API_KEY"
```

5) Download a sample image (optional)
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

6) Run
```bash
# Make executable (macOS/Linux)
chmod +x background_removal.pl

# Then:
perl background_removal.pl input.jpg output.png
# or on macOS/Linux if executable:
./background_removal.pl input.jpg output.png
```

On success:
✅ Saved: output.png

On error, you’ll see the HTTP status and any response body.

## What the script does

- Sends a multipart/form-data POST to https://api.backgrounderase.net/v2
- Field name: image_file
- Header: x-api-key: YOUR_API_KEY
- Guesses Content-Type from the filename extension (via LWP::MediaTypes); falls back to application/octet-stream
- Saves the response bytes (PNG with transparency) to the output path you provide
- User-Agent: BackgroundEraseClient/1.0
- Timeout: 60 seconds

## Supported inputs

The API accepts common image formats. The script determines a MIME type from the filename extension. Typical extensions that resolve well:
- jpg, jpeg → image/jpeg
- png → image/png
- webp → image/webp
- heic → image/heic (if your LWP::MediaTypes knows it)
- unknown extensions fall back to application/octet-stream

Tip: If you have a non-standard extension, you can rename the file to .jpg/.png/.webp before sending, or extend the MIME map in your Perl environment.

## Usage examples

- Basic:
```bash
perl background_removal.pl photo.jpg cutout.png
```

- With absolute paths:
```bash
perl background_removal.pl "/path to/input image.jpg" "/tmp/output.png"
```

- Windows PowerShell:
```powershell
$env:BG_ERASE_API_KEY = "YOUR_API_KEY"
perl background_removal.pl .\input.jpg .\output.png
```

## Configuration and customization

- API key
  - Preferred: set BG_ERASE_API_KEY in the environment (don’t commit keys to source control)
  - Alternative: edit the script and replace 'YOUR_API_KEY' with your key (not recommended)

- Endpoint
  - Default: https://api.backgrounderase.net/v2
  - You can change it in the script if needed

- Timeout/User-Agent
  - Adjust in the script where the LWP::UserAgent is created:
    my $ua = LWP::UserAgent->new(agent => 'BackgroundEraseClient/1.0', timeout => 60);

- Proxies
  - Honor standard env vars, e.g.:
    export https_proxy="http://user:pass@proxy:port"
    export HTTP_PROXY=... / HTTPS_PROXY=...

## Troubleshooting

- 401 Unauthorized
  - BG_ERASE_API_KEY missing or invalid
  - Confirm your subscription includes API access

- 400/415 Bad Request or Unsupported Media Type
  - Ensure the input path is correct and readable
  - Use a common file extension so MIME is detected (jpg, png, webp)
  - The API also accepts bytes even if Content-Type is generic

- SSL/HTTPS errors (Linux)
  - Install HTTPS support for LWP:
    sudo apt-get install liblwp-protocol-https-perl
  - Ensure time is correct and CA certificates are installed

- “Can’t open output” or permissions errors
  - Verify the destination directory exists and is writable

- “Usage: perl … input.jpg output.png”
  - Provide both an input and output path

- Verifying the request manually (for debugging)
  - Equivalent curl:
    curl -X POST "https://api.backgrounderase.net/v2" \
      -H "x-api-key: $BG_ERASE_API_KEY" \
      -F "image_file=@input.jpg" \
      --output output.png

## Development notes

- This is a minimal CLI example using LWP to demonstrate multipart upload and binary response handling
- The script writes the raw response bytes; no image viewing/preview logic is included
- Exit code is 0 on success; non-zero on failure

## License and contributions

- Feel free to adapt this script within your project
- Issues and PRs are welcome; include:
  - Perl version and OS
  - Steps to reproduce
  - Full error output and any logs