# BackgroundErase.NET C#/.NET API Client (CLI + single-file client)

Minimal C# client and command-line tool to remove image backgrounds using the BackgroundErase.NET API.

- API base: https://api.backgrounderase.net/v2
- Get an API key: https://backgrounderase.net/account
- Plans/pricing: https://backgrounderase.net/pricing

Contents
- CS/BENClient.cs — low-level HTTP client (multipart/form-data upload)
- CS/Program.cs — CLI wrapper that calls BENClient and writes the PNG result

What you get
- Upload a single image under field name image_file
- Receive a PNG with transparency on success (HTTP 200)
- Simple CLI: dotnet run -- <input> [output]


## Requirements

- .NET 6.0+ SDK (6, 7, or 8 are fine)
  - Install: https://dotnet.microsoft.com/download
- An API key from https://backgrounderase.net/account


## Install just the C# client

Option A: git sparse-checkout
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set CS
git checkout main   # or whatever the default branch is
cd CS
```

Option B: svn export
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/CS
cd CS
```

Download a sample image (optional):
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```


## Configure your API key

Choose one of:
- Edit Program.cs and set DefaultApiKey to your key (fastest)
- Or set an environment variable BG_ERASE_API_KEY (recommended for security)

Examples for BG_ERASE_API_KEY:

- macOS/Linux (bash/zsh)
```bash
export BG_ERASE_API_KEY="sk_live_123..."
```

- Windows PowerShell
```powershell
setx BG_ERASE_API_KEY "sk_live_123..."
# Restart your terminal to pick up the new variable
```

Note: The provided Program.cs is designed to read from a DefaultApiKey constant. If you prefer using BG_ERASE_API_KEY, see “Known fixes” below to ensure the env var is read at runtime.


## Build and run the CLI

From the CS folder:
```bash
dotnet build
dotnet run -- ./input.jpg ./output.no-bg.png
```

- If you omit the output path, the tool writes next to your input as <input>.no-bg.png
- Exit codes:
  - 0 = success
  - 1 = failure
  - 2 = usage error or missing input file
  - 130 = canceled (Ctrl+C)

Examples:
```bash
dotnet run -- ./photo.jpg
# writes ./photo.no-bg.png

dotnet run -- "./My Pictures/selfie.jpeg" "./out/selfie.no-bg.png"
```


## Use the client in your own C# app

Copy CS/BENClient.cs into your project and call:

```csharp
using System.Threading;
using System.Threading.Tasks;

var ok = await BENClient.RemoveBackgroundManualAsync(
    src: "input.jpg",
    dst: "cutout.png",     // saved as PNG with transparency
    apiKey: "YOUR_API_KEY",
    ct: CancellationToken.None);

if (!ok)
{
    // handle error
}
```

Notes
- The client uploads your file as multipart/form-data under field name image_file.
- The response body (on success) is the PNG bytes. BENClient saves the bytes to dst for you.
- GuessMimeType uses the file extension to set Content-Type; unknown extensions default to application/octet-stream.


## Troubleshooting

- 401 Unauthorized
  - Invalid/missing API key. Verify your key and plan at https://backgrounderase.net/account
  - If using environment variables, confirm your process actually sees BG_ERASE_API_KEY.

- 400/415 Bad Request or Unsupported Media Type
  - Ensure your input file is a valid image (jpg/jpeg/png/webp/gif/bmp/tif/tiff/heic/heif are recognized).

- 413 Payload Too Large
  - Image is too large for your plan. Check plan limits.

- Networking/SSL issues behind proxies
  - Try from a different network or configure proxy settings for HttpClient if needed.

- Nothing written to output
  - Check the console for an error message and HTTP status. The tool prints the server’s error body when available.


## API details (what the client sends)

- Method: POST https://api.backgrounderase.net/v2
- Headers:
  - x-api-key: YOUR_API_KEY
  - Content-Type: multipart/form-data; boundary=...
- Body:
  - image_file: your image bytes (filename and content type inferred from your input path)
- Response:
  - 200 OK: raw PNG bytes (transparent background)
  - Non-200: JSON or text describing the error; the CLI prints it


## Known fixes (apply if your local copy doesn’t build)

If you copied the CS/*.cs snippets above and see build errors, apply these small fixes:

1) Program.cs
- Make sure the program actually calls BENClient and (optionally) reads BG_ERASE_API_KEY.

Replace the call block with:
```csharp
// Choose API key: environment variable takes precedence, then the hardcoded default.
var apiKey = Environment.GetEnvironmentVariable("BG_ERASE_API_KEY") ?? DefaultApiKey;

if (string.IsNullOrWhiteSpace(apiKey) || apiKey == "YOUR_API_KEY" || apiKey == "YOUR_API_KEY_HERE")
{
    Console.Error.WriteLine(
        "Please set your API key in Program.cs (DefaultApiKey) or via the BG_ERASE_API_KEY environment variable.");
    return 2;
}

using var cts = new CancellationTokenSource();
Console.CancelKeyPress += (_, e) => { e.Cancel = true; cts.Cancel(); };

try
{
    var ok = await BENClient.RemoveBackgroundManualAsync(src, dst, apiKey, cts.Token);
    return ok ? 0 : 1;
}
```

2) BENClient.cs
- Ensure CRLF and quoted header values are correct:

```csharp
const string CRLF = "\r\n";

var header =
    $"--{boundary}{CRLF}" +
    $"Content-Disposition: form-data; name=\"image_file\"; filename=\"{fileName}\"{CRLF}" +
    $"Content-Type: {contentType}{CRLF}{CRLF}";
```

These changes address common copy/paste issues (newline constant, string quoting, and a stray token in Program.cs).


## FAQ

- Does the API return a PNG even if I upload a JPEG?
  - Yes, the output is a PNG with transparency.

- How big can my input image be?
  - Depends on your plan. See https://backgrounderase.net/pricing

- Can I change timeouts or add retries?
  - You can wrap the HttpClient call in your own retry logic or pass a CancellationToken with a timeout via CancellationTokenSource.


## License and contributions

- This sample is provided as-is to help you integrate with BackgroundErase.NET.
- Issues and PRs are welcome. Please include:
  - .NET version, OS, reproduction steps, and any console logs.