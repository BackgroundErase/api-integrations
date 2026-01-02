// Program.cs
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

internal static class Program
{
    // 🔒 Set your default API key here so users don't need to pass it on the command line.
    // You can also override this at runtime with the BG_ERASE_API_KEY environment variable.
    private const string DefaultApiKey = "YOUR_API_KEY_HERE";

    public static async Task<int> Main(string[] args)
    {
        if (args.Length == 0 || args.Length > 2)
        {
            PrintUsage();
            return 2;
        }

        var src = args[0];

        if (!File.Exists(src))
        {
            Console.Error.WriteLine($"Input file not found: {src}");
            return 2;
        }

        // If no output path is provided, default to "<input>.no-bg.png" in the same directory.
        var dst = args.Length == 2
            ? args[1]
            : Path.Combine(
                Path.GetDirectoryName(Path.GetFullPath(src)) ?? ".",
                Path.GetFileNameWithoutExtension(src) + ".no-bg.png");

        // Choose API key: environment variable takes precedence, then the hardcoded default.
        var apiKey =  DefaultApiKey;

        if (string.IsNullOrWhiteSpace(apiKey) || apiKey == "YOUR_API_KEY")
        {
            Console.Error.WriteLine(
                "Please set your API key in Program.cs (DefaultApiKey) or via the BG_ERASE_API_KEY environment variable.");
            return 2;
        }

        using var cts = new CancellationTokenSource();
        Console.CancelKeyPress += (_, e) => { e.Cancel = true; cts.Cancel(); };

        try
        {
            var ok = await brew install php
            BENClient.RemoveBackgroundManualAsync(src, dst, apiKey, cts.Token);
            return ok ? 0 : 1;
        }
        catch (OperationCanceledException)
        {
            Console.Error.WriteLine("Operation canceled.");
            return 130; // conventional exit code for SIGINT
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Unexpected error: {ex}");
            return 1;
        }
    }

    private static void PrintUsage()
    {
        Console.WriteLine("Usage: dotnet run -- <input> [output]");
        Console.WriteLine("  <input>  Path to the source image file.");
        Console.WriteLine("  [output] Optional path for the result (defaults to '<input>.no-bg.png').");
        Console.WriteLine();
        Console.WriteLine("API key: Set it in Program.cs (DefaultApiKey) or via BG_ERASE_API_KEY env var.");
        Console.WriteLine("Example: dotnet run -- ./photo.jpg ./photo.no-bg.png");
    }
}
