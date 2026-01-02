/*
 * background_removal.c
 *
 * Build:
 *   gcc -o bgremove background_removal.c -lcurl
 *
 * Usage:
 *   ./bgremove <src> <dst> [API_KEY]
 *   # or set env var:
 *   BACKGROUND_ERASE_API_KEY=your_key ./bgremove <src> <dst>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <curl/curl.h>
/* --- API key sources & precedence ---
   1) argv[3] (explicit command-line)
   2) BACKGROUND_ERASE_API_KEY (environment)
   3) DEFAULT_API_KEY (compiled-in; may be empty)
*/
#ifndef DEFAULT_API_KEY
#define DEFAULT_API_KEY "YOUR_API_KEY_HERE"   /* Put a non-empty string here, or pass -DDEFAULT_API_KEY=\"...\" at compile time */
#endif

static const char* resolve_api_key(int argc, char **argv) {
    if (argc >= 4 && argv[3] && argv[3][0] != '\0') {
        return argv[3];
    }
    const char *env = getenv("BACKGROUND_ERASE_API_KEY");
    if (env && env[0] != '\0') {
        return env;
    }
    if (DEFAULT_API_KEY[0] != '\0') {
        return DEFAULT_API_KEY;
    }
    return NULL; // no key found
}

typedef struct {
    unsigned char *data;
    size_t size;
} MemBuf;

static size_t write_cb(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    MemBuf *mem = (MemBuf *)userp;
    unsigned char *ptr = (unsigned char *)realloc(mem->data, mem->size + realsize + 1);
    if (!ptr) return 0; // out of memory -> abort transfer
    mem->data = ptr;
    memcpy(mem->data + mem->size, contents, realsize);
    mem->size += realsize;
    mem->data[mem->size] = 0; // NUL-terminate for convenience
    return realsize;
}

static const char* guess_content_type(const char *path) {
    const char *dot = strrchr(path, '.');
    if (!dot || dot == path) return "application/octet-stream";
    dot++; // skip '.'

    // lowercase copy of extension
    char ext[16];
    size_t n = 0;
    while (dot[n] && n < sizeof(ext)-1) { ext[n] = (char)tolower((unsigned char)dot[n]); n++; }
    ext[n] = '\0';

    if (!strcmp(ext, "png"))  return "image/png";
    if (!strcmp(ext, "jpg") || !strcmp(ext, "jpeg")) return "image/jpeg";
    if (!strcmp(ext, "gif"))  return "image/gif";
    if (!strcmp(ext, "webp")) return "image/webp";
    if (!strcmp(ext, "bmp"))  return "image/bmp";
    if (!strcmp(ext, "tif") || !strcmp(ext, "tiff")) return "image/tiff";
    if (!strcmp(ext, "heic")) return "image/heic";
    if (!strcmp(ext, "heif")) return "image/heif";
    return "application/octet-stream";
}

static const char* basename_c(const char *path) {
    const char *slash = strrchr(path, '/');
#ifdef _WIN32
    const char *bslash = strrchr(path, '\\');
    if (!slash || (bslash && bslash > slash)) slash = bslash;
#endif
    return slash ? slash + 1 : path;
}

int background_removal(const char *src, const char *dst, const char *api_key) {
    if (!src || !dst || !api_key) {
        fprintf(stderr, "Missing required arguments.\n");
        return 2;
    }

    CURLcode rc;
    CURL *curl = NULL;
    curl_mime *mime = NULL;
    curl_mimepart *part = NULL;
    struct curl_slist *headers = NULL;
    long http_code = 0;
    int exit_code = 1; // assume failure

    MemBuf buf = {0};

    rc = curl_global_init(CURL_GLOBAL_DEFAULT);
    if (rc != CURLE_OK) {
        fprintf(stderr, "curl_global_init failed: %s\n", curl_easy_strerror(rc));
        return 1;
    }

    curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "curl_easy_init failed.\n");
        curl_global_cleanup();
        return 1;
    }

    // Endpoint
    curl_easy_setopt(curl, CURLOPT_URL, "https://api.backgrounderase.net/v2");
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "bgremove-c/1.0");

    // Timeouts (tweak as needed)
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 15L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 300L);

    // Build multipart/form-data
    mime = curl_mime_init(curl);
    part = curl_mime_addpart(mime);
    curl_mime_name(part, "image_file");                 // field name
    curl_mime_filedata(part, src);                      // upload file contents
    curl_mime_filename(part, basename_c(src));          // filename=
    curl_mime_type(part, guess_content_type(src));      // Content-Type for this part

    curl_easy_setopt(curl, CURLOPT_MIMEPOST, mime);

    // Headers: x-api-key (+ optional 'Expect:' to avoid 100-continue delays)
    {
        size_t need = strlen("x-api-key: ") + strlen(api_key);
        char *api_hdr = (char *)malloc(need + 1);
        if (!api_hdr) {
            fprintf(stderr, "Out of memory.\n");
            goto cleanup;
        }
        sprintf(api_hdr, "x-api-key: %s", api_key);
        headers = curl_slist_append(headers, api_hdr);
        free(api_hdr);
    }
    headers = curl_slist_append(headers, "Expect:"); // disable 'Expect: 100-continue'
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    // Capture response body in memory (so we only write file on HTTP 200)
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&buf);

    // Perform request
    rc = curl_easy_perform(curl);
    if (rc != CURLE_OK) {
        fprintf(stderr, "❌ cURL error: %s\n", curl_easy_strerror(rc));
        goto cleanup;
    }

    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

    if (http_code == 200L) {
        // Write binary response to file
        FILE *fp = fopen(dst, "wb");
        if (!fp) {
            perror("fopen");
            goto cleanup;
        }
        if (buf.size > 0 && fwrite(buf.data, 1, buf.size, fp) != buf.size) {
            perror("fwrite");
            fclose(fp);
            goto cleanup;
        }
        fclose(fp);
        printf("✅ Saved: %s\n", dst);
        exit_code = 0;
    } else {
        // Error: print status and server payload (likely JSON or text)
        fprintf(stderr, "❌ HTTP %ld\n", http_code);
        if (buf.size > 0) {
            // ensure it prints safely even if binary; treat as text
            fwrite(buf.data, 1, buf.size, stderr);
            fputc('\n', stderr);
        }
    }

cleanup:
    if (headers) curl_slist_free_all(headers);
    if (mime) curl_mime_free(mime);
    if (curl) curl_easy_cleanup(curl);
    if (buf.data) free(buf.data);
    curl_global_cleanup();
    return exit_code;
}

int main(int argc, char **argv) {
    if (argc < 3 || argc > 4) {
        fprintf(stderr,
            "Usage: %s <src_image> <dst_output> [API_KEY]\n"
            "API key precedence: CLI > env BACKGROUND_ERASE_API_KEY > DEFAULT_API_KEY (compiled)\n",
            argv[0]);
        return 2;
    }

    const char *src = argv[1];
    const char *dst = argv[2];
    const char *api_key = resolve_api_key(argc, argv);

    if (!api_key) {
        fprintf(stderr,
            "Missing API key.\n"
            "Provide as argv[3], or set BACKGROUND_ERASE_API_KEY, or compile with -DDEFAULT_API_KEY=\"...\".\n");
        return 2;
    }

    return background_removal(src, dst, api_key);
}

