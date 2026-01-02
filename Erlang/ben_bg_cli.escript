#!/usr/bin/env escript
%%! -noshell
main([Src, Dst, ApiKey]) ->
    code:add_path("."),
    case code:load_file(ben_bg) of
        {module, ben_bg} -> ok;
        _ -> io:format("Could not load ben_bg.beam. Compile first with: erlc ben_bg.erl~n"), halt(1)
    end,
    case ben_bg:background_removal(Src, Dst, ApiKey) of
        ok -> halt(0);
        _ -> halt(1)
    end;
main(_) ->
    io:format("Usage: ./ben_bg_cli.escript input.jpg output.png YOUR_API_KEY~n"),
    halt(1).
