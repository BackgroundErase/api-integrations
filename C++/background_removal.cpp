// background_removal.cpp
// Build: see instructions below (Linux/macOS/Windows)
// Requires: libcurl with SSL

#include <curl/curl.h>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <filesystem>




namespace fs = std::filesystem;


static size_t write_to_vector(char* ptr, size_t size, size_t nmemb, void* userdata) {
    auto* buf = static_cast<std::vector<unsigned char>*>(userdata);
    size_t total = size * nmemb;
    buf->insert(buf->end(), reinterpret_cast<unsigned char*>(ptr), reinterpret_cast<unsigned char*>(ptr) + total);
    return total;
}

static std::string guess_mime(const std::string& path) {
    std::string ext = fs::path(path).extension().string();
    for (auto& c : ext) c = static_cast<char>(::tolower(static_cast<unsigned char>(c)));
    if (ext == ".png")  return "image/png";
    if (ext == ".jpg" || ext == ".jpeg") return "image/jpeg";
    if (ext == ".webp") return "image/webp";
    if (ext == ".gif")  return "image/gif";
    if (ext == ".bmp")  return "image/bmp";
    if (ext == ".tif" || ext == ".tiff") return "image/tiff";
    return "application/octet-stream";
}

bool background_removal(const std::string& src,
                        const std::string& dst,
                        const std::string& api_key) {
    CURLcode ginit = curl_global_init(CURL_GLOBAL_DEFAULT);
    if (ginit != CURLE_OK) {
        std::cerr << "curl_global_init failed: " << curl_easy_strerror(ginit) << "\n";
        return false;
    }

    bool ok = false;
    CURL* curl = curl_easy_init();
    if (!curl) {
        std::cerr << "curl_easy_init failed\n";
        curl_global_cleanup();
        return false;
    }

    std::vector<unsigned char> response;
    char errbuf[CURL_ERROR_SIZE] = {0};

    // Prepare MIME form
    curl_mime* mime = curl_mime_init(curl);
    curl_mimepart* part = curl_mime_addpart(mime);
    curl_mime_name(part, "image_file");
    curl_mime_filedata(part, src.c_str()); // streams from disk
    // Optional: set explicit content type (server usually accepts default too)
    std::string ctype = guess_mime(src);
    curl_mime_type(part, ctype.c_str());
    // Optional: enforce a filename (libcurl uses basename by default)
    std::string fname = fs::path(src).filename().string();
    curl_mime_filename(part, fname.c_str());

    // Headers
    struct curl_slist* headers = nullptr;
    std::string api_key_header = "x-api-key: " + api_key;
    headers = curl_slist_append(headers, api_key_header.c_str());
    // Remove "Expect: 100-continue" to avoid some server/proxy quirks
    headers = curl_slist_append(headers, "Expect:");

    // libcurl options
    curl_easy_setopt(curl, CURLOPT_URL, "https://api.backgrounderase.net/v2");
    curl_easy_setopt(curl, CURLOPT_MIMEPOST, mime);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_to_vector);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
    curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errbuf);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "background-removal-cpp/1.0");

    // Perform
    CURLcode res = curl_easy_perform(curl);

    long status = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &status);

    if (res != CURLE_OK) {
        std::cerr << "❌ libcurl error: " << curl_easy_strerror(res)
                  << (errbuf[0] ? std::string(" — ") + errbuf : "") << "\n";
    } else if (status == 200) {
        std::ofstream ofs(dst, std::ios::binary);
        if (!ofs) {
            std::cerr << "❌ Cannot open output file: " << dst << "\n";
        } else {
            ofs.write(reinterpret_cast<const char*>(response.data()), static_cast<std::streamsize>(response.size()));
            ofs.close();
            std::cout << "✅ Saved: " << dst << "\n";
            ok = true;
        }
    } else {
        // Server returned an error; print textual body if present
        std::string body(response.begin(), response.end());
        std::cerr << "❌ HTTP " << status << " — " << body << "\n";
    }

    // Cleanup
    curl_slist_free_all(headers);
    curl_mime_free(mime);
    curl_easy_cleanup(curl);
    curl_global_cleanup();
    return ok;
}




// Keep your existing kDefaultApiKey
static constexpr const char* kDefaultApiKey =
    "YOUR_API_KEY_HERE";

int main(int argc, char** argv) {
    if (argc < 3 || argc > 4) {
        std::cerr << "Usage: " << argv[0] << " <source_image> <dest_image> [API_KEY]\n"
                     "       (or set environment variable BG_ERASE_API_KEY)\n";
        return 1;
    }
    std::string src = argv[1];
    std::string dst = argv[2];

    // Precedence: CLI > ENV > compiled-in default
    std::string api_key = kDefaultApiKey;
    if (const char* env = std::getenv("BG_ERASE_API_KEY"); env && *env) api_key = env;
    if (argc == 4 && argv[3] && *argv[3]) api_key = argv[3];

    // 👉 Only check for emptiness
    if (api_key.empty()) {
        std::cerr << "❌ Missing API key. Set kDefaultApiKey, pass argv[3], or set BG_ERASE_API_KEY.\n";
        return 1;
    }

    if (!fs::exists(src)) {
        std::cerr << "❌ Source file not found: " << src << "\n";
        return 1;
    }

    return background_removal(src, dst, api_key) ? 0 : 2;
}
