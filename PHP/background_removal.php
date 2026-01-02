<?php
/**
 * Background removal via multipart/form-data using PHP cURL.
 * Mirrors the Python example that posts `image_file` to /v2 with x-api-key.
 */

function background_removal(string $src, string $dst, string $apiKey): void
{
    if (!is_file($src) || !is_readable($src)) {
        throw new RuntimeException("Source file not found or not readable: $src");
    }

    // Detect MIME type (fallback to octet-stream if unknown)
    $mime = detectMime($src);

    $ch = curl_init('https://api.backgrounderase.net/v2');
    if ($ch === false) {
        throw new RuntimeException("Failed to initialize cURL");
    }

    // Build multipart payload using CURLFile
    $postFields = [
        'image_file' => new CURLFile($src, $mime, basename($src)),
    ];

    curl_setopt_array($ch, [
        CURLOPT_POST            => true,
        CURLOPT_POSTFIELDS      => $postFields,
        CURLOPT_HTTPHEADER      => [
            'x-api-key: ' . $apiKey,
            // Do NOT add Content-Type here; cURL sets it with the correct boundary.
        ],
        CURLOPT_RETURNTRANSFER  => true,   // capture response in a string
        CURLOPT_HEADER          => false,  // we only need the body
        CURLOPT_FOLLOWLOCATION  => false,
        CURLOPT_TIMEOUT         => 120,    // seconds
        CURLOPT_SSL_VERIFYPEER  => true,
        CURLOPT_SSL_VERIFYHOST  => 2,
    ]);

    $body = curl_exec($ch);
    $curlErr = curl_error($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $respContentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    curl_close($ch);

    if ($body === false) {
        throw new RuntimeException("cURL error: $curlErr");
    }

    if ($status === 200) {
        // Write binary output to destination path
        if (file_put_contents($dst, $body) === false) {
            throw new RuntimeException("Failed to write output file: $dst");
        }
        echo "✅ Saved: $dst\n";
        return;
    }

    // Try to show a helpful error message if server returned JSON
    $msg = "HTTP $status";
    $decoded = json_decode($body, true);
    if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
        // Common patterns: { "error": "...", "message": "...", "detail": "..." }
        $errText = $decoded['error'] ?? $decoded['message'] ?? $decoded['detail'] ?? null;
        if ($errText) {
            $msg .= " — " . $errText;
        }
    } else {
        // Fall back to raw text
        $snippet = trim(substr($body, 0, 300));
        if ($snippet !== '') {
            $msg .= " — " . $snippet;
        }
    }

    $ct = $respContentType ? " (Content-Type: $respContentType)" : '';
    throw new RuntimeException("❌ Request failed$ct: $msg");
}

/**
 * Robust MIME detection.
 */
function detectMime(string $path): string
{
    // Try finfo if available
    if (function_exists('finfo_open')) {
        $f = finfo_open(FILEINFO_MIME_TYPE);
        if ($f) {
            $m = finfo_file($f, $path);
            finfo_close($f);
            if ($m) return $m;
        }
    }
    // Fallback to mime_content_type
    if (function_exists('mime_content_type')) {
        $m = @mime_content_type($path);
        if ($m) return $m;
    }
    // Last resort
    return 'application/octet-stream';
}
// ---------- Example usage from CLI ----------
// php script.php /path/to/input.jpg /path/to/output.png [API_KEY]

const DEFAULT_API_KEY = 'YOUR_API_KEY_HERE';

if (PHP_SAPI === 'cli' && basename(__FILE__) === basename($_SERVER['argv'][0])) {
    [$script, $src, $dst, $apiKey] = $_SERVER['argv'] + [null, null, null, null];

    // Allow override from environment or CLI argument
    $apiKey = $apiKey ?: getenv('BG_ERASE_API_KEY') ?: DEFAULT_API_KEY;

    if (!$src || !$dst) {
        fwrite(STDERR, "Usage: php {$script} <input_path> <output_path> [API_KEY]\n");
        exit(2);
    }

    try {
        background_removal($src, $dst, $apiKey);
    } catch (Throwable $e) {
        fwrite(STDERR, $e->getMessage() . "\n");
        exit(1);
    }
}
