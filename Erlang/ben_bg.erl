%% file: ben_bg.erl
-module(ben_bg).
-export([background_removal/3]).

-define(CRLF, <<"\r\n">>).

background_removal(Src, Dst, ApiKey) ->
    ok = ensure_started(),
    {ok, FileBin} = file:read_file(Src),
    FName = filename:basename(Src),
    CType = mime(Src),

    Boundary = boundary(),
    BoundaryStr = binary_to_list(Boundary),
    ContentType = "multipart/form-data; boundary=" ++ BoundaryStr,

    
    HeaderPart = [
        "--", Boundary, ?CRLF,
        "Content-Disposition: form-data; name=\"image_file\"; filename=\"", FName, "\"", ?CRLF,
        "Content-Type: ", CType, ?CRLF, ?CRLF
    ],
    FooterPart = [?CRLF, "--", Boundary, "--", ?CRLF],
    Body = iolist_to_binary([HeaderPart, FileBin, FooterPart]),

    Headers = [{"x-api-key", ApiKey}],
    Url = "https://api.backgrounderase.net/v2",

    case httpc:request(post, {Url, Headers, ContentType, Body}, [], []) of
        {ok, {{_, 200, _}, _RespHeaders, RespBody}} ->
            ok = file:write_file(Dst, RespBody),
            io:format("✅ Saved: ~s~n", [Dst]),
            ok;
        {ok, {{_, Status, Reason}, _RespHeaders, RespBody}} ->
            io:format("❌ ~p ~s ~s~n", [Status, Reason, safe_text(RespBody)]),
            {error, {Status, Reason}};
        {error, Err} ->
            io:format("❌ request error: ~p~n", [Err]),
            {error, Err}
    end.

ensure_started() ->
    application:ensure_all_started(crypto),
    application:ensure_all_started(ssl),
    application:ensure_all_started(inets),
    ok.

mime(Path) ->
    Ext = string:lowercase(filename:extension(Path)),
    case Ext of
        ".png"  -> "image/png";
        ".jpg"  -> "image/jpeg";
        ".jpeg" -> "image/jpeg";
        ".webp" -> "image/webp";
        ".bmp"  -> "image/bmp";
        ".gif"  -> "image/gif";
        _       -> "application/octet-stream"
    end.

boundary() ->
    <<"----", (binary:encode_hex(crypto:strong_rand_bytes(16)))/binary>>.

safe_text(Bin) when is_binary(Bin) ->
    try unicode:characters_to_list(Bin) catch _:_ -> <<"">> end.
