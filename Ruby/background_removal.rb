# background_removal.rb
require "net/http"
require "uri"
require "securerandom"
require "openssl"  # <-- add this

API_KEY = "YOUR_API_KEY_HERE" 
def guess_mime(path)
  ext = File.extname(path).downcase
  {
    ".jpg"  => "image/jpeg",
    ".jpeg" => "image/jpeg",
    ".png"  => "image/png",
    ".webp" => "image/webp",
    ".bmp"  => "image/bmp",
    ".gif"  => "image/gif",
    ".tif"  => "image/tiff",
    ".tiff" => "image/tiff",
    ".heic" => "image/heic"
  }[ext] || "application/octet-stream"
end

def build_cert_store
  store = OpenSSL::X509::Store.new
  store.set_default_paths  # use OpenSSL's compiled-in defaults

  # If the user has explicitly pointed to a CA bundle/dir, honor that.
  if (cafile = ENV["SSL_CERT_FILE"]) && File.exist?(cafile)
    store.add_file(cafile)
  elsif (capath = ENV["SSL_CERT_DIR"]) && Dir.exist?(capath)
    store.add_path(capath)
  else
    %w[
      /opt/homebrew/etc/ca-certificates/cert.pem
      /opt/homebrew/etc/openssl@3/cert.pem
      /usr/local/etc/ca-certificates/cert.pem
      /usr/local/etc/openssl@3/cert.pem
      /etc/ssl/cert.pem
      /etc/ssl/certs/ca-certificates.crt
    ].each do |path|
      if File.exist?(path)
        begin
          store.add_file(path)
          break
        rescue OpenSSL::X509::StoreError
          # try next candidate
        end
      end
    end
  end

  store
end

def background_removal(src, dst, api_key: API_KEY)
  fname    = File.basename(src)
  ctype    = guess_mime(src)
  boundary = "----#{SecureRandom.hex(16)}"
  crlf     = "\r\n"
  filedata = File.binread(src)

  head = [
    "--#{boundary}",
    %(Content-Disposition: form-data; name="image_file"; filename="#{fname}"),
    "Content-Type: #{ctype}",
    "",
  ].join(crlf)
  tail = "#{crlf}--#{boundary}--#{crlf}"
  body = head.b + crlf.b + filedata + tail.b

  uri  = URI("https://api.backgrounderase.net/v2")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 30
  http.read_timeout = 120

  # TLS: verify server cert and use a working trust store
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.cert_store  = build_cert_store
  # (Optional) force modern TLS if your OpenSSL is odd:
  # http.min_version = OpenSSL::SSL::TLS1_2_VERSION

  req = Net::HTTP::Post.new(uri.request_uri)
  req["Content-Type"]   = "multipart/form-data; boundary=#{boundary}"
  req["x-api-key"]      = api_key
  req["Content-Length"] = body.bytesize.to_s
  req.body = body

  resp = http.request(req)

  if resp.code.to_i == 200
    File.binwrite(dst, resp.body)
    puts "✅ Saved: #{dst}"
  else
    warn "❌ #{resp.code} #{resp.message}"
    warn resp.body.to_s
  end
end

if __FILE__ == $0
  src = ARGV[0] || "input.jpg"
  dst = ARGV[1] || "output.png"
  background_removal(src, dst, api_key: API_KEY)
end
