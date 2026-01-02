
    .text
    .align  2
    .globl  _main
_main:
    // prologue
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // argc=x0, argv=x1
    cmp     x0, #3
    b.ge    ok_args
    adrp    x0, USAGE@PAGE
    add     x0, x0, USAGE@PAGEOFF
    bl      _puts
    mov     w0, #1
    bl      _exit

ok_args:
    mov     x19, x1            // argv
    ldr     x20, [x19, #8]     // src = argv[1]
    ldr     x21, [x19, #16]    // dst = argv[2]

    // Ensure src is readable: access(src, R_OK)
    mov     w1, #4             // R_OK
    mov     x0, x20
    bl      _access
    cbz     w0, have_src
    adrp    x0, SRC_ERR@PAGE
    add     x0, x0, SRC_ERR@PAGEOFF
    bl      _perror
    mov     w0, #1
    bl      _exit

have_src:
    // api_key = getenv("BG_ERASE_API_KEY") ?: DEFAULT_API_KEY
    adrp    x0, ENV_NAME@PAGE
    add     x0, x0, ENV_NAME@PAGEOFF
    bl      _getenv
    cbnz    x0, have_env
    adrp    x0, DEFAULT_API_KEY@PAGE
    add     x0, x0, DEFAULT_API_KEY@PAGEOFF
have_env:
    mov     x22, x0

    // Build hdrbuf = "x-api-key: " + api_key
    // strcpy(hdrbuf, "x-api-key: ")
    adrp    x0, hdrbuf@PAGE
    add     x0, x0, hdrbuf@PAGEOFF
    adrp    x1, HDR_PREFIX@PAGE
    add     x1, x1, HDR_PREFIX@PAGEOFF
    bl      _strcpy
    // strcat(hdrbuf, api_key)
    adrp    x0, hdrbuf@PAGE
    add     x0, x0, hdrbuf@PAGEOFF
    mov     x1, x22
    bl      _strcat

    // Build formbuf = "image_file=@" + src
    adrp    x0, formbuf@PAGE
    add     x0, x0, formbuf@PAGEOFF
    adrp    x1, FORM_PREFIX@PAGE
    add     x1, x1, FORM_PREFIX@PAGEOFF
    bl      _strcpy
    adrp    x0, formbuf@PAGE
    add     x0, x0, formbuf@PAGEOFF
    mov     x1, x20
    bl      _strcat

    // argv on stack: 10 pointers incl NULL
    sub     sp, sp, #(10*8)
    mov     x23, sp

    // argv[0] = "/usr/bin/curl"
    adrp    x0, CURL_ABS@PAGE
    add     x0, x0, CURL_ABS@PAGEOFF
    str     x0, [x23, #(0*8)]
    // argv[1] = "-sSf"
    adrp    x0, OPT_SSF@PAGE
    add     x0, x0, OPT_SSF@PAGEOFF
    str     x0, [x23, #(1*8)]
    // argv[2] = "-H"
    adrp    x0, OPT_H@PAGE
    add     x0, x0, OPT_H@PAGEOFF
    str     x0, [x23, #(2*8)]
    // argv[3] = hdrbuf
    adrp    x0, hdrbuf@PAGE
    add     x0, x0, hdrbuf@PAGEOFF
    str     x0, [x23, #(3*8)]
    // argv[4] = "-F"
    adrp    x0, OPT_F@PAGE
    add     x0, x0, OPT_F@PAGEOFF
    str     x0, [x23, #(4*8)]
    // argv[5] = formbuf
    adrp    x0, formbuf@PAGE
    add     x0, x0, formbuf@PAGEOFF
    str     x0, [x23, #(5*8)]
    // argv[6] = URL
    adrp    x0, URL@PAGE
    add     x0, x0, URL@PAGEOFF
    str     x0, [x23, #(6*8)]
    // argv[7] = "-o"
    adrp    x0, OPT_O@PAGE
    add     x0, x0, OPT_O@PAGEOFF
    str     x0, [x23, #(7*8)]
    // argv[8] = dst
    str     x21, [x23, #(8*8)]
    // argv[9] = NULL
    mov     x0, #0
    str     x0, [x23, #(9*8)]

    // Debug prints
    adrp    x0, DBG1@PAGE
    add     x0, x0, DBG1@PAGEOFF
    bl      _puts
    adrp    x0, hdrbuf@PAGE
    add     x0, x0, hdrbuf@PAGEOFF
    bl      _puts
    adrp    x0, DBG2@PAGE
    add     x0, x0, DBG2@PAGEOFF
    bl      _puts
    adrp    x0, formbuf@PAGE
    add     x0, x0, formbuf@PAGEOFF
    bl      _puts

    // execvp("/usr/bin/curl", argv)
    adrp    x0, CURL_ABS@PAGE
    add     x0, x0, CURL_ABS@PAGEOFF
    mov     x1, x23
    bl      _execvp

    // perror("execvp failed"); exit(1)
    adrp    x0, ERR_EXEC@PAGE
    add     x0, x0, ERR_EXEC@PAGEOFF
    bl      _perror
    mov     w0, #1
    bl      _exit

    // no return
    .ltorg

    .data
    .align  3
DEFAULT_API_KEY: .asciz "YOUR_API_KEY"
URL:            .asciz "https://api.backgrounderase.net/v2"
CURL_ABS:       .asciz "/usr/bin/curl"
OPT_SSF:        .asciz "-sSf"
OPT_H:          .asciz "-H"
OPT_F:          .asciz "-F"
OPT_O:          .asciz "-o"
HDR_PREFIX:     .asciz "x-api-key: "
FORM_PREFIX:    .asciz "image_file=@"
USAGE:          .asciz "Usage: background_removal <src> <dst>"
ENV_NAME:       .asciz "BG_ERASE_API_KEY"
ERR_EXEC:       .asciz "execvp failed"
SRC_ERR:        .asciz "source image not readable"
DBG1:           .asciz "[ben] header ->"
DBG2:           .asciz "[ben] form   ->"

    .bss
    .align  4
    .lcomm hdrbuf, 512
    .lcomm formbuf, 1024

    .extern _getenv
    .extern _execvp
    .extern _puts
    .extern _perror
    .extern _exit
    .extern _access
    .extern _strcpy
    .extern _strcat




