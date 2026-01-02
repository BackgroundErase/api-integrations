using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public static class BENClient
{
    private static readonly Uri Endpoint = new Uri("https://api.backgrounderase.net/v2");

    public static async Task<bool> RemoveBackgroundManualAsync(
        string src,
        string dst,
        string apiKey,
        CancellationToken ct = default)
    {
        var boundary = "----" + Guid.NewGuid().ToString("N");
        const string CRLF = "\r\n";

        var fileName = Path.GetFileName(src);
        var contentType = GuessMimeType(src);

        var header =
            $"--{boundary}{CRLF}" +
            $"Content-Disposition: form-data; name=\"image_file\"; filename=\"{fileName}\"{CRLF}" +
            $"Content-Type: {contentType}{CRLF}{CRLF}";

        var trailer = $"{CRLF}--{boundary}--{CRLF}";

        var fileBytes = await File.ReadAllBytesAsync(src, ct);
        var headerBytes = Encoding.ASCII.GetBytes(header);
        var trailerBytes = Encoding.ASCII.GetBytes(trailer);

        using var ms = new MemoryStream(headerBytes.Length + fileBytes.Length + trailerBytes.Length);
        ms.Write(headerBytes, 0, headerBytes.Length);
        ms.Write(fileBytes, 0, fileBytes.Length);
        ms.Write(trailerBytes, 0, trailerBytes.Length);

        using var content = new ByteArrayContent(ms.ToArray());
        content.Headers.ContentType = new MediaTypeHeaderValue("multipart/form-data");
        content.Headers.ContentType.Parameters.Add(new NameValueHeaderValue("boundary", boundary));

        using var req = new HttpRequestMessage(HttpMethod.Post, Endpoint) { Content = content };
        req.Headers.Add("x-api-key", apiKey);

        using var client = new HttpClient();
        using var resp = await client.SendAsync(req, HttpCompletionOption.ResponseHeadersRead, ct);
        var bytes = await resp.Content.ReadAsByteArrayAsync(ct);

        if (resp.IsSuccessStatusCode)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(dst))!);
            await File.WriteAllBytesAsync(dst, bytes, ct);
            Console.WriteLine($"✅ Saved: {dst}");
            return true;
        }

        Console.Error.WriteLine($"❌ {(int)resp.StatusCode} {resp.ReasonPhrase}\n{TryDecodeUtf8(bytes)}");
        return false;
    }

    private static string GuessMimeType(string path)
    {
        var ext = Path.GetExtension(path).ToLowerInvariant();
        return ext switch
        {
            ".png"            => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".webp"           => "image/webp",
            ".gif"            => "image/gif",
            ".bmp"            => "image/bmp",
            ".tif" or ".tiff" => "image/tiff",
            ".heic"           => "image/heic",
            ".heif"           => "image/heif",
            _                 => "application/octet-stream"
        };
    }

    private static string TryDecodeUtf8(byte[] bytes)
    {
        try { return Encoding.UTF8.GetString(bytes); }
        catch { return $"[{bytes.Length} bytes]"; }
    }
}
