
        default rel
        global  main

        extern  getenv
        extern  snprintf
        extern  execvp
        extern  puts
        extern  perror
        extern  exit

SECTION .rodata
DEFAULT_API_KEY: db "YOUR_API_KEY",0
URL:            db "https://api.backgrounderase.net/v2",0
CURL:           db "curl",0
OPT_SSF:        db "-sSf",0
OPT_H:          db "-H",0
OPT_F:          db "-F",0
OPT_O:          db "-o",0
HDR_FMT:        db "x-api-key: %s",0
FORM_FMT:       db "image_file=@%s",0
USAGE:          db "Usage: background_removal <src> <dst>",0
ENV_NAME:       db "BG_ERASE_API_KEY",0
ERR_EXEC:       db "execvp failed",0

SECTION .bss
hdrbuf:   resb 512
formbuf:  resb 1024
        default rel
        global  main
        extern  getenv, snprintf, execvp, puts, perror, exit
SECTION .text
main:
        push rbp
        mov  rbp, rsp              ; <— aligned here; do NOT subtract 8

        ; argc in rdi, argv in rsi
        cmp  rdi, 3
        jge  .ok_args
        lea  rdi, [rel USAGE]
        call puts
        mov  edi, 1
        call exit

.ok_args:
        mov  rbx, rsi               ; rbx = argv
        mov  r12, [rbx+8]           ; r12 = argv[1] (src)  (callee-saved)
        mov  r13, [rbx+16]          ; r13 = argv[2] (dst)  (callee-saved)

        ; api_key = getenv("BG_ERASE_API_KEY")
        lea  rdi, [rel ENV_NAME]
        call getenv
        test rax, rax
        jnz  .have_env_key
        lea  rax, [rel DEFAULT_API_KEY]
.have_env_key:

        ; snprintf(hdrbuf, 512, "x-api-key: %s", api_key)
        mov  rdi, hdrbuf
        mov  rsi, 512
        lea  rdx, [rel HDR_FMT]
        mov  rcx, rax
        xor  rax, rax
        call snprintf

        ; snprintf(formbuf, 1024, "image_file=@%s", src)
        mov  rdi, formbuf
        mov  rsi, 1024
        lea  rdx, [rel FORM_FMT]
        mov  rcx, r12
        xor  rax, rax
        call snprintf

        ; Build argv: ["curl","-sSf","-H",hdrbuf,"-F",formbuf,URL,"-o",dst,NULL]
        sub  rsp, 10*8              ; 80 bytes; still 16B-aligned
        mov  r10, rsp

        lea  rax, [rel CURL]        ; 0
        mov  [r10+0*8], rax
        lea  rax, [rel OPT_SSF]     ; 1
        mov  [r10+1*8], rax
        lea  rax, [rel OPT_H]       ; 2
        mov  [r10+2*8], rax
        mov  rax, hdrbuf            ; 3
        mov  [r10+3*8], rax
        lea  rax, [rel OPT_F]       ; 4
        mov  [r10+4*8], rax
        mov  rax, formbuf           ; 5
        mov  [r10+5*8], rax
        lea  rax, [rel URL]         ; 6
        mov  [r10+6*8], rax
        lea  rax, [rel OPT_O]       ; 7
        mov  [r10+7*8], rax
        mov  rax, r13               ; 8 = dst
        mov  [r10+8*8], rax
        mov  qword [r10+9*8], 0     ; 9 = NULL

        ; execvp("curl", argv)
        lea  rdi, [rel CURL]
        mov  rsi, r10
        call execvp

        ; exec failed
        lea  rdi, [rel ERR_EXEC]
        call perror
        mov  edi, 1
        call exit
