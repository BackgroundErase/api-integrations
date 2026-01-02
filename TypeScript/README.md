# BackgroundErase.NET TypeScript example (background removal)

Minimal TypeScript example that uploads an image to BackgroundErase.NET and saves the cutout (PNG with transparency) to disk.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

The example uses only Node’s built‑in modules (https, fs, path). No third‑party dependencies.

## Files

- backgroundRemoval.ts — multipart uploader (field name image_file) that streams the response to a file. Can be used as:
  - a small CLI: npx ts-node backgroundRemoval.ts input.jpg output.png
  - a function you import in your own TS/Node app

## Requirements

- Node.js 18+ (recommended)
- TypeScript/ts-node if you want to run .ts directly
  - npx ts-node works without installing locally
  - Or compile with tsc and run with node

## 1) Get an API key

- Sign in: https://backgrounderase.net/account
- If needed, purchase/upgrade: https://backgrounderase.net/pricing
- You’ll use the key in the x-api-key header

## 2) Get the code

Option A: Git sparse checkout
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set TypeScript
git checkout main
cd TypeScript
```

Option B: SVN export (no git history)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/TypeScript
cd TypeScript
```

Optional: Grab a sample input image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

## 3) Configure your API key

Open backgroundRemoval.ts and set:
```ts
const API_KEY = "YOUR_API_KEY_HERE";
```

Tip (optional): You can load from an environment variable instead:
```ts
const API_KEY = process.env.BEN2_API_KEY || "YOUR_API_KEY_HERE";
```
Then run with:
```bash
BEN2_API_KEY=sk_live_xxx npx ts-node backgroundRemoval.ts input.jpg output.png
```

Never commit real API keys to source control.

## 4) Run as a CLI

Using ts-node (no local install required):
```bash
npx ts-node backgroundRemoval.ts input.jpg output.png
```

- input.jpg: source image (jpg/png/heic/webp, etc.)
- output.png: destination file path; result is a PNG with transparency

On success you’ll see:
```
✅ File saved: output.png
✅ Done: output.png
```

## 5) Use programmatically in your project

Install TypeScript (if you don’t already use it):
```bash
npm init -y
npm i -D typescript ts-node
```

Example usage from another TypeScript file:
```ts
import backgroundRemoval from "./backgroundRemoval";

async function main() {
  try {
    const out = await backgroundRemoval("input.jpg", "cutout.png");
    console.log("Saved to", out);
  } catch (err) {
    console.error("Background removal failed:", err);
  }
}

main();
```

Run:
```bash
npx ts-node app.ts
```

## 6) Build to JavaScript (optional)

If you prefer compiling to JS instead of ts-node:

- Initialize a tsconfig (minimal example):
```bash
npx tsc --init --rootDir . --outDir dist --module commonjs --target ES2020
```

- Compile:
```bash
npx tsc
```

- Run the compiled file:
```bash
node dist/backgroundRemoval.js input.jpg output.png
```

## How it works (quick notes)

- Sends a multipart/form-data POST to https://api.backgrounderase.net/v2 with field name image_file
- Sets x-api-key header with your key
- Streams the response to the destination path
- If the response Content-Type isn’t image/*, it captures the error body and rejects

## Troubleshooting

- 401/403 or “❌ Error: …”
  - Check API key validity and plan status
  - Ensure x-api-key was set (see API_KEY)
- ENOENT: no such file or directory
  - Verify the input path exists and the output directory is writable
- EACCES or EPERM on Windows/macOS/Linux
  - Choose an output path where your user has write permission
- Non-image response
  - The script prints the server’s error message; verify request field name is image_file and filename is set

## Security and best practices

- Keep your API key secret; don’t hardcode in public repos
- Prefer environment variables or a secure secrets manager in production

## License and contributions

Issues and pull requests are welcome. If you report a problem, include:
- Node.js version and OS
- Exact command you ran
- Logs/error output
- A small sample image if relevant
