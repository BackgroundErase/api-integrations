# BackgroundErase.NET Assembly CLI (macOS arm64 + Linux x86_64)

Minimal assembly examples that call the BackgroundErase.NET v2 API via curl to remove image backgrounds. Works on:
- macOS Apple Silicon (arm64) via clang/Apple assembler
- Linux x86_64 via NASM + GCC

API: https://api.backgrounderase.net/v2  
Get your API key: https://backgrounderase.net/account  
Plans: https://backgrounderase.net/pricing

## What it does

- Reads API key from BG_ERASE_API_KEY (or falls back to a compiled-in default)
- Uploads a local file as multipart form field image_file
- Writes the returned PNG (with transparency) to the output path you provide

macOS uses absolute /usr/bin/curl; Linux searches curl in PATH.

## Get the code (Assembly folder only)

Option A: Git sparse checkout
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Assembly
git checkout main   # or replace with repo’s default branch if different
cd Assembly
```

Option B: SVN export (no git needed)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Assembly
cd Assembly
```

Optional: Sample input image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

## Build

macOS (Apple Silicon, arm64)
- Requirements: Xcode Command Line Tools (clang), curl at /usr/bin/curl
```bash
clang -c background_removal_arm64.S -o background_removal_arm64.o
clang background_removal_arm64.o -o background_removal
```

Linux (x86_64)
- Requirements: nasm, gcc, curl
```bash
nasm -f elf64 background_removal.asm -o background_removal.o
gcc -no-pie background_removal.o -o background_removal
```
Note: -no-pie is required on many distros for this hand-written assembly.

## Usage

Syntax:
```bash
BG_ERASE_API_KEY=YOUR_API_KEY ./background_removal <input_image> <output_png>
```

Examples:
- macOS:
```bash
BG_ERASE_API_KEY=YOUR_API_KEY ./background_removal ./input.jpg ./output.png
```

- Linux:
```bash
BG_ERASE_API_KEY=YOUR_API_KEY ./background_removal ./input.jpg ./output.png
```

Results:
- output.png is a PNG with transparency (background removed)

## Configuration

- API key
  - Preferred: set BG_ERASE_API_KEY in your environment.
  - Fallback: both sources include a DEFAULT_API_KEY constant ("YOUR_API_KEY"). You can edit it to hardcode a key, but environment variables are recommended.

- Endpoint and fields
  - URL: https://api.backgrounderase.net/v2
  - Header: x-api-key: <your_key>
  - Multipart form field: image_file=@<path>

## Notes and differences

- macOS (background_removal_arm64.S)
  - Validates the input image is readable (access R_OK)
  - Uses absolute path /usr/bin/curl
  - Prints simple debug lines showing the header and form strings

- Linux (background_removal.asm)
  - Skips the access check; ensure the source file is readable
  - Uses execvp("curl", ...) to search PATH
  - Also prints a simple usage or error via perror on failure

## Troubleshooting

- “Usage: background_removal <src> <dst>”
  - Provide both input and output paths.

- “execvp failed”
  - curl not found. Install curl or adjust PATH (Linux), or ensure /usr/bin/curl exists (macOS).

- HTTP 401/403 or empty output
  - Invalid or missing API key.
  - Ensure your plan is active: https://backgrounderase.net/pricing
  - Verify BG_ERASE_API_KEY is set in the same shell session.

- Permission errors writing the output
  - Ensure the destination directory is writable.

- Linux link/load errors
  - Rebuild with -no-pie as shown above.

- Running on Intel macOS
  - The provided macOS assembly targets arm64. Use an Apple Silicon Mac to run it, or build/run the Linux variant on a Linux machine/WSL.

## File overview

- background_removal_arm64.S (macOS arm64, clang/Apple assembler)
- background_removal.asm (Linux x86_64, NASM)

Each builds a small process that constructs the required header and multipart form string, then execs curl with:
- -sSf
- -H "x-api-key: ..."
- -F "image_file=@<src>"
- <URL>
- -o <dst>

Issues and PRs welcome. Please include OS/distro, toolchain versions, and exact build/run commands.