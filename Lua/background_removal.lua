-- background_removal.lua
-- Requires: LuaSocket + LuaSec (ssl.https)
--   luarocks install luasec
--   luarocks install luasocket
--
-- Usage:
--   lua background_removal.lua <src> <dst> [API_KEY]
--   # or set env var:
--   BG_ERASE_API_KEY=your_key lua background_removal.lua <src> <dst>

local https = require("ssl.https")
local ltn12 = require("ltn12")

-- Simple MIME detector by file extension (fallback to octet-stream)
local function guess_mime(path)
  local ext = path:match("^.+(%.[^./\\]+)$")
  if not ext then return "application/octet-stream" end
  ext = ext:lower()
  local map = {
    [".jpg"] = "image/jpeg", [".jpeg"] = "image/jpeg",
    [".png"] = "image/png",  [".gif"]  = "image/gif",
    [".bmp"] = "image/bmp",  [".webp"] = "image/webp",
    [".tif"] = "image/tiff", [".tiff"] = "image/tiff"
  }
  return map[ext] or "application/octet-stream"
end

-- Tiny random hex helper for boundary
local function rand_hex(n)
  local t = {}
  for i = 1, n do
    t[i] = string.format("%x", math.random(0, 15))
  end
  return table.concat(t)
end

local function read_file_bytes(path)
  local f, err = io.open(path, "rb")
  if not f then return nil, err end
  local data = f:read("*all")
  f:close()
  return data
end

local function write_file_bytes(path, data)
  local f, err = io.open(path, "wb")
  if not f then return nil, err end
  f:write(data)
  f:close()
  return true
end

local function background_removal(src, dst, api_key)
  -- Resolve API key: CLI arg > env var
  api_key = api_key or os.getenv("BG_ERASE_API_KEY")
  if not api_key or api_key == "" then
    return nil, "Missing API key. Pass as argv[3] or set BG_ERASE_API_KEY."
  end

  -- Read file
  local file_bytes, rerr = read_file_bytes(src)
  if not file_bytes then
    return nil, ("Failed to read input file: %s"):format(rerr or "unknown")
  end

  -- Build multipart body
  math.randomseed(tonumber(tostring(os.time()):reverse()) + os.clock() * 1e6)
  local boundary = "----" .. rand_hex(32)
  local CRLF = "\r\n"
  local fname = src:match("([^/\\]+)$") or "upload.bin"
  local ctype = guess_mime(src)

  local parts = {
    "--" .. boundary, CRLF,
    ('Content-Disposition: form-data; name="image_file"; filename="%s"'):format(fname), CRLF,
    ("Content-Type: %s"):format(ctype), CRLF, CRLF,
    file_bytes, CRLF,
    "--" .. boundary .. "--", CRLF
  }

  -- Concatenate body (ensure it's a single string, not a stream)
  local body = table.concat(parts)

  local resp_chunks = {}
  local ok, code, resp_headers, status = https.request{
    url = "https://api.backgrounderase.net/v2",
    method = "POST",
    headers = {
      ["Content-Type"]   = "multipart/form-data; boundary=" .. boundary,
      ["x-api-key"]      = api_key,
      ["Content-Length"] = tostring(#body),
    },
    source = ltn12.source.string(body),
    sink   = ltn12.sink.table(resp_chunks),
  }

  if not ok then
    return nil, "HTTPS request failed: " .. tostring(code)
  end

  local resp_body = table.concat(resp_chunks)

  if tonumber(code) == 200 then
    local wok, werr = write_file_bytes(dst, resp_body)
    if not wok then
      return nil, ("Received OK but failed to save output: %s"):format(werr or "unknown")
    end
    return true
  else
    return nil, ("HTTP %s - %s"):format(tostring(code), status or "error")
  end
end

-- CLI entry
local function main()
  local src, dst, key = arg[1], arg[2], arg[3]
  if not src or not dst then
    io.stderr:write("Usage: lua background_removal.lua <src> <dst> [API_KEY]\n")
    os.exit(2)
  end
  local ok, err = background_removal(src, dst, key)
  if ok then
    print("✅ Saved: " .. dst)
    os.exit(0)
  else
    io.stderr:write("❌ " .. tostring(err) .. "\n")
    os.exit(1)
  end
end

if pcall(debug.getlocal, 4, 1) == false then
  main()
end
