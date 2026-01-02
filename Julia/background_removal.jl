using HTTP
using UUIDs
using MIMEs

function background_removal(src::String, dst::String, api_key::String)
    # Get file name and MIME type
    fname = basename(src)
    ctype = try
        string(MIME(HTTP.sniffmime(src)))
    catch
        "application/octet-stream"
    end
    boundary = "----" * string(uuid4())

    # Read file data
    data = read(src)

    # Build multipart body
    CRLF = "\r\n"
    header_part = "--$boundary$CRLF" *
                  "Content-Disposition: form-data; name=\"image_file\"; filename=\"$fname\"$CRLF" *
                  "Content-Type: $ctype$CRLF$CRLF"

    footer_part = "$CRLF--$boundary--$CRLF"

    body = vcat(Vector{UInt8}(header_part), data, Vector{UInt8}(footer_part))

    headers = [
        "Content-Type" => "multipart/form-data; boundary=$boundary",
        "x-api-key" => api_key,
        "Content-Length" => string(length(body))
    ]

    # Send POST request
    resp = HTTP.request("POST", "https://api.backgrounderase.net/v2", headers, body)

    if resp.status == 200
        open(dst, "w") do io
            write(io, resp.body)
        end
        println("✅ Saved: $dst")
    else
        println("❌ $(resp.status): $(String(resp.body))")
    end
end

# Command-line usage
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 3
        println("Usage: julia ben.jl <API_KEY> <input.jpg> <output.png>")
        exit(1)
    end
    api_key, src, dst = ARGS
    background_removal(src, dst, api_key)
end

