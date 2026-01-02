# BackgroundErase.NET Scala Client (single-file, scala-cli)

Minimal Scala 3 example that uploads an image to BackgroundErase.NET v2 and saves the cutout (PNG with transparency). Uses Java 11+ HttpClient and a hand-built multipart/form-data body.

- API: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans: https://backgrounderase.net/pricing

## What this is

- A single source file: BackgroundRemoval.scala
- Sends multipart form data with field name image_file
- Writes the API’s raw PNG response to the path you specify

## Requirements

- Java 11+ JDK on your PATH (java -version should show 11 or newer)
- scala-cli (https://scala-cli.virtuslab.org/install)
- A BackgroundErase.NET API key (paid plan)

## Get the code

Option A: Sparse-checkout this folder from the repo
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set Scala
git checkout main   # or the repo’s default branch if different
cd Scala
```

Option B: Export just this directory with Subversion
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/Scala
cd Scala
```

Option C: Copy the single file
- Copy Scala/BackgroundRemoval.scala into any folder.

## Quick start

1) Get an API key  
- Sign in or create an account: https://backgrounderase.net/account  
- If needed, purchase/upgrade a plan: https://backgrounderase.net/pricing

2) Install prerequisites  
- Install a JDK 11+  
- Install scala-cli

3) Grab a sample image (optional)
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

4) Run it (choose one)

- Pass the key via flag:
```bash
scala-cli run BackgroundRemoval.scala -- input.jpg output.png --api-key YOUR_API_KEY
```

- Or use an environment variable:
  - macOS/Linux:
    ```bash
    export BG_ERASE_API_KEY=YOUR_API_KEY
    scala-cli run BackgroundRemoval.scala -- input.jpg output.png
    ```
  - Windows PowerShell:
    ```powershell
    $env:BG_ERASE_API_KEY="YOUR_API_KEY"
    scala-cli run .\BackgroundRemoval.scala -- .\input.jpg .\output.png
    ```
  - Windows CMD:
    ```cmd
    set BG_ERASE_API_KEY=YOUR_API_KEY
    scala-cli run BackgroundRemoval.scala -- input.jpg output.png
    ```

If successful, you’ll see:
```
✅ Saved: output.png
```

## Usage

Command syntax
- scala-cli run BackgroundRemoval.scala -- <src> <dst> [--api-key YOUR_API_KEY]

Notes
- <src> is a local image path (jpg, jpeg, png, heic, webp, …)
- <dst> is where the PNG cutout will be written; directories must already exist
- If both --api-key and BG_ERASE_API_KEY are absent, the program exits with an error
- The API always returns PNG bytes; using a .png extension for <dst> is recommended

Examples
```bash
# JPG to PNG cutout
scala-cli run BackgroundRemoval.scala -- photo.jpg cutout.png --api-key YOUR_API_KEY

# Using env var, HEIC input
export BG_ERASE_API_KEY=YOUR_API_KEY
scala-cli run BackgroundRemoval.scala -- portrait.heic portrait_cutout.png

# Windows PowerShell
$env:BG_ERASE_API_KEY="YOUR_API_KEY"
scala-cli run .\BackgroundRemoval.scala -- .\input.jpg .\output.png
```

## How it works (internals at a glance)

- Java 11 HttpClient builds a POST to https://api.backgrounderase.net/v2
- Multipart form-data is constructed manually with a random boundary
- The file is sent under the field name image_file
- Content-Type is inferred via Files.probeContentType, with application/octet-stream fallback
- Response status 200 -> raw PNG bytes are written to <dst>; otherwise prints the error body

File: BackgroundRemoval.scala
- Main entry: run(args: String*)
- Usage helper: parseArgs ensures you provided <src> <dst> and an API key (flag or env)
- buildMultipart reads the file and returns (bodyBytes, contentTypeHeader)

## Troubleshooting

Common errors
- 401/403 Unauthorized/Forbidden
  - The API key is missing, invalid, or not entitled. Verify:
    - You passed --api-key or set BG_ERASE_API_KEY
    - Your plan is active: https://backgrounderase.net/pricing
- 404 Not Found
  - Check the endpoint (should be https://api.backgrounderase.net/v2)
- 413 Payload Too Large
  - The input image exceeds size limits for your plan
- 415 Unsupported Media Type
  - Try using a common extension (jpg, jpeg, png, heic, webp) so probeContentType can detect it
  - The client falls back to application/octet-stream; most common image types are accepted
- 429 Too Many Requests
  - You hit a rate/throughput limit; retry with backoff
- Non-200 response body printed
  - The program prints the server’s error text. Use it to diagnose.

Local issues
- File not found
  - Ensure <src> exists; the program will exit if it doesn’t
- Destination folder missing
  - Create the folder for <dst> before running
- SSL/proxy problems
  - Configure Java proxies (example): -Dhttps.proxyHost=host -Dhttps.proxyPort=port

Timeouts
- The sample does not set explicit timeouts. If you need them, you can:
  - Add a connect timeout on the client
  - Add a per-request timeout
- Example change (for reference only):
  ```scala
  val client = HttpClient.newBuilder()
    .connectTimeout(java.time.Duration.ofSeconds(15))
    .followRedirects(HttpClient.Redirect.NEVER)
    .build()

  val req = HttpRequest.newBuilder()
    .uri(URI.create("https://api.backgrounderase.net/v2"))
    .timeout(java.time.Duration.ofSeconds(60))
    ...
  ```

## Platform notes

- Java: Requires JDK 11+ (uses java.net.http.HttpClient introduced in Java 11)
- Scala: The file includes a scala-cli directive to pick the Scala version
- OS: Works on macOS, Linux, and Windows (adjust paths and env var syntax accordingly)

## Security

- Prefer BG_ERASE_API_KEY environment variable instead of committing keys to source control
- Avoid printing your API key to logs or terminals

## Support

- If you believe the issue is with the API or your account:
  - Check your plan: https://backgrounderase.net/pricing
  - Manage API keys: https://backgrounderase.net/account
- For code issues in this example, please include:
  - OS, Java version (java -version), scala-cli version (scala-cli version)
  - Command you ran
  - The full error output (status code and response body)