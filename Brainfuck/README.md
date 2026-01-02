
# Brainfuck → BackgroundErase.NET via curl (systemf execve)

What this does
- Generates a Brainfuck program that calls Linux execve to run curl with multipart/form-data and your API key
- Uploads an input image to https://api.backgrounderase.net/v2
- Saves a transparent PNG to out/output.png

Folder layout
- assets/: sample input image(s)
- bf/: generated Brainfuck (bf/main.bf) and optional trigger.bf
- out/: output image(s)
- scripts/: tools
  - genbf.py: emits bf/main.bf that execve’s curl
  - send_with_bf.sh: simple wrapper that runs a BF file (optional) and then curl
- build.sh: builds systemf and generates bf/main.bf
- run.sh: convenience runner that calls scripts/send_with_bf.sh
- .env: stores your API key

Requirements (Ubuntu/WSL)
- sudo apt update
- sudo apt install -y build-essential nasm git curl python3 gdb binutils
- Optional: sudo apt install -y bf   # a classic BF interpreter (only used for a small demo step)

Note: This project uses the ajyoon/systemf interpreter (bundled in systemf/). It’s Linux-only. If you’re on macOS, you can still use scripts/send_with_bf.sh (curl-only path), but the systemf Brainfuck execve portion won’t run natively.

Get the code
Option A: Sparse-checkout just the Brainfuck folder
- git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
- cd ben-api-other-integrations
- git sparse-checkout init --cone
- git sparse-checkout set Brainfuck
- git checkout main
- cd Brainfuck

Option B: SVN export a single folder
- svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Brainfuck
- cd Brainfuck

Get an API key
- You need a plan: https://backgrounderase.net/pricing
- Generate/view your key: https://backgrounderase.net/account

Create .env
- echo 'API_KEY=YOUR_REAL_API_KEY_HERE' > .env

Get a sample input image
- mkdir -p assets
- curl -L -o assets/input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg

Build
- chmod +x build.sh run.sh scripts/genbf.py scripts/send_with_bf.sh
- bash ./build.sh
  - Builds systemf (systemf/bin/systemf)
  - Detects the BF tape base (TAPE_BASE) via gdb or nm if available
  - Emits bf/main.bf which, when run under systemf, execve’s /usr/bin/curl with:
    - -fsS -v -H "x-api-key: <API_KEY>" -F "image_file=@/abs/path" https://api.backgrounderase.net/v2 -o out/output.png

Run
Option A: Actually execute the Brainfuck program (systemf → execve → curl)
- ./systemf/bin/systemf bf/main.bf
- On success, output is saved to out/output.png

Option B: Simplest wrapper (uses curl directly; BF step optional)
- bash ./run.sh assets/input.jpg out/output.png
  - If the classic bf interpreter is installed, it will run bf/trigger.bf (no output, just a demo)
  - Then it calls curl with your API key and saves out/output.png

How it works (short)
- scripts/genbf.py:
  - Writes zero-terminated strings to the BF tape (curl path, args, API key header, API URL, output path)
  - Builds an argv[] table as 8-byte little-endian native pointers into the tape (needs the native tape base address)
  - Builds a minimal envp[] (just NULL)
  - Lays out a systemf syscall frame at tape cell 0 for execve("/usr/bin/curl", argv, envp) and invokes % (systemf syscall)
- systemf’s non-PIE default build makes the tape symbol address stable, so TAPE_BASE detection is typically consistent

Troubleshooting
- Could not determine TAPE_BASE
  - The generator tries:
    - TAPE_BASE env var
    - gdb -q ./systemf/bin/systemf -ex 'p &tape' -ex 'quit'
    - nm -an ./systemf/bin/systemf | grep ' tape$'
  - If auto-detection fails, set it manually and rebuild:
    - export TAPE_BASE=0xYOUR_VALUE
    - bash ./build.sh
- /usr/bin/curl not found
  - Install curl (sudo apt install -y curl) or adjust genbf.py to point to your curl path
- API errors (HTTP 401/403/4xx)
  - Ensure .env has a valid API_KEY
  - Confirm plan status: https://backgrounderase.net/pricing
- Output file missing
  - Check network
  - Check write permissions for out/
  - Re-run with -v for curl in logs (genbf.py already includes -v)
- systemf missing or fails to build
  - Ensure you ran build.sh
  - If the systemf folder is not present, initialize submodules or re-clone the repo

Environment notes
- scripts/send_with_bf.sh reads API_KEY from:
  - $API_KEY (if exported), or
  - .env (API_KEY=...)
- build.sh sources .env to pass API_KEY to genbf.py

Security
- Treat .env and any logs with care (they can contain your API key)
- Prefer environment variables in CI over committing secrets

License/credits
- systemf by ajyoon (https://github.com/ajyoon/systemf)
- BackgroundErase.NET API docs: https://api.backgrounderase.net/v2

That’s it! After a successful run, open out/output.png to see your transparent PNG result.