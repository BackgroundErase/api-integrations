# BEN2 Erlang API Client + CLI

Minimal Erlang client and CLI to call BackgroundErase.NET and save the cutout as a PNG with transparency.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

Files in this folder:
- ben_bg.erl — Erlang module that uploads an image (multipart) and writes the PNG response
- ben_bg_cli.escript — Escript wrapper so you can run it like a command

Requirements:
- Erlang/OTP with inets, ssl, crypto apps (OTP 22+ recommended)
- Internet access with TLS (HTTPS)

Install (only the Erlang folder)
Option A: Git (sparse checkout)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Erlang
git checkout main   # or the repo's default branch
cd Erlang
```

Option B: Subversion (export just this folder)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Erlang
cd Erlang
```

Build
1) Compile the Erlang module
```bash
erlc ben_bg.erl
```
This creates ben_bg.beam in the current directory.

2) Make the CLI executable (optional; for command-like usage)
```bash
chmod +x ben_bg_cli.escript
```

Quick start
1) Get an API key
- Create an account or sign in: https://backgrounderase.net/account
- If needed, purchase/upgrade: https://backgrounderase.net/pricing

2) Download a sample image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

3) Run it (choose one)

A) Erlang shell
```bash
erl
1> ben_bg:background_removal("input.jpg", "output.png", "YOUR_API_KEY").
%% expect: "✅ Saved: output.png"
2> q().    % quit
```

B) Non-interactive one-liner (good for scripts/CI)
```bash
erl -noshell -eval 'ben_bg:background_removal("input.jpg","output.png","YOUR_API_KEY"), halt().'
```

C) Escript CLI (like a normal command)
```bash
./ben_bg_cli.escript input.jpg output.png YOUR_API_KEY
# or after copying/renaming:
# cp ben_bg_cli.escript ben_bg && chmod +x ben_bg
# ./ben_bg input.jpg output.png YOUR_API_KEY
```

Tip: Keep your key out of history
```bash
export BEN2_API_KEY="YOUR_API_KEY"
./ben_bg_cli.escript input.jpg output.png "$BEN2_API_KEY"
```
Windows (PowerShell):
```powershell
$env:BEN2_API_KEY="YOUR_API_KEY"
.\ben_bg_cli.escript input.jpg output.png $env:BEN2_API_KEY
```

What it does
- Sends a multipart/form-data POST to https://api.backgrounderase.net/v2
- Field name: image_file
- Auth header: x-api-key: YOUR_API_KEY
- Response: raw PNG bytes (transparent background)
- Saves to the output file you specify

Supported input types (MIME detection by file extension)
- .jpg, .jpeg → image/jpeg
- .png → image/png
- .webp → image/webp
- .bmp → image/bmp
- .gif → image/gif
- other extensions → application/octet-stream (still may work if the server detects it)

File overview
- ben_bg.erl
  - background_removal(SrcPath, DstPath, ApiKey) -> ok | {error, Reason}
  - Starts crypto, ssl, inets
  - Builds a random boundary and multipart body
  - Writes the PNG response to DstPath on success
  - Prints:
    - Success: "✅ Saved: output.png"
    - Errors with status or request details
- ben_bg_cli.escript
  - Usage: ./ben_bg_cli.escript input.jpg output.png YOUR_API_KEY
  - Loads ben_bg.beam from the current directory and calls background_removal/3
  - Exits with code 0 on success, 1 on failure

Examples

- Process many files (bash)
```bash
export BEN2_API_KEY="YOUR_API_KEY"
for f in *.jpg *.jpeg *.png 2>/dev/null; do
  [ -e "$f" ] || continue
  out="${f%.*}.cutout.png"
  ./ben_bg_cli.escript "$f" "$out" "$BEN2_API_KEY" || echo "Failed: $f"
done
```

- From Erlang shell with variables
```erlang
Api = "YOUR_API_KEY",
Src = "input.jpg",
Dst = "output.png",
ben_bg:background_removal(Src, Dst, Api).
```

Troubleshooting
- Could not load ben_bg.beam. Compile first with: erlc ben_bg.erl
  - Run: erlc ben_bg.erl in the Erlang folder
- 401 Unauthorized
  - Check your API key, plan status, and header spelling (x-api-key)
- 415/400 errors
  - Make sure the file exists and extension matches its format
  - The field name must be image_file (already correct in this client)
- TLS/SSL errors
  - Ensure ssl app is available (OTP includes it)
  - Your OS should have system CA certs; updating Erlang/OTP can help
- escript “Permission denied”
  - chmod +x ben_bg_cli.escript (or run via erl -noshell …)

Notes
- This client does not resize or recompress your input; it uploads as-is.
- Output is always PNG bytes with transparency.
- Default httpc settings are used; you can adjust options by editing ben_bg.erl if needed (timeouts, proxies, etc.).

Issues and contributions
- Please include:
  - Erlang/OTP version and OS
  - Exact command used and full console output
  - Sample input (if possible) or steps to reproduce