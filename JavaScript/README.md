# BackgroundErase.NET JavaScript Client (Node.js)

Minimal Node.js script to remove image backgrounds using the BackgroundErase.NET API. Upload a photo and save the returned PNG (with transparency) locally.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

Files in this folder:
- backgroundRemoval.js

Screenshot not included; result is a PNG with transparent background.

## Requirements

- Node.js 14+ (built-in https and fs modules; no npm deps)
- An API key from https://backgrounderase.net/account

## Install

Option A: Clone only the JavaScript folder
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set JavaScript
git checkout main   # use the repo's default branch if different
cd JavaScript
```

Option B: Export just the JavaScript folder
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/JavaScript
cd JavaScript
```

Option C: Copy the single file
- Create a folder, save backgroundRemoval.js into it.

## Quick start

1) Add your API key  
Open backgroundRemoval.js and set:
```js
const API_KEY = 'YOUR_API_KEY';
```
Replace YOUR_API_KEY with the key from https://backgrounderase.net/account.

Optional (recommended): Use an environment variable instead of hardcoding. Change the line to:
```js
const API_KEY = process.env.BEN2_API_KEY || 'YOUR_API_KEY';
```
Then run with BEN2_API_KEY set (see “Run” below).

2) Get a sample input image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

3) Run
```bash
# macOS/Linux (if using env var)
BEN2_API_KEY=sk_live_xxx node backgroundRemoval.js input.jpg output.png

# Windows PowerShell (if using env var)
$env:BEN2_API_KEY="sk_live_xxx"; node backgroundRemoval.js input.jpg output.png

# If you hardcoded the key, just run:
node backgroundRemoval.js input.jpg output.png
```

Notes:
- The API returns PNG bytes with transparency. Use a .png extension for the output file to preserve alpha.
- If you see “File saved: output.png” and “Background removed successfully!”, you’re done.

## Usage (CLI)

Basic:
```bash
node backgroundRemoval.js <inputPath> <outputPath>
```
Examples:
- JPG to PNG: node backgroundRemoval.js input.jpg cutout.png
- PNG to PNG: node backgroundRemoval.js product.png product_cutout.png

Exit codes:
- 0 on success
- 1 (or error) on failure, error text is printed to stderr

## Programmatic usage (optional)

If you want to call the function from another Node script, export it:

1) At the bottom of backgroundRemoval.js, add:
```js
module.exports = backgroundRemoval;
```

2) In your app:
```js
// app.js
const backgroundRemoval = require('./backgroundRemoval'); // adjust path if needed

(async () => {
  try {
    await backgroundRemoval('input.jpg', 'output.png');
    console.log('Done!');
  } catch (err) {
    console.error('Failed:', err.message);
  }
})();
```

Run:
```bash
node app.js
```

## How it works

- Sends a multipart/form-data POST to https://api.backgrounderase.net/v2
- Field name: image_file
- Header: x-api-key with your API key
- On success: response Content-Type is image/png (image/*). The script streams it to your output path.
- On error: response Content-Type is not image/*; the script reads and prints the error body.

Supported input types (common): jpg, jpeg, png, heic, webp. The script uses application/octet-stream for upload and lets the server detect format.

## Troubleshooting

- 401 Unauthorized / Invalid API key
  - Check your key at https://backgrounderase.net/account
  - Ensure the x-api-key header is set (and BEN2_API_KEY if using env var)
- 400/415 Unsupported image or bad request
  - Try with a standard JPG/PNG
  - Ensure you sent the image under field name image_file
- 413 Payload too large
  - Use a smaller image or upgrade plan limits
- 429 Rate limit
  - Wait and retry or upgrade your plan
- Network/SSL errors
  - Check firewall/proxy, retry later
- Output is not PNG
  - The API returns PNG; ensure your output path ends with .png for best compatibility

To inspect full error responses, you can temporarily log the error body in backgroundRemoval.js where it rejects on non-image responses.

## Security

- Do not commit your API key to source control.
- Prefer using environment variables for secrets in production.

## Reference

- API: https://api.backgrounderase.net/v2
- Account (get key): https://backgrounderase.net/account
- Pricing: https://backgrounderase.net/pricing

## License

This example is provided as-is for integration purposes. Use within your project as needed.