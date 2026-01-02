# BackgroundErase.NET Objective-C CLI

A minimal Objective-C example that uploads an image to BackgroundErase.NET and saves the cutout (PNG with transparency) to disk.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans/upgrade: https://backgrounderase.net/pricing

This repo/folder contains a single file:
- BENObjectiveC.m — small CLI that:
  - Reads an input image from disk
  - POSTs it as multipart/form-data under field name image_file
  - Writes the API’s PNG response to the output path

Note: The API responds with raw PNG bytes (no JSON on success).

## Requirements

- macOS with Apple Clang and Foundation framework (Xcode or Command Line Tools)
- Internet access
- An API key from BackgroundErase.NET

Tip: This example is intended as a tiny, self-contained CLI. If you integrate into an app, run the network call off the main thread and avoid synchronous waits on UI threads.

## Get an API key

- Sign in: https://backgrounderase.net/account
- If needed, purchase/upgrade a plan: https://backgrounderase.net/pricing
- Copy your API key (x-api-key)

## Install just the Objective-C example

Option A: Git (sparse checkout)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Objective-C
git checkout main   # or the default branch
cd Objective-C
```

Option B: SVN export
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Objective-C
cd Objective-C
```

Get a sample input image
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

## Build

Compile with Apple Clang on macOS:
```bash
clang -fobjc-arc -framework Foundation BENObjectiveC.m -o ben
```

If you prefer, you can open Xcode and create a macOS Command Line Tool target (Objective-C), then add BENObjectiveC.m to the target and build/run from there.

## Run

Usage:
```text
./ben <input_image_path> <output_png_path> <YOUR_API_KEY>
```

Example:
```bash
./ben ./input.jpg ./output.png YOUR_API_KEY
```

Expected output:
```text
✅ Saved: ./output.png
```

The output is a PNG with transparency.

## How it works (short)

- Determines MIME type based on the input file extension (png, jpg/jpeg, webp, gif, bmp, tif/tiff, heic; otherwise application/octet-stream)
- Builds a multipart/form-data POST to https://api.backgrounderase.net/v2
  - Header: x-api-key: YOUR_API_KEY
  - Field: image_file (file content)
- On HTTP 200, writes the raw PNG bytes to the output path
- Prints status and simple error messages to the console

## Programmatic use in your app

- The example’s core logic is the static function background_removal(NSString *src, NSString *dst, NSString *apiKey).
- For an app:
  - Move that function into a shared source file in your app target.
  - Avoid blocking the main thread. Use NSURLSession’s async completion handler (already present) and remove the semaphore, or dispatch background work to a queue.
  - Keep your API key out of source control (Keychain, config files, CI secrets, etc.).

Minimal example (inside your own controller/object):
```objective-c
// Pseudocode: call your adapted upload function asynchronously and update UI on main thread
dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    // call background_removal(...) or your refactored async wrapper
});
```

## Notes and tips

- Security: Treat your API key like a password. Do not hardcode into public repos.
- App Transport Security (ATS): The API uses HTTPS; no special ATS exceptions are needed.
- Input filenames matter: The extension helps set the correct Content-Type. If unknown, it falls back to application/octet-stream.
- Output always PNG: The result is a PNG with transparency.
- Threading: The CLI uses a semaphore to behave synchronously. For UI apps, use asynchronous patterns.

## Troubleshooting

- Build errors involving string quotes in Content-Disposition:
  - Ensure the BENObjectiveC.m has escaped quotes, e.g. name=\"image_file\"; filename=\"%@\"
- If you see a non-200 status:
  - Verify the API key is correct and active (account/pricing)
  - Check that the input path exists and is readable
  - Print the response body (already logged) for error details
- If output isn’t created:
  - Confirm write permissions for the target directory
  - Ensure the disk has available space
  - Try another output path (e.g., ./output.png)

## API details (for reference)

- Method: POST
- URL: https://api.backgrounderase.net/v2
- Headers:
  - x-api-key: YOUR_API_KEY
  - Content-Type: multipart/form-data; boundary=...
- Body:
  - form field image_file with the binary image payload
- Success (HTTP 200): raw PNG bytes in response body
- Error: Non-200 with a text or JSON body describing the issue

## License and contributions

- Example code is provided as-is for demonstration purposes.
- Issues and PRs welcome. When filing an issue, include:
  - macOS version, Xcode/Clang version
  - Exact commands you ran and full console output
  - A sample image if relevant