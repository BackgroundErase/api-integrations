# BackgroundErase.NET PowerShell Integration

A minimal PowerShell script that uploads an image to BackgroundErase.NET and saves the cutout (PNG with transparency) to disk.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

File included:
- background_removal.ps1

## Requirements

- PowerShell 7+ (pwsh) on Windows/macOS/Linux
  - Windows: winget install Microsoft.PowerShell
  - macOS: brew install --cask powershell
  - Linux: https://learn.microsoft.com/powershell/scripting/install/installing-powershell
- Internet access to https://api.backgrounderase.net

Note: The script uses PowerShell 7 features (null-conditional operator). It will not run on Windows PowerShell 5.1.

## Install

Option A: Clone this repo (sparse checkout of the PowerShell folder)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set PowerShell
git checkout main
cd PowerShell
```

Option B: Export just the PowerShell folder
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/PowerShell
cd PowerShell
```

Option C: Download the single script directly
```bash
curl -L -o background_removal.ps1 \
  https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/PowerShell/background_removal.ps1
```

Get a sample input image (optional):
```bash
curl -L -o input.jpg \
  https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

## Generate your API key

- Sign in or create an account: https://backgrounderase.net/account
- If needed, purchase a plan: https://backgrounderase.net/pricing
- Your API key is shown at the bottom of the Account page

## Usage

Basic:
```bash
pwsh ./background_removal.ps1 -Src "input.jpg" -Dst "output.png" -ApiKey "YOUR_API_KEY"
```

Parameters:
- -Src: Path to the input image (jpg, jpeg, png, webp, bmp, tif, tiff)
- -Dst: Path where the result will be saved (e.g., output.png)
- -ApiKey: Your BackgroundErase.NET API key

Behavior:
- Uploads the image as multipart/form-data under field name image_file
- Sets header x-api-key to your API key
- On success (HTTP 200 and image/* response), saves the returned image bytes to -Dst
- Default HTTP timeout is 120 seconds

Supported input formats:
- jpg, jpeg, png, webp, bmp, tif, tiff
- Unknown extensions fall back to application/octet-stream

Typical output:
- PNG with transparency (alpha). Use a .png destination to preserve transparency.

## Examples

Use an environment variable for your key:
```powershell
# PowerShell 7+ (Windows/macOS/Linux)
$env:BEN2_API_KEY = "YOUR_API_KEY"
pwsh ./background_removal.ps1 -Src "input.jpg" -Dst "output.png" -ApiKey $env:BEN2_API_KEY
```

Batch convert a folder of JPGs to PNG cutouts:
```powershell
# Create output folder
New-Item -ItemType Directory -Force -Path .\out | Out-Null

# Convert all JPG/JPEG files in the current directory
Get-ChildItem -File -Include *.jpg,*.jpeg | ForEach-Object {
  $src = $_.FullName
  $dst = Join-Path ".\out" ($_.BaseName + ".png")
  pwsh ./background_removal.ps1 -Src $src -Dst $dst -ApiKey $env:BEN2_API_KEY
}
```

macOS/Linux example:
```bash
export BEN2_API_KEY="YOUR_API_KEY"
pwsh ./background_removal.ps1 -Src "./input.jpg" -Dst "./output.png" -ApiKey "$BEN2_API_KEY"
```

## Troubleshooting

- 401 Unauthorized:
  - Check that your API key is correct and active
  - Ensure header x-api-key is present (the script sets this automatically)
- 400/415 Unsupported Media Type:
  - Make sure the file extension matches the actual format (or try jpg/png)
- 413 Payload Too Large:
  - Reduce image size before upload
- Network/Proxy issues:
  - Confirm your environment can reach https://api.backgrounderase.net
- Error output:
  - The script prints HTTP status, reason, and response body when the server returns a non-image response

## Security tips

- Do not hardcode your API key in scripts you commit
- Prefer environment variables or a secure secret store
- Rotate keys in your account if they leak

## How it works (API details)

- Endpoint: POST https://api.backgrounderase.net/v2
- Headers: x-api-key: YOUR_API_KEY
- Body: multipart/form-data with a single field:
  - image_file: the uploaded image file
- Response:
  - On success: image/* (typically PNG) bytes
  - On error: text or JSON with error details

## Script reference

background_removal.ps1
- Detects MIME type from file extension
- Sends the file via HttpClient as multipart/form-data (field name image_file)
- Saves the response bytes to the destination path if content-type starts with image/
- Disposes all streams/objects properly and reports errors clearly

Issues and pull requests are welcome. Please include:
- OS and PowerShell versions (pwsh --version)
- Reproduction steps
- Full command and console output (redact your API key)