; This is a 64-bit Windows executable that prints "Hello, world!\r\n" to the console.
; It is written in NASM syntax and can be assembled with NASM.
; 100% of the program is written out in here and no linker or external tools are used. Simply assemble this file with NASM (-f bin) and you will get a working executable.

[DEFAULT REL]
[BITS 64]

; Constants
    %define ImageBase            0x140000000
    %define FileAlignment        0x200
    %define SectionAlignment     0x1000
    %assign SectionCount         0

; Runtime constants
    %define STD_ERROR_HANDLE     0xFFFFFFF4
    %define STD_OUTPUT_HANDLE    0xFFFFFFF5
    %define STD_INPUT_HANDLE     0xFFFFFFF6

; Macros
    %macro GenerateSectionRVA 0
        %assign SectionCount SectionCount+1
        dd SectionAlignment*SectionCount
    %endmacro

    %define GetTextRVA(ofs)      (ofs - text + 0x1000)
    %define GetIdataRVA(ofs)     (ofs - idata + 0x2000)
    %define GetRdataRVA(ofs)     (ofs - rdata + 0x3000)

    %define Import(name) $ + (GetIdataRVA(name)-GetTextRVA($))
    %define GetText(name) $ + (GetRdataRVA(name)-GetTextRVA($))

dos: ; DOS header
    dw 0x5a4d     ; "MZ"
    dw 0x0000     ; Bytes on last page of file
    dw 0x0000     ; Pages in file
    dw 0x0000     ; Relocations
    dw 0x0004     ; Size of header in paragraphs
    dw 0x0000     ; Minimum extra paragraphs needed
    dw 0xffff     ; Maximum extra paragraphs needed
    dw 0x0000     ; Initial (relative) SS value
    dw 0x0000     ; Initial SP value
    dw 0x0000     ; Checksum
    dw 0x0000     ; Initial IP value
    dw 0x0000     ; Initial (relative) CS value
    dw 0x0000     ; File address of relocation table
    dw 0x0000     ; Overlay number
    dq 0          ; Reserved
    dw 0x0000     ; OEM identifier
    dw 0x0000     ; OEM information
    times 20 db 0 ; Reserved
    dd pe         ; File address of new exe header

stub: ; DOS stub
    [BITS 16]

    push cs
    pop ds ; DS = CS (0)

    mov dx, dosmsg-stub ; String to print
    mov ah, 0x09        ; Print string
    int 0x21

    mov al, 0x1  ; Exit code
    mov ah, 0x4c ; Exit
    int 0x21

    dosmsg db "It's Windows only?!", '$' ; DOS strings are terminated with $

    [BITS 64]
    ALIGN 16, db 0 ; Align to 16 bytes

pe: ; PE header
    dd 0x00004550    ; Signature (PE\0\0)
    dw 0x8664        ; Machine (x64)
    dw 0x0003        ; Number of sections
    dd 0x00000000    ; Time date stamp
    dd 0x00000000    ; Pointer to symbol table
    dd 0x00000000    ; Number of symbols
    dw peoh.end-peoh ; Size of optional header
    dw 0x0022        ; Characteristics (IMAGE_FILE_EXECUTABLE_IMAGE, IMAGE_FILE_LARGE_ADDRESS_AWARE)

    peoh: ; PE Optional header
        dw 0x020b        ; Magic (PE32+)
        db 0x00          ; Major linker version
        db 0x00          ; Minor linker version
        dd text.end-text ; Size of code
        dd rdata.end-rdata ; Size of initialized data
        dd 0x00000000    ; Size of uninitialized data
        dd GetTextRVA(entry) ; Entry point RVA
        dd GetTextRVA(text) ; Base of code
        peoh.win: ; Windows-specific PE Optional header fields
            dq ImageBase          ; Image base
            dd SectionAlignment   ; Section alignment
            dd FileAlignment      ; File alignment
            dw 0x0000             ; Major OS version
            dw 0x0000             ; Minor OS version
            dw 0x0000             ; Major image version
            dw 0x0000             ; Minor image version
            dw 0x0006             ; Major subsystem version
            dw 0x0000             ; Minor subsystem version
            dd 0x00000000         ; Win32 version value (reserved)
            dd 0x4000             ; Size of image (in memory)
            dd head.end           ; Size of headers
            dd 0x00000000         ; Checksum
            dw 0x0003             ; Subsystem (Windows Console)
            dw 0x8160             ; DLL characteristics (IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA, IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE, IMAGE_DLLCHARACTERISTICS_NX_COMPAT, IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE)
            dq 0x0000000001000000 ; Size of stack reserve
            dq 0x0000000000001000 ; Size of stack commit
            dq 0x0000000001000000 ; Size of heap reserve
            dq 0x0000000000001000 ; Size of heap commit
            dd 0x00000000         ; Loader flags (reserved)
            dd 0x00000010         ; Number of data directories
        peoh.ddir: ; Optional header data directories
            dq 0x0000000000000000  ; Export table
            dd GetIdataRVA(idt)    ; Import table
            dd GetIdataRVA(idt.end)-GetIdataRVA(idt) ; Import table size
            dq 0x0000000000000000  ; Resource table
            dq 0x0000000000000000  ; Exception table
            dq 0x0000000000000000  ; Certificate table
            dq 0x0000000000000000  ; Base relocation table
            dq 0x0000000000000000  ; Debug data
            dq 0x0000000000000000  ; Architecture-specific data (reserved)
            dq 0x0000000000000000  ; Global pointer register
            dq 0x0000000000000000  ; Thread local storage (TLS) table
            dq 0x0000000000000000  ; Load configuration table
            dq 0x0000000000000000  ; Bound import table
            dd GetIdataRVA(iat)    ; Import address table
            dd GetIdataRVA(iat.end)-GetIdataRVA(iat) ; Import address table size
            dq 0x0000000000000000  ; Delay import descriptor
            dq 0x0000000000000000  ; CLR runtime header
            dq 0x0000000000000000  ; Reserved
        peoh.end:

sections: ; Section header
    textsection: ; .text section
        dq ".text"     ; Name
        dd text.uend-text ; Virtual size
        GenerateSectionRVA ; Virtual address
        dd text.end-text ; Size of raw data
        dd text        ; Pointer to raw data
        dd 0x00000000  ; Pointer to relocations
        dd 0x00000000  ; Pointer to line numbers
        dw 0x0000      ; Number of relocations
        dw 0x0000      ; Number of line numbers
        dd 0x60000020  ; Characteristics (IMAGE_SCN_CNT_CODE, IMAGE_SCN_MEM_READ, IMAGE_SCN_MEM_EXECUTE)

    idatasection:
        dq ".idata"    ; Name
        dd idata.uend-idata ; Virtual size
        GenerateSectionRVA ; Virtual address
        dd idata.end-idata ; Size of raw data
        dd idata       ; Pointer to raw data
        dd 0x00000000  ; Pointer to relocations
        dd 0x00000000  ; Pointer to line numbers
        dw 0x0000      ; Number of relocations
        dw 0x0000      ; Number of line numbers
        dd 0xc0000040  ; Characteristics (IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_MEM_READ, IMAGE_SCN_MEM_WRITE)

    rdatasection:
        dq ".rdata"    ; Name
        dd rdata.uend-rdata ; Virtual size
        GenerateSectionRVA ; Virtual address
        dd rdata.end-rdata ; Size of raw data
        dd rdata       ; Pointer to raw data
        dd 0x00000000  ; Pointer to relocations
        dd 0x00000000  ; Pointer to line numbers
        dw 0x0000      ; Number of relocations
        dw 0x0000      ; Number of line numbers
        dd 0x40000040  ; Characteristics (IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_MEM_READ)
head.end: ; End of all headers

text: ; 0x1000
    ALIGN FileAlignment, db 0 ; The start of a section must be aligned to FileAlignment

    entry:
        mov rcx, STD_OUTPUT_HANDLE  ; Handle (nStdHandle)
        call [Import(GetStdHandle)] ; GetStdHandle(STD_OUTPUT_HANDLE)

        mov rcx, rax             ; Handle (hConsoleOutput)
        lea rdx, [GetText(msg)]  ; String (lpBuffer)
        mov r8, (msg.end-msg)/2  ; Length (nNumberOfCharsToWrite)
        mov r9, 0                ; Unused (lpReserved)
        call [Import(WriteConsoleW)] ; WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), msg, (msg.end-msg)/2, 0, 0)

        xor rcx, rcx               ; Exit code (uExitCode)
        call [Import(ExitProcess)] ; ExitProcess(0)

    text.uend: ; Unpadded (virtual) end of section
        ALIGN FileAlignment, db 0 ; The size of a section must be a multiple of FileAlignment
    text.end:

idata: ; 0x2000
    ; No need to pad the .idata section because it is already aligned to FileAlignment by the .text section

    idt: ; Import directory table
        dd GetIdataRVA(ilt)                ; Import lookup table RVA
        dd 0x00000000                      ; Time date stamp
        dd 0x00000000                      ; Forwarder chain
        dd GetIdataRVA(kernel32import.name); Name RVA
        dd GetIdataRVA(iat)                ; Import address (thunk) table RVA
        times 20 db 0                      ; Mark the end of the import directory table (1 empty entry)
        idt.end:

    ilt: ; Import lookup table (original thunk)
        dq GetIdataRVA(ExitProcessHint)    ; Import by name, hint 0x178 (ExitProcess)
        dq GetIdataRVA(GetStdHandleHint)   ; Import by name, hint 0x2e8 (GetStdHandle)
        dq GetIdataRVA(WriteConsoleWHint)  ; Import by name, hint 0x61b (WriteConsoleW)
        dq 0                               ; Mark the end of the import lookup table (1 empty entry)

    iat: ; Import address (thunk) table
        ExitProcess:
            dq GetIdataRVA(ExitProcessHint)      ; Import by name, hint 0x16c (ExitProcess)
        GetStdHandle:
            dq GetIdataRVA(GetStdHandleHint)     ; Import by name, hint 0x2e8 (GetStdHandle)
        WriteConsoleW:
            dq GetIdataRVA(WriteConsoleWHint)    ; Import by name, hint 0x61b (WriteConsoleW)
            dq 0                                  ; Mark the end of the import address table (1 empty entry)
        iat.end:

    hnt: ; Hint/Name table
        ExitProcessHint:
            dw 0x0178                ; Hint
            db "ExitProcess", 0      ; Name
            ALIGN 2, db 0            ; Pad
        GetStdHandleHint:
            dw 0x02f3                ; Hint
            db "GetStdHandle", 0     ; Name
            ALIGN 2, db 0            ; Pad
        WriteConsoleWHint:
            dw 0x064a                ; Hint
            db "WriteConsoleW", 0    ; Name
            ALIGN 2, db 0            ; Pad

    kernel32import.name:
        db "KERNEL32.dll", 0

    idata.uend: ; Unpadded (virtual) end of section
        ALIGN FileAlignment, db 0 ; The size of a section must be a multiple of FileAlignment
    idata.end:

rdata: ; 0x3000
    ; No need to pad the .rdata section because it is already aligned to FileAlignment by the .idata section

    msg:
        db __utf16le__("Hello, world!"), 13, 0, 10, 0
    msg.end:

    rdata.uend: ; Unpadded (virtual) end of section
        ALIGN FileAlignment, db 0 ; The size of a section must be a multiple of FileAlignment
    rdata.end:

;;; REFERENCES ;;;
; https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
