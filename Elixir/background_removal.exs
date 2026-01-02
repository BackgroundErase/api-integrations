#!/usr/bin/env elixir

# Usage:
#   BG_ERASE_API_KEY="YOUR_API_KEY" elixir background_removal.exs path/to/input.jpg output.png

if length(System.argv()) < 2 do
  IO.puts("Usage: elixir background_removal.exs <input_image> <output_png>")
  System.halt(1)
end

[src_arg, dst] = System.argv()
api_key = System.get_env("BG_ERASE_API_KEY") || ""

if api_key == "" do
  IO.puts("❌ Missing API key. Set BG_ERASE_API_KEY environment variable.")
  System.halt(1)
end

src = Path.expand(src_arg)
unless File.exists?(src) do
  IO.puts("❌ Input file not found: #{src}")
  System.halt(1)
end

:ok = :inets.start()
:ok = :ssl.start()

# MIME detection with fallback
ctype =
  (try do MIME.from_path(src) rescue _ -> nil end) ||
    case Path.extname(src) |> String.downcase() do
      ".jpg"  -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png"  -> "image/png"
      ".webp" -> "image/webp"
      ".bmp"  -> "image/bmp"
      ".tif"  -> "image/tiff"
      ".tiff" -> "image/tiff"
      _       -> "application/octet-stream"
    end

{:ok, file_data} = File.read(src)
fname    = Path.basename(src)
boundary = "----" <> Base.encode16(:crypto.strong_rand_bytes(8))
crlf     = "\r\n"

# Build multipart body
body =
  [
    "--", boundary, crlf,
    ~s(Content-Disposition: form-data; name="image_file"; filename="#{fname}"), crlf,
    "Content-Type: ", ctype, crlf, crlf,
    file_data, crlf,
    "--", boundary, "--", crlf
  ]
  |> IO.iodata_to_binary()

# Only the headers that are NOT Content-Type (that comes from the 3rd arg below)
headers = [
  {~c"x-api-key", String.to_charlist(api_key)}
]

url = ~c"https://api.backgrounderase.net/v2"
content_type = String.to_charlist("multipart/form-data; boundary=#{boundary}")

case :httpc.request(:post, {url, headers, content_type, body}, [], []) do
  {:ok, {{_, 200, _}, _resp_headers, response_body}} ->
    File.write!(dst, response_body)
    IO.puts("✅ Saved: #{Path.expand(dst)}")

  {:ok, {{_, status, reason}, _resp_headers, response_body}} ->
    IO.puts("❌ #{status} #{reason}")
    if is_binary(response_body), do: IO.puts(response_body), else: IO.inspect(response_body)
    System.halt(2)

  {:error, reason} ->
    IO.puts("❌ Request failed: #{inspect(reason)}")
    System.halt(3)
end
