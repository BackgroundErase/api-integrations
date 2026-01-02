# background_removal.ps1
# Usage:
#   pwsh ./background_removal.ps1 -Src "input.jpg" -Dst "output.png" -ApiKey "YOUR_API_KEY"

param(
  [Parameter(Mandatory=$true)] [string]$Src,
  [Parameter(Mandatory=$true)] [string]$Dst,
  [Parameter(Mandatory=$true)] [string]$ApiKey
)

# Minimal content-type mapping (falls back to application/octet-stream)
function Get-ContentType([string]$path) {
  $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
  switch ($ext) {
    ".jpg" { "image/jpeg" ; break }
    ".jpeg" { "image/jpeg" ; break }
    ".png" { "image/png" ; break }
    ".webp" { "image/webp" ; break }
    ".bmp" { "image/bmp" ; break }
    ".tif" { "image/tiff" ; break }
    ".tiff" { "image/tiff" ; break }
    default { "application/octet-stream" }
  }
}

if (-not (Test-Path -LiteralPath $Src)) {
  Write-Error "Input file not found: $Src"
  exit 1
}

$fname = [System.IO.Path]::GetFileName($Src)
$ctype = Get-ContentType $Src

$handler = [System.Net.Http.HttpClientHandler]::new()
$http    = [System.Net.Http.HttpClient]::new($handler)
$http.Timeout = [TimeSpan]::FromSeconds(120)

try {
  $content = [System.Net.Http.MultipartFormDataContent]::new()

  $fs = [System.IO.File]::OpenRead($Src)
  $fileContent = [System.Net.Http.StreamContent]::new($fs)
  $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($ctype)

  # name must match server expectation: image_file
  $content.Add($fileContent, "image_file", $fname)

  # Add API key header
  $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, "https://api.backgrounderase.net/v2")
  $request.Headers.Add("x-api-key", $ApiKey)
  $request.Content = $content

  $response = $http.Send($request)
  $status   = [int]$response.StatusCode
  $ctypeOut = $response.Content.Headers.ContentType?.MediaType

  if ($status -eq 200 -and $ctypeOut -and $ctypeOut.StartsWith("image/")) {
    # Save binary image to destination
    $bytes = $response.Content.ReadAsByteArrayAsync().Result
    [System.IO.File]::WriteAllBytes($Dst, $bytes)
    Write-Host "✅ Saved: $Dst"
  }
  else {
    # Show text error body if available
    $body = $response.Content.ReadAsStringAsync().Result
    $reason = $response.ReasonPhrase
    if ([string]::IsNullOrWhiteSpace($body)) { $body = "<no body>" }
    Write-Host ("❌ {0} {1} {2}" -f $status, $reason, $body)
    exit 1
  }
}
catch {
  Write-Host "❌ Request failed: $($_.Exception.Message)"
  exit 1
}
finally {
  if ($fileContent) { $fileContent.Dispose() }
  if ($fs) { $fs.Dispose() }
  if ($content) { $content.Dispose() }
  if ($http) { $http.Dispose() }
}
