# BEN2 Java API Client (single-file example)

A minimal Java 11+ client for BackgroundErase.NET. Upload an image, get back a PNG with transparency (background removed), and save it to disk.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Buy/upgrade a plan: https://backgrounderase.net/pricing

## Quick start

1) Get an API key
- Sign in: https://backgrounderase.net/account
- If needed, purchase a plan: https://backgrounderase.net/pricing

2) Get the Java example
Option A: Git (sparse checkout)
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Java
git checkout main   # or replace 'main' with the repo's default branch if different
cd Java
```

Option B: SVN (export just the folder)
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Java
cd Java
```

3) Get a sample image (or use your own)
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

4) Add your API key
Open BenBackgroundRemoval.java and replace:
```java
private static final String API_KEY = "YOUR_API_KEY";
```
with your actual key.

Tip (optional): If you prefer environment variables, change it to:
```java
private static final String API_KEY =
    System.getenv().getOrDefault("BEN2_API_KEY", "YOUR_API_KEY");
```
Then export the key:
- macOS/Linux:
  ```bash
  export BEN2_API_KEY="sk_live_..."
  ```
- Windows (PowerShell):
  ```powershell
  setx BEN2_API_KEY "sk_live_..."
  ```

5) Build and run
Requires Java 11+ (uses java.net.http.HttpClient).
```bash
javac BenBackgroundRemoval.java
java BenBackgroundRemoval
```

- By default it reads input.jpg and writes output.png to the current directory.
- On success you’ll see: “Saved: …/output.png”
- On failure you’ll see the HTTP status and error body.

## What the example does

- Sends a multipart/form-data POST request to https://api.backgrounderase.net/v2
- Field name: image_file
- Headers:
  - x-api-key: your key
  - Content-Type: multipart/form-data; boundary=...
- Body: your image bytes (jpg, jpeg, png, heic, webp, others fallback to application/octet-stream)
- Response: raw PNG bytes (background removed, with transparency). The example writes them directly to output.png.

## Usage from your own Java code

- Copy BenBackgroundRemoval.java into your project.
- Call:
```java
Path src = Path.of("path/to/your/input.jpg");
Path dst = Path.of("path/to/save/output.png");
BenBackgroundRemoval.backgroundRemoval(src, dst);
```

Notes:
- backgroundRemoval throws Exception on network or I/O errors; wrap in try/catch in production.
- Timeout defaults in the example: connect 20s, request 120s. Adjust as needed.

## Requirements

- Java 11 or newer (java.net.http.HttpClient)
- Internet access
- A valid API key

## Common issues

- 401 Unauthorized
  - Wrong or missing API key. Ensure x-api-key is set correctly.
- 413 Payload Too Large
  - Image is too large for your plan. Try a smaller file or upgrade your plan.
- 415 Unsupported Media Type
  - Double-check the multipart field name is image_file and content type is correct. The example auto-detects MIME type and falls back to application/octet-stream.
- Timeouts
  - Slow networks can time out. Increase the request timeout in HttpRequest.newBuilder().timeout(...).

## Customization tips

- Input formats: jpg, jpeg, png, heic, webp generally work well. Others are sent as application/octet-stream.
- Output: Always PNG with transparency. You can rename the output file or save bytes to memory instead of disk.
- Retries: For production, consider wrapping the request with basic retries for transient network failures.
- Logging: Capture resp.statusCode() and the response body on errors for easier debugging.

## Security

- Don’t commit your API key to source control.
- Prefer environment variables or a secure configuration store for secrets.

## File reference

- BenBackgroundRemoval.java
  - main: demo entry point (reads input.jpg, writes output.png)
  - backgroundRemoval(Path src, Path dst): uploads src and saves the PNG response to dst
  - buildMultipartBody(...): constructs the multipart/form-data body for the image under field name image_file

Issues and pull requests are welcome. Please include:
- Java version and vendor (e.g., Temurin 17)
- OS
- Reproduction steps, logs, and example images if possible.