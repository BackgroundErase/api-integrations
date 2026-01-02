use std::fs;
use std::io::{Read, Write};
use std::path::Path;
use mime_guess::from_path;
use uuid::Uuid;

const API_KEY: &str = "YOUR_API_KEY"; // or read from env: std::env::var("BG_ERASE_API_KEY")?

fn background_removal(src: &str, dst: &str) -> Result<(), Box<dyn std::error::Error>> {
    let file_path = Path::new(src);
    let file_name = file_path
        .file_name()
        .and_then(|s| s.to_str())
        .ok_or("bad file name")?;

    let ctype = from_path(file_path)
        .first_or_octet_stream()
        .essence_str()
        .to_string();

    let data = fs::read(file_path)?;
    let boundary = format!("----{}", Uuid::new_v4().as_simple()); // e.g., ----3f7e...

    // Build multipart body manually
    let crlf = "\r\n";
    let mut body = Vec::with_capacity(data.len() + 512);
    body.extend_from_slice(format!("--{}{}", &boundary, crlf).as_bytes());
    body.extend_from_slice(
        format!(
            "Content-Disposition: form-data; name=\"image_file\"; filename=\"{}\"{}",
            escape_quotes(file_name),
            crlf
        )
        .as_bytes(),
    );
    body.extend_from_slice(format!("Content-Type: {}{}", ctype, crlf).as_bytes());
    body.extend_from_slice(crlf.as_bytes());
    body.extend_from_slice(&data);
    body.extend_from_slice(crlf.as_bytes());
    body.extend_from_slice(format!("--{}--{}", &boundary, crlf).as_bytes());

    // Send request with ureq (multipart)
    let resp = ureq::post("https://api.backgrounderase.net/v2")
        .set("x-api-key", API_KEY)
        .set("Content-Type", &format!("multipart/form-data; boundary={}", boundary))
        .send_bytes(&body)?;

    if resp.status() == 200 {
        let mut out_file = std::fs::File::create(dst)?;
        // Avoid feature surprises: read the body via reader
        let mut reader = resp.into_reader();
        let mut bytes = Vec::new();
        reader.read_to_end(&mut bytes)?;
        out_file.write_all(&bytes)?;
        println!("✅ Saved: {}", dst);
    } else {
        let status = resp.status();
        let text = resp.into_string().unwrap_or_default();
        eprintln!("❌ {} {}", status, text);
    }

    Ok(())
}

fn escape_quotes(s: &str) -> String {
    s.replace('"', "\\\"")
}

fn main() {
    let src = "input.jpg";
    let dst = "output.png";
    if let Err(e) = background_removal(src, dst) {
        eprintln!("Error: {e}");
    }
}
