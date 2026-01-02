import java.io.*;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.UUID;

public class BenBackgroundRemoval {

    // TODO: put your real key here or load from env/props
    private static final String API_KEY = "YOUR_API_KEY";

    public static void main(String[] args) throws Exception {
        // Example usage:
        Path src = Path.of("input.jpg");       // your input image
        Path dst = Path.of("output.png");      // where to save result
        backgroundRemoval(src, dst);
    }

    public static void backgroundRemoval(Path src, Path dst) throws Exception {
        String fileName = src.getFileName().toString();
        String contentType = Files.probeContentType(src);
        if (contentType == null) contentType = "application/octet-stream";

        byte[] fileBytes = Files.readAllBytes(src);

        // Build multipart body manually
        String boundary = "----" + UUID.randomUUID().toString().replace("-", "");
        byte[] body = buildMultipartBody(boundary, fileName, contentType, fileBytes);

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(20))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://api.backgrounderase.net/v2"))
                .timeout(Duration.ofSeconds(120))
                .header("x-api-key", API_KEY)
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body))
                .build();

        HttpResponse<byte[]> resp = client.send(request, HttpResponse.BodyHandlers.ofByteArray());

        if (resp.statusCode() == 200) {
            Files.write(dst, resp.body());
            System.out.println("✅ Saved: " + dst.toAbsolutePath());
        } else {
            String err = new String(resp.body());
            System.out.println("❌ " + resp.statusCode() + " " + err);
        }
    }

    private static byte[] buildMultipartBody(String boundary,
                                             String fileName,
                                             String contentType,
                                             byte[] fileBytes) throws IOException {
        String CRLF = "\r\n";
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (var out = new DataOutputStream(baos)) {
            // Part: image_file
            out.writeBytes("--" + boundary + CRLF);
            out.writeBytes("Content-Disposition: form-data; name=\"image_file\"; filename=\"" + escapeQuotes(fileName) + "\"" + CRLF);
            out.writeBytes("Content-Type: " + contentType + CRLF);
            out.writeBytes(CRLF);
            out.write(fileBytes);
            out.writeBytes(CRLF);

            // End boundary
            out.writeBytes("--" + boundary + "--" + CRLF);
        }
        return baos.toByteArray();
    }

    private static String escapeQuotes(String s) {
        return s.replace("\"", "\\\"");
    }
}
