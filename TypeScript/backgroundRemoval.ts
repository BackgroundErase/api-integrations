// backgroundRemoval.ts
import https from "https";
import fs from "fs";
import path from "path";

const API_KEY = "YOUR_API_KEY_HERE"; // Insert your API key here

async function backgroundRemoval(srcPath: string, dstPath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const boundary = "----" + Date.now().toString(16);

    const options: https.RequestOptions = {
      hostname: "api.backgrounderase.net",
      path: "/v2",
      method: "POST",
      headers: {
        "Content-Type": `multipart/form-data; boundary=${boundary}`,
        "x-api-key": API_KEY,
      },
    };

    const req = https.request(options, (res) => {
      const contentType = res.headers["content-type"] || "";
      const isImage = /^image\//.test(Array.isArray(contentType) ? contentType[0] : contentType);

      if (!isImage) {
        let errMsg = "";
        res.on("data", (chunk) => (errMsg += chunk));
        res.on("end", () => reject(new Error(`❌ Error: ${errMsg}`)));
        return;
      }

      const fileStream = fs.createWriteStream(dstPath);
      res.pipe(fileStream);

      fileStream.on("finish", () => {
        console.log(`✅ File saved: ${dstPath}`);
        resolve(dstPath);
      });
      fileStream.on("error", reject);
    });

    req.on("error", reject);

    // multipart body
    req.write(`--${boundary}\r\n`);
    req.write(
      `Content-Disposition: form-data; name="image_file"; filename="${path.basename(
        srcPath
      )}"\r\n`
    );
    req.write("Content-Type: application/octet-stream\r\n\r\n");

    const upload = fs.createReadStream(srcPath);
    upload.on("error", reject);
    upload.on("end", () => {
      req.write("\r\n");
      req.write(`--${boundary}--\r\n`);
      req.end();
    });

    upload.pipe(req, { end: false });
  });
}

// ───────────────────────────────
// USAGE (run directly)
// ───────────────────────────────
if (process.argv[1].endsWith("backgroundRemoval.ts")) {
  const src = process.argv[2];
  const dst = process.argv[3];

  if (!src || !dst) {
    console.error("Usage: ts-node backgroundRemoval.ts <input.jpg> <output.png>");
    process.exit(1);
  }

  backgroundRemoval(src, dst)
    .then((out) => console.log("✅ Done:", out))
    .catch((err) => console.error(err));
}

export default backgroundRemoval;
