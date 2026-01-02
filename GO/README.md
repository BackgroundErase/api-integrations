# BEN2 Go API Client (CLI Example)

A minimal Go client for BackgroundErase.NET. Upload an image, remove the background via the API, and save the result as a PNG with transparency.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

## Quick start

1) Get an API key
- Sign in or create an account: https://backgrounderase.net/account
- Ensure you have an active (business) plan: https://backgrounderase.net/pricing

2) Fetch this example
Option A: Git (sparse checkout)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set GO
git checkout main   # or the repo's default branch if different
cd GO
```

Option B: SVN export
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/GO
cd GO
```

3) Get a sample image (optional)
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

4) Run the CLI
Option A: pass the key directly
```bash
go run main.go -in ./input.jpg -out ./output.png -key YOUR_API_KEY
```

Option B: use an environment variable
```bash
# macOS/Linux
export BACKGROUND_ERASE_API_KEY=YOUR_API_KEY
go run main.go -in ./input.jpg -out ./output.png
```

Windows (PowerShell):
```powershell
$env:BACKGROUND_ERASE_API_KEY="YOUR_API_KEY"
go run main.go -in .\input.jpg -out .\output.png
```

Windows (cmd.exe):
```bat
set BACKGROUND_ERASE_API_KEY=YOUR_API_KEY
go run main.go -in .\input.jpg -out .\output.png
```

If successful, you’ll see:
```
✅ Saved: ./output.png
```

## Build a binary

```bash
go build -o background-erase
./background-erase -in ./input.jpg -out ./output.png -key YOUR_API_KEY
```

Windows:
```powershell
go build -o background-erase.exe
.\background-erase.exe -in .\input.jpg -out .\output.png -key YOUR_API_KEY
```

## Requirements

- Go 1.18+ (standard library only)
- macOS, Linux, or Windows
- Internet access to reach https://api.backgrounderase.net

## What this example does

- Sends a multipart/form-data POST to https://api.backgrounderase.net/v2
- Uploads the image under field name image_file
- Sets header x-api-key: YOUR_API_KEY
- Infers Content-Type from the file extension (falls back to application/octet-stream if unknown)
- Uses a 60s HTTP client timeout
- On success (HTTP 200), writes raw PNG bytes (with transparency) to the output path

Excerpt from main.go:
```go
req, err := http.NewRequest("POST", "https://api.backgrounderase.net/v2", &body)
...
req.Header.Set("Content-Type", writer.FormDataContentType())
req.Header.Set("x-api-key", apiKey)
client := &http.Client{Timeout: 60 * time.Second}
resp, err := client.Do(req)
...
// On 200 OK: write PNG bytes to dst
```

## Use in your own Go code

You can copy the backgroundRemoval function from main.go into your project and call it:

```go
err := backgroundRemoval("path/to/input.jpg", "path/to/output.png", "YOUR_API_KEY")
if err != nil {
    // handle error
}
```

Notes:
- The filename’s extension informs MIME detection: jpg, jpeg, png, heic, webp, etc.
- If the extension is unknown, it sends application/octet-stream.
- The API responds with PNG bytes (transparent background).

## Supported input formats

- Common image types such as JPG/JPEG, PNG, HEIC, WEBP
- Ensure the filename has the correct extension so the MIME type is inferred properly

Output format:
- PNG with transparency

## Troubleshooting

- 401 Unauthorized
  - Check your API key and plan status
  - Ensure you’re passing -key or BACKGROUND_ERASE_API_KEY

- 415 Unsupported Media Type
  - Ensure the file extension matches the actual image type
  - If in doubt, try .jpg or .png

- 413 Payload Too Large
  - Image may exceed size limits; try a smaller image

- 429 Too Many Requests / Out of credits
  - Slow down or upgrade your plan

- 5xx Server Error
  - Temporary issue; retry after a short delay

- Network/Timeouts
  - The client uses a 60s timeout; increase if you have very slow connections

## Security tips

- Do not commit your API key to source control
- Prefer environment variables for local development
- Rotate/regenerate keys from https://backgrounderase.net/account if needed

## License and contributions

This folder is a minimal example. Issues and PRs are welcome in the main repo.