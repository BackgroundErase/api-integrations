#!/usr/bin/env python3
import os, sys, re, subprocess

STR_START  = 1000   # where strings live on the BF tape
ARGV_START = 2000   # argv[] table on tape (we'll write 8-byte native pointers)
ENV_START  = 2100   # envp[] table on tape (just a single NULL)

def z(s):      return s.encode() + b"\x00"
def le64(n):   return bytes([ (n >> (8*i)) & 0xFF for i in range(8) ])
def move(cur, target):
    return (">" * (target - cur), target) if target > cur else ("<" * (cur - target), target)

def write_bytes_at(data, at, cur):
    code, _ = move(cur, at)
    code += "".join("[-]" + ("+"*b) + ">" for b in data)  # set byte, move right
    return code, at + len(data)

def parse_hex_ptr(s):
    s = s.strip()
    if s.startswith("0x"): return int(s, 16)
    return int(s, 16)

def detect_tape_base():
    # 1) env
    if os.environ.get("TAPE_BASE"):
        return parse_hex_ptr(os.environ["TAPE_BASE"])
    # 2) gdb
    try:
        out = subprocess.check_output(
            ["gdb","-q","./systemf/bin/systemf","-ex","p &tape","-ex","quit"],
            stderr=subprocess.STDOUT, text=True
        )
        m = re.search(r"\$\d+\s*=\s*\(.*\)\s*(0x[0-9a-fA-F]+)", out)
        if m:
            return int(m.group(1), 16)
    except Exception:
        pass
    # 3) nm
    try:
        out = subprocess.check_output(["nm","-an","./systemf/bin/systemf"], text=True)
        for line in out.splitlines():
            if re.search(r"\btape$", line):
                addr = "0x" + line.split()[0]
                return int(addr, 16)
    except Exception:
        pass
    raise SystemExit("Could not determine TAPE_BASE. Set env TAPE_BASE=0x... and rerun.")

def main():
    if len(sys.argv) < 4:
        print("Usage: genbf.py <API_KEY> <ABS_IMAGE_PATH> <OUTPUT_PATH>", file=sys.stderr)
        sys.exit(1)

    api_key  = sys.argv[1]
    img_path = os.path.abspath(sys.argv[2])
    out_abs  = os.path.abspath(sys.argv[3])

    TAPE_BASE = detect_tape_base()

    # 1) Strings to place on the tape (zero-terminated)
    strings = [
        "/usr/bin/curl",                      # 0 path
        "curl",                               # 1
        "-fsS",                               # 2
        "-v",                                 # 3
        "-H",                                 # 4
        f"x-api-key: {api_key}",              # 5
        "-F",                                 # 6
        f"image_file=@{img_path}",            # 7
        "https://api.backgrounderase.net/v2", # 8
        "-o",                                 # 9
        out_abs,                              #10
    ]

    # Assign cell indices for each string
    str_cell = []
    cur_cell = STR_START
    for s in strings:
        str_cell.append(cur_cell)
        cur_cell += len(z(s))

    # Build the BF program
    bf_parts = []
    cur = 0

    # A) write all strings to tape
    for cell, s in zip(str_cell, strings):
        code, cur = write_bytes_at(z(s), cell, cur)
        bf_parts.append(code)

    # B) argv[] table with NATIVE pointers (8-byte little-endian)
    argv_native_ptrs = [
        TAPE_BASE + str_cell[1],  # "curl"
        TAPE_BASE + str_cell[2],  # "-fsS"
        TAPE_BASE + str_cell[3],  # "-v"
        TAPE_BASE + str_cell[4],  # "-H"
        TAPE_BASE + str_cell[5],  # "x-api-key: …"
        TAPE_BASE + str_cell[6],  # "-F"
        TAPE_BASE + str_cell[7],  # "image_file=@/abs/..."
        TAPE_BASE + str_cell[8],  # "https://api.backgrounderase.net/v2"
        TAPE_BASE + str_cell[9],  # "-o"
        TAPE_BASE + str_cell[10], # "/abs/.../out/output.png"
        0                         # NULL
    ]
    argv_bytes = b"".join(le64(p) for p in argv_native_ptrs)
    code, cur = write_bytes_at(argv_bytes, ARGV_START, cur)
    bf_parts.append(code)

    # C) envp[] table: single NULL pointer (8 bytes)
    env_bytes = le64(0)
    code, cur = write_bytes_at(env_bytes, ENV_START, cur)
    bf_parts.append(code)

    # D) syscall frame for execve at cell 0
    # syscall 59 (execve), argc 3
    code, cur = write_bytes_at(bytes([59, 3]), 0, cur)
    bf_parts.append(code)

    # Arg0: pathname (pointer to tape cell of "/usr/bin/curl")
    #   type=2 (cell pointer), len=2 (we encode cell index in 2 bytes), content=cell index
    path_arg = bytes([2, 2]) + bytes([ (str_cell[0] >> 8) & 0xFF, str_cell[0] & 0xFF ])
    code, cur = write_bytes_at(path_arg, 2, cur)
    bf_parts.append(code)

    # Arg1: argv (pointer to tape cell of argv table)
    argv_arg = bytes([2, 2]) + bytes([ (ARGV_START >> 8) & 0xFF, ARGV_START & 0xFF ])
    code, cur = write_bytes_at(argv_arg, 2 + len(path_arg), cur)
    bf_parts.append(code)

    # Arg2: envp (pointer to tape cell of env table)
    env_arg = bytes([2, 2]) + bytes([ (ENV_START >> 8) & 0xFF, ENV_START & 0xFF ])
    code, cur = write_bytes_at(env_arg, 2 + len(path_arg) + len(argv_arg), cur)
    bf_parts.append(code)

    # E) call %
    mv, _ = move(cur, 0)
    bf_parts.append(mv + "%")

    print("".join(bf_parts))

if __name__ == "__main__":
    main()
