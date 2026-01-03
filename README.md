# BackgroundErase API Integrations

This repository contains ready-to-use examples showing how to call the BackgroundErase API from a wide range of programming languages and environments.

Every example follows the same request pattern, so you can easily adapt it to your existing stack with minimal changes.

---

## Authentication

All requests are authenticated using an API key, which must be included in the request headers.

You can generate, rotate, and manage your API keys from your
[account dashboard](https://backgrounderase.com/account).

---

## Response

By default, the API returns a PNG image with the background removed.

Additional output formats and behaviors can be configured using request flags
(e.g. output format, resizing, transparency options).

For a full list of available flags, see the
[Flags documentation](https://backgrounderase.com/docs#flags).

---

## Supported Integrations

Assembly  
Bash / Shell  
Brainfuck  
C  
C++  
C#  
Docker  
Elixir  
Erlang  
Flutter  
Go  
Haskell  
Java  
JavaScript  
Julia  
Kotlin  
Lua  
MATLAB  
Objective-C  
Perl  
PHP  
PowerShell  
Python  
Ruby  
Rust  
Scala  
Scratch  
Swift  
TypeScript  
Zig  

---

## Notes

- All examples are intentionally minimal and production-oriented
- Error handling is kept simple for clarity
- API behavior is identical across all integrations
- Please don’t use Assembly, Brainfuck, or Scratch in production 🙂

If your language or framework isn’t listed, the existing examples should still
serve as a clear reference for implementing your own client.
