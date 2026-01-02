package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"os"
	"path/filepath"
	"time"
)

func backgroundRemoval(src, dst, apiKey string) error {
	file, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("open %q: %w", src, err)
	}
	defer file.Close()

	filename := filepath.Base(src)

	// Guess a content type from the extension; fall back to octet-stream like the Python version.
	ctype := mime.TypeByExtension(filepath.Ext(filename))
	if ctype == "" {
		ctype = "application/octet-stream"
	}

	// Build multipart body in memory (mirrors your Python approach).
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)

	// Manually set headers so we can include the part's Content-Type.
	h := make(textproto.MIMEHeader)
	h.Set("Content-Disposition", fmt.Sprintf(`form-data; name="image_file"; filename="%s"`, filename))
	h.Set("Content-Type", ctype)

	part, err := writer.CreatePart(h)
	if err != nil {
		return fmt.Errorf("create form part: %w", err)
	}
	if _, err := io.Copy(part, file); err != nil {
		return fmt.Errorf("copy file data: %w", err)
	}
	if err := writer.Close(); err != nil {
		return fmt.Errorf("close multipart writer: %w", err)
	}

	req, err := http.NewRequest("POST", "https://api.backgrounderase.net/v2", &body)
	if err != nil {
		return fmt.Errorf("new request: %w", err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("x-api-key", apiKey)
	// Optional: set Content-Length explicitly (http will also infer it from bytes.Buffer)
	req.ContentLength = int64(body.Len())

	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("http post: %w", err)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode == http.StatusOK {
		if err := os.WriteFile(dst, respBytes, 0o644); err != nil {
			return fmt.Errorf("write output file: %w", err)
		}
		fmt.Println("✅ Saved:", dst)
		return nil
	}

	return fmt.Errorf("❌ %d %s\n%s", resp.StatusCode, http.StatusText(resp.StatusCode), string(respBytes))
}

func main() {
	in := flag.String("in", "", "Path to input image")
	out := flag.String("out", "", "Path to save output image")
	key := flag.String("key", "", "API key (or set BACKGROUND_ERASE_API_KEY)")
	flag.Parse()

	apiKey := *key
	if apiKey == "" {
		apiKey = os.Getenv("BACKGROUND_ERASE_API_KEY")
	}

	if apiKey == "" || *in == "" || *out == "" {
		fmt.Fprintln(os.Stderr, "Usage: background-erase -in input.jpg -out output.png [-key YOUR_API_KEY]")
		if apiKey == "" {
			fmt.Fprintln(os.Stderr, "Provide -key or set BACKGROUND_ERASE_API_KEY environment variable.")
		}
		os.Exit(2)
	}

	if err := backgroundRemoval(*in, *out, apiKey); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

