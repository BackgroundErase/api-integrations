// backgroundRemoval.ts
import https from "node:https";
import fs from "node:fs";
import path from "node:path";

const API_KEY = "YOUR_API_KEY"; // Replace with your API key

export function backgroundRemoval(srcPath: string, dstPath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const boundary = "----" + Date.now().toString(16);

    const options: https.RequestOptions = {
      hostname: "api.backgrounderase.com",
      path: "/v2",
      method: "POST",
      headers: {
        "Content-Type": `multipart/form-data; boundary=${boundary}`,
        "x-api-key": API_KEY,
      },
    };

    const req = https.request(options, (res) => {
      const contentType = (res.headers["content-type"] as string | undefined) ?? "";
      const isImage = /^image\//.test(contentType);

      if (!isImage) {
        let errMsg = "";
        res.setEncoding("utf8");
        res.on("data", (chunk) => (errMsg += chunk));
        res.on("end", () => reject(new Error(`❌ Error: ${errMsg || `Non-image response (${contentType || "unknown"})`}`)));
        return;
      }

      const fileStream = fs.createWriteStream(dstPath);
      res.pipe(fileStream);

      fileStream.on("finish", () => {
        fileStream.close(() => {
          console.log(`✅ File saved: ${dstPath}`);
          resolve(dstPath);
        });
      });

      fileStream.on("error", (err) => reject(err));
      res.on("error", (err) => reject(err));
    });

    req.on("error", (err) => reject(err));

    req.write(`--${boundary}\r\n`);
    req.write(
      `Content-Disposition: form-data; name="image_file"; filename="${path.basename(srcPath)}"\r\n`
    );
    req.write("Content-Type: application/octet-stream\r\n\r\n");

    const upload = fs.createReadStream(srcPath);

    upload.on("error", (err) => reject(err));

    upload.on("end", () => {
      req.write("\r\n");
      req.write(`--${boundary}--\r\n`);
      req.end();
    });
    upload.pipe(req, { end: false });
  });
}

// Usage: ts-node backgroundRemoval.ts input.jpg output.png
// or compile with tsc and run node dist/background_removal.js

if (require.main === module) {
  const [, , src, dst] = process.argv;

  if (!src || !dst) {
    console.error("Usage: node backgroundRemoval.ts <input> <output>");
    process.exit(1);
  }

  backgroundRemoval(src, dst)
    .then(() => console.log("✅ Background removed successfully!"))
    .catch((err: unknown) => {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(msg);
      process.exit(1);
    });
}
