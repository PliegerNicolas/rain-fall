section .text
    global _start

_start:
    mov edx, len
    mov ecx, message
    mov ebx, 1
    mov eax, 4                                          ;syscall
    int 0x80                                            ;call the kernel

    mov eax, 1                                          ;syscall exit
    int 0x80                                            ;call the kernel
section .data                                           ;db = define bytes
    message db "writing assembly code", 10    ;10 is new line
    len equ $ - message                                 ;calculate length of the message
    ; this is apin on the abs
