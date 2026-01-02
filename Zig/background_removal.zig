const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var args_it = try std.process.argsWithAllocator(alloc);
    defer args_it.deinit();

    _ = args_it.next(); // program name
    const src_path = args_it.next() orelse return usage();
    const dst_path = args_it.next() orelse return usage();
    const cli_key  = args_it.next(); // optional

    const DEFAULT_API_KEY = "YOUR_API_KEY_HERE";
    // API key precedence: CLI > ENV > DEFAULT
    const env_key = std.process.getEnvVarOwned(alloc, "BG_ERASE_API_KEY") catch null;
    defer if (env_key) |k| alloc.free(k);

    const api_key = if (cli_key) |k|
        k
    else if (env_key) |k|
        k
    else
        DEFAULT_API_KEY;

    // read file
    var file = try std.fs.cwd().openFile(src_path, .{ .mode = .read_only });
    defer file.close();

    const file_data = try file.readToEndAlloc(alloc, 100 * 1024 * 1024); // 100MB cap
    defer alloc.free(file_data);

    // guess mime by extension (fallback to octet-stream)
    const mime = guessMime(src_path);

    // boundary: random hex from u64
    const boundary = try makeBoundary(alloc);
    defer alloc.free(boundary);

    // build multipart body in memory
    const body = try buildMultipart(alloc, boundary, "image_file", src_path, mime, file_data);
    defer alloc.free(body);

    // HTTPS POST to https://api.backgrounderase.net/v2
    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();

    // Load system CAs for TLS
    client.tls_ca_bundle = try std.crypto.Certificate.Bundle.fromSystem(alloc);
    defer client.tls_ca_bundle.deinit();

    const uri = try std.Uri.parse("https://api.backgrounderase.net/v2");

    var req = try client.request(.POST, uri, .{
        .server_header_buffer = &[_]u8{},
        .headers = .{},
    });
    defer req.deinit();

    // headers
    try req.headers.put("Host", "api.backgrounderase.net");
    try req.headers.put("Accept", "*/*");
    try req.headers.put("x-api-key", api_key);

    var ct_buf = std.ArrayList(u8).init(alloc);
    defer ct_buf.deinit();
    try ct_buf.writer().print("multipart/form-data; boundary={s}", .{boundary});
    try req.headers.put("Content-Type", ct_buf.items);

    const len_str = try std.fmt.allocPrint(alloc, "{d}", .{body.len});
    defer alloc.free(len_str);
    try req.headers.put("Content-Length", len_str);

    // send
    try req.writeAll(body);
    try req.finish();
    try req.wait();

    const status = req.response.status;

    // read response body
    const out_bytes = try req.reader().readAllAlloc(alloc, 100 * 1024 * 1024);
    defer alloc.free(out_bytes);

    if (status == .ok) {
        try std.fs.cwd().writeFile(.{ .sub_path = dst_path, .data = out_bytes });
        std.debug.print("✅ Saved: {s}\n", .{dst_path});
    } else {
        std.debug.print("❌ {d} {s}\n", .{@intFromEnum(status), @tagName(status)});
        std.debug.print("{s}\n", .{out_bytes});
        std.process.exit(1);
    }
}

fn usage() noreturn {
    std.debug.print(
        "Usage:\n  background_removal <src> <dst> [API_KEY]\n\n" ++
        "API key precedence: CLI arg > BG_ERASE_API_KEY env var > hardcoded default\n", .{});
    std.process.exit(2);
}

// ---- Zig 0.15-safe helpers ----

fn guessMime(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path); // includes leading dot, e.g. ".jpg"
    if (std.ascii.eqlIgnoreCase(ext, ".jpg") or std.ascii.eqlIgnoreCase(ext, ".jpeg")) return "image/jpeg";
    if (std.ascii.eqlIgnoreCase(ext, ".png")) return "image/png";
    if (std.ascii.eqlIgnoreCase(ext, ".webp")) return "image/webp";
    if (std.ascii.eqlIgnoreCase(ext, ".bmp")) return "image/bmp";
    if (std.ascii.eqlIgnoreCase(ext, ".gif")) return "image/gif";
    return "application/octet-stream";
}

fn makeBoundary(alloc: std.mem.Allocator) ![]u8 {
    // Random 64-bit hex is plenty unique for multipart boundary
    const r: u64 = std.crypto.random.int(u64);
    return std.fmt.allocPrint(alloc, "----BEN{x}", .{r});
}

fn buildMultipart(
    alloc: std.mem.Allocator,
    boundary: []const u8,
    field_name: []const u8,
    filename_path: []const u8,
    mime: []const u8,
    data: []const u8,
) ![]u8 {
    // Extract filename part (handles both "/" and "\" just in case)
    const fname = blk: {
        var last_slash: usize = 0;
        var i: usize = 0;
        while (i < filename_path.len) : (i += 1) {
            const c = filename_path[i];
            if (c == '/' or c == '\\') last_slash = i + 1;
        }
        break :blk filename_path[last_slash..];
    };

    const CRLF = "\r\n";

    var buf = std.ArrayList(u8).init(alloc);
    errdefer buf.deinit();

    const w = buf.writer();

    // Preamble
    try w.print("--{s}{s}", .{ boundary, CRLF });
    try w.print(
        "Content-Disposition: form-data; name=\"{s}\"; filename=\"{s}\"{s}",
        .{ field_name, fname, CRLF },
    );
    try w.print("Content-Type: {s}{s}{s}", .{ mime, CRLF, CRLF });

    // File bytes
    try w.writeAll(data);
    try w.writeAll(CRLF);

    // Closing boundary
    try w.print("--{s}--{s}", .{ boundary, CRLF });

    return buf.toOwnedSlice();
}
