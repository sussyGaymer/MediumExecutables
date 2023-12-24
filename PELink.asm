; Same as PE.asm, but with a linker

; Build with:
; nasm -f win64 -o out\PELink.obj PELink.asm

; Link with:
; link out\PELink.obj /entry:entry /nodefaultlib /subsystem:console /out:out\PELink.exe lib\KERNEL32.lib
; link.exe can be found in the Visual Studio Build Tools folder (C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.38.33130\bin\Hostx64\x64\link.exe)
; You'll also need KERNEL32.lib in the lib folder.
; I'm not sure where you'd get it normally but I just copied it from the Windows SDK (C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x64). - see Visual Studio Build Tools

[DEFAULT REL]
[BITS 64]

section .data
    msg:
        db __utf16le__("Hello, world!"), 13, 0, 10, 0
    msg.end:

section .text
    extern GetStdHandle
    extern WriteConsoleW
    extern ExitProcess

%define STD_ERROR_HANDLE     0xFFFFFFF4
%define STD_OUTPUT_HANDLE    0xFFFFFFF5
%define STD_INPUT_HANDLE     0xFFFFFFF6

global entry
entry:
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle ; GetStdHandle(STD_OUTPUT_HANDLE)

    mov rcx, rax             ; Handle
    lea rdx, [msg]           ; String
    mov r8, (msg.end-msg)/2  ; Length (msg is a wide string, so divide by 2)
    mov r9, 0                ; Unused
    call WriteConsoleW       ; WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), msg, (msg.end-msg)/2, 0, 0)

    xor rcx, rcx ; Exit code
    call ExitProcess ; ExitProcess(0)
