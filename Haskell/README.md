```markdown
# BEN2 Haskell API Client (CLI)

Minimal Haskell CLI that uploads an image to BackgroundErase.NET API v2 and saves the returned PNG (with transparency) to disk.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

Executable name: `ben`

## Quick start

1) Get an API key  
- Create an account or sign in: https://backgrounderase.net/account  
- You need a business subscription: https://backgrounderase.net/pricing

2) Get this Haskell example (choose one)

Git (sparse checkout):
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Haskell
git checkout main   # or the repo's default branch if different
cd Haskell
```

SVN export:
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Haskell
cd Haskell
```

3) Install toolchain (via GHCup)
- Recommended: latest GHC and cabal-install
```bash
# macOS/Linux
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Verify
ghc --version
cabal --version
```

Note: This project’s .cabal file uses `cabal-version: 3.12`. Make sure your `cabal-install` is recent enough (install/update via GHCup).

4) Build and run
```bash
# Fetch package index
cabal update

# Build
cabal build

# (Optional) Try a sample image
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg

# Run: ben <API_KEY> <input-image> <output.png>
cabal run ben -- YOUR_API_KEY_HERE input.jpg output.png
```

If successful, you’ll see a “Saved: output.png” message, and `output.png` will contain a transparent-background cutout.

## Usage

- Syntax:
```bash
ben <API_KEY> <input-image> <output.png>
```

- With cabal (recommended during development):
```bash
cabal run ben -- <API_KEY> <input-image> <output.png>
```

- After building, you can also run the compiled executable directly (path varies by platform and GHC version), for example:
```bash
./dist-newstyle/build/*/*/Haskell-0.1.0.0/x/ben/build/ben/ben <API_KEY> input.jpg output.png
```

Notes:
- Input can be jpg, jpeg, png, heic, webp, etc.
- Output will be PNG with transparency.
- The API key is passed via the `x-api-key` header.

## What this client does

- POSTs to: `https://api.backgrounderase.net/v2`
- Authentication: header `x-api-key: YOUR_API_KEY`
- Request body: multipart form with a single field `image_file` containing your input image
- Response:
  - HTTP 200: raw PNG bytes (transparent background cutout)
  - Non-200: prints status code and response body to help diagnose

## Project structure

```
Haskell/
├─ app/
│  └─ Main.hs          # CLI entry and request logic
└─ Haskell.cabal       # Cabal package definition
```

Main.hs (high level):
- Builds a TLS-enabled HTTP manager
- Forms a multipart request with your image file under field name `image_file`
- Adds `x-api-key` header
- Writes the response body to your specified output path if status is 200

## Requirements

- cabal-install 3.12+ (use GHCup to install/update)
- GHC (recent version; 9.x recommended)
- Internet access to reach `https://api.backgrounderase.net/v2`

Dependencies (handled by cabal):
- base
- bytestring
- http-types
- http-client
- http-client-tls
- http-client-multipart

## Examples

- Basic:
```bash
cabal run ben -- sk_live_123... input.jpg cutout.png
```

- Different formats (input can be JPEG/PNG/HEIC/WEBP; output always PNG):
```bash
cabal run ben -- sk_live_123... photo.heic result.png
```

- Windows PowerShell:
```powershell
cabal run ben -- "sk_live_123..." "C:\path\to\input.jpg" "C:\path\to\output.png"
```

## Troubleshooting

- cabal says unknown field or parse error with `cabal-version`:
  - Ensure `cabal-install` is up to date (3.12+). Install/update via GHCup, then try `cabal update` and build again.

- 401 Unauthorized:
  - Double-check your API key (copy/paste correctness, no extra spaces).
  - Ensure your plan allows API usage: https://backgrounderase.net/pricing

- 400/415/422 errors:
  - The input might be unreadable or unsupported. Try a common format like JPEG or PNG.
  - Make sure you passed the image under the `image_file` field (this client already does that).

- TLS or network errors:
  - Check firewall/proxy settings.
  - If behind a corporate proxy, set `HTTPS_PROXY`/`https_proxy` environment variable.

- Output file not created:
  - The API must return 200 for the client to write the file. Check the printed status code and body for details.

## Modifying or extending

- Change output behavior (e.g., different filename rules) inside `app/Main.hs` in `backgroundRemoval`.
- Add timeouts:
  - You can set `responseTimeout` in the `Request` (e.g., `responseTimeout = responseTimeoutMicro 60000000` for 60s).
- Add proxy support:
  - Configure the `Manager` with proxy settings or rely on environment variables if your environment/tooling supports it.

## Security

- Avoid hardcoding your API key in source control.
- Pass the key as a CLI argument (as in this example) or implement your own environment-variable read before calling `backgroundRemoval`.

## License

- The `Haskell.cabal` declares `license: NONE`. No license file is provided.

## Support

- API key/account/billing: https://backgrounderase.net/account
- Plans: https://backgrounderase.net/pricing
- Issues with this example: please include your OS, cabal/GHC versions, the command you ran, and the printed status/error output.
```