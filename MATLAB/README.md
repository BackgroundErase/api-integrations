# BEN2 MATLAB API Client (Background removal)

A single-file MATLAB function that uploads an image to BackgroundErase.NET, saves the cutout as PNG (with transparency), and shows a side‑by‑side before/after preview.

- API endpoint: https://api.backgrounderase.net/v2
- Get your API key: https://backgrounderase.net/account
- Plans: https://backgrounderase.net/pricing

## Requirements

- MATLAB R2016b or newer (uses matlab.net.http.*)
- Optional: Image Processing Toolbox (for imshow). If not installed, you can comment out the display lines or use image/imshowpair alternatives.
- macOS, Windows, or Linux with internet access

## Install

Option A: Clone only the MATLAB folder
```bash
git clone --no-checkout https://github.com/PramaLLC/ben-api-other-integrations.git
cd ben-api-other-integrations
git sparse-checkout init --cone
git sparse-checkout set MATLAB
git checkout main
cd MATLAB
```

Option B: SVN export just this folder
```bash
svn export https://github.com/PramaLLC/ben-api-other-integrations/trunk/MATLAB
cd MATLAB
```

Option C: Direct download the function
- Save the file in this repo as background_removal.m (file name must match the function name in MATLAB)
- Place it in your working folder or anywhere on the MATLAB path

## Get an API key

1) Sign in or create an account: https://backgrounderase.net/account  
2) If needed, purchase/upgrade a plan: https://backgrounderase.net/pricing  
3) Copy your API key from the account page (near the bottom)

Keep your key private. Do not commit it to source control.

## Quick start

Download a sample input image:
```bash
curl -L -o input.jpg https://raw.githubusercontent.com/PramaLLC/ben-api-other-integrations/main/input.jpg
```

In MATLAB:
```matlab
% If you're in the MATLAB folder, add it to the path (optional if already there)
addpath(pwd);

% Run the background removal
background_removal('input.jpg', 'output.png', 'YOUR_API_KEY');
```

What happens:
- Uploads the image as multipart/form-data (field name image_file) to https://api.backgrounderase.net/v2
- Saves the result as output.png (PNG with transparency)
- Opens a figure showing Original vs Background Removed side by side

## Usage

Function signature:
```matlab
background_removal(src, dst, api_key)
```

- src: path to an input image (jpg, jpeg, png, heic, webp, others fallback to application/octet-stream)
- dst: path to save the resulting PNG (e.g., output.png)
- api_key: your BackgroundErase.NET API key string

Examples:
```matlab
% Basic
background_removal('photo.jpg', 'cutout.png', 'sk_live_...');

% With absolute paths
background_removal('C:\images\input.png', 'C:\images\output.png', 'sk_live_...');

% Paths with spaces (use quotes):
background_removal('my pics/input.jpg', 'my pics/output.png', 'sk_live_...');
```

Notes:
- The API returns raw PNG bytes. The function writes them directly to dst.
- The figure preview uses imshow; if you don’t have Image Processing Toolbox, comment out the display block or replace with image(imread(...)).

## How it works (high level)

- Reads your image as raw bytes
- Detects a MIME type from the file extension (falls back to application/octet-stream)
- Builds a multipart/form-data request with:
  - Field name: image_file
  - File name: the source file’s name and extension
- Sends POST to https://api.backgrounderase.net/v2 with header x-api-key: YOUR_API_KEY
- On 200 OK, saves the body bytes to the destination file and shows a side‑by‑side figure

## Troubleshooting

- 401 Unauthorized
  - Double-check your API key
  - Ensure your subscription is active: https://backgrounderase.net/pricing
- Non-200 response / error body
  - The function prints the HTTP status and server message if present
- SSL/Proxy/Firewall issues
  - If behind a corporate proxy, configure MATLAB’s proxy in Preferences → Web or via:
    - setpref('Internet','UseSystemProxy', true)
    - Or set specific proxy host/port in MATLAB internet preferences
  - Ensure your network allows outbound HTTPS to api.backgrounderase.net
- File I/O errors
  - Verify src exists and is readable; verify dst’s folder is writable
- No figure appears or imshow not found
  - Image Processing Toolbox is recommended for imshow
  - As an alternative, comment out imshow lines or use:
    - img = imread(src); image(img); axis image off;

## Security tips

- Don’t hardcode real keys in scripts committed to Git
- Use environment variables or MATLAB preferences to load keys when possible
- Rotate keys if they’ve been exposed accidentally

## Reference: Function source

Place this function in a file named background_removal.m:

```matlab
function background_removal(src, dst, api_key)
    % BACKGROUND_REMOVAL  Uploads an image to the Background Erase API and
    % shows before/after result side by side in MATLAB.
    %
    % Usage:
    %   background_removal('input.jpg', 'output.png', 'YOUR_API_KEY')

    if nargin < 3
        error('Usage: background_removal("input.jpg","output.png","YOUR_API_KEY")');
    end

    % Read the file and determine its type
    [~, fname, ext] = fileparts(src);

    % Read file as raw bytes (important for binary data)
    fid = fopen(src, 'rb');
    if fid == -1
        error('Cannot open input file: %s', src);
    end
    fileData = fread(fid, '*uint8')';
    fclose(fid);

    % Guess MIME type
    try
        ctype = matlab.net.internal.getMIMEType(ext);
    catch
        ctype = '';
    end
    if isempty(ctype)
        ctype = 'application/octet-stream';
    end

    % Generate multipart boundary and CRLF
    boundary = ['----' char(java.util.UUID.randomUUID())];
    CRLF = char([13 10]);

    % Build multipart body
    headerPart = sprintf(['--%s%s' ...
        'Content-Disposition: form-data; name="image_file"; filename="%s%s"%s' ...
        'Content-Type: %s%s%s'], ...
        boundary, CRLF, fname, ext, CRLF, ctype, CRLF, CRLF);

    footerPart = sprintf('%s--%s--%s', CRLF, boundary, CRLF);

    % Combine into one binary array
    body = [uint8(headerPart) fileData uint8(footerPart)];

    % HTTP headers
    headerFields = [ ...
        matlab.net.http.field.ContentTypeField(['multipart/form-data; boundary=' boundary]), ...
        matlab.net.http.HeaderField('x-api-key', api_key) ...
    ];

    % Build and send request
    req = matlab.net.http.RequestMessage('POST', headerFields, body);
    uri = matlab.net.URI('https://api.backgrounderase.net/v2');
    resp = send(req, uri);

    % Handle response
    if resp.StatusCode == matlab.net.http.StatusCode.OK
        % Save result
        fid = fopen(dst, 'wb');
        fwrite(fid, resp.Body.Data);
        fclose(fid);
        fprintf('Saved: %s\n', dst);

        % Display original vs result
        try
            figure('Name', 'Background Removal Result', 'NumberTitle', 'off');
            subplot(1,2,1);
            imshow(imread(src));
            title('Original');

            subplot(1,2,2);
            imshow(imread(dst));
            title('Background Removed');
        catch
            % If imshow not available, skip visualization
        end
    else
        fprintf('HTTP error: %s\n', string(resp.StatusCode));
        if ~isempty(resp.Body.Data)
            try
                disp(char(resp.Body.Data));
            catch
                % raw bytes; ignore
            end
        end
    end
end
```

## Support

Issues and pull requests are welcome in this repo. When reporting problems, include:
- MATLAB version and OS
- Exact command you ran
- Full error message / output
- Whether you’re behind a proxy or firewall