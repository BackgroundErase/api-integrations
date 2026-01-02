import http.client, os, uuid, mimetypes

API_KEY = "YOUR_API_KEY"

def background_removal(src, dst):
    fname = os.path.basename(src)
    ctype = mimetypes.guess_type(src)[0] or "application/octet-stream"
    boundary, CRLF = "----%s" % uuid.uuid4().hex, "\r\n"

    with open(src, "rb") as f: data = f.read()

    body = (
        f"--{boundary}{CRLF}"
        f'Content-Disposition: form-data; name="image_file"; filename="{fname}"{CRLF}'
        f"Content-Type: {ctype}{CRLF}{CRLF}"
    ).encode() + data + f"{CRLF}--{boundary}--{CRLF}".encode()

    headers = {
        "Content-Type": f"multipart/form-data; boundary={boundary}",
        "x-api-key": API_KEY,
        "Content-Length": str(len(body))
    }

    conn = http.client.HTTPSConnection("api.backgrounderase.net")
    conn.request("POST", "/v2", body=body, headers=headers)
    resp = conn.getresponse()
    out = resp.read()

    if resp.status == 200:
        with open(dst, "wb") as f: f.write(out)
        print("✅ Saved:", dst)
    else:
        print("❌", resp.status, resp.reason, out.decode(errors="ignore"))
    conn.close()

INPUT_PATH = "./input.jpg"
OUTPUT_PATH = "./output.png"

background_removal(INPUT_PATH, OUTPUT_PATH)

