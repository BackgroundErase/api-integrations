# BackgroundErase TypeScript Client

Minimal Node script to remove image backgrounds using the BackgroundErase API. Upload a photo and save the returned PNG (with transparency) locally.

- API endpoint: https://api.backgrounderase.com/v2
- Get your API key: https://backgrounderase.com/account
- Plans/pricing: https://backgrounderase.com/pricing


Screenshot not included; result is a PNG with transparent background.

## Requirements

- Node.js 14+ (built-in https and fs modules; no npm deps)
- An API key from https://backgrounderase.com/account

## Install

Option A: Clone only the JavaScript folder
```bash
git clone --no-checkout https://github.com/BackgroundErase/api-integrations.git
cd api-integrations
git sparse-checkout init --cone
git sparse-checkout set JavaScript
git checkout main
cd JavaScript
```

Option B: Export just the JavaScript folder
```bash
svn export https://github.com/BackgroundErase/api-integrations/trunk/JavaScript
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
Replace YOUR_API_KEY with the key from https://backgrounderase.com/account.

Optional (recommended): Use an environment variable instead of hardcoding. Change the line to:
```js
const API_KEY = process.env.BG_ERASE_API_KEY || 'YOUR_API_KEY';
```
Then run with BG_ERASE_API_KEY set (see “Run” below).

2) Get a sample input image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/BackgroundErase/api-integrations/main/input.jpg
```

3) Run
```bash
# macOS/Linux (if using env var)
BG_ERASE_API_KEY=... node backgroundRemoval.js input.jpg output.png

# Windows PowerShell (if using env var)
$env:BG_ERASE_API_KEY="..."; node backgroundRemoval.js input.jpg output.png

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

- Sends a multipart/form-data POST to https://api.backgrounderase.com/v2
- Field name: image_file
- Header: x-api-key with your API key
- On success: response Content-Type is image/png (image/*). The script streams it to your output path.
- On error: response Content-Type is not image/*; the script reads and prints the error body.

Supported input types (common): jpg, jpeg, png, heic, webp. The script uses application/octet-stream for upload and lets the server detect format.

## Troubleshooting

- 401 Unauthorized / Invalid API key
  - Check your key at https://backgrounderase.com/account
  - Ensure the x-api-key header is set (and BG_ERASE_API_KEY if using env var)
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

- API: https://api.backgrounderase.com/v2
- Account (get key): https://backgrounderase.com/account
- Pricing: https://backgrounderase.com/pricing

## License

This example is provided as-is for integration purposes. Use within your project as needed.