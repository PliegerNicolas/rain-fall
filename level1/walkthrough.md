# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level2/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level1` commands.

We use `objdump -d ~/level1` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file "/home/user/level0/level0"`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level1/level1
```

We also discover that the flag is owned by `level2` and has the `setuid` flag set.
```sh
ls -la ~/level1
-rwsr-s---+ 1 level2 users 5138 Mar  6  2016 /home/user/level1/level1
```

Useful documentation:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASRL): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

## Discovered vulnerability

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Inherently Dangerous Function" ([CWE-242](http://cwe.mitre.org/data/definitions/242.html)) as state by the [`gets()` man page](https://man7.org/linux/man-pages/man3/gets.3.html).

`gets()` does not perform a buffer overrun check. It introduces a **stack-overflow** opportunity.  
In parallel, the kernel and binary do not implement modern security practices *(Stack Canaries, No-eXecute bit)* that would make it harder to exploit.

## Vulnerability analysis

We wish to perform a stack overflow. We must analyze how this 32-bit binary's stack operates.

Traditionally, a 32-bit function **call** follows this pattern:
1. The **Return Address** is pushed onto the stack **(-4 bytes)**, derived from the address of the instruction after the CALL instruction.
2. The CPU jumps to the called function's address.
3. The **caller's Stack Base Pointer (EBP)** is pushed onto the stack **(-4 bytes)**.
4. The EBP register takes the value of the current Stack Pointer (ESP).
5. The function allocates space for **local variables** on the stack **(-N bytes)** by decreasing the value held by the ESP register.

Model of typical 32-bit x86 stack frame (post function prologue):
```ruby
    HIGHER MEMORY ADDRESSES    
+-----------------------------+
|        Return address       | (4 bytes)
+-----------------------------+
| Caller's Stack Base Pointer | (4 bytes)
+-----------------------------+ <--- Stack Base Pointer (EBP)
|       Memory alignment      | (0-15 bytes)
+-----------------------------+
|                             |
|                             |
|                             |
|       Local Variables       | (0-N bytes)
|                             |
|                             |
|                             |
+-----------------------------+ <--- Stack Pointer (ESP)
     LOWER MEMORY ADDRESSES    
```

Traditionally, once the function finishes, it performs its [epilogue](https://en.wikipedia.org/wiki/Function_prologue_and_epilogue), following this pattern:
1. **Local variable** stack space is released **(+N bytes)** by moving the Stack Pointer (ESP) back to the value of the Stack Base Pointer (EBP).
2. The **caller's Stack Base Pointer (EBP)** is restored by popping it from the stack **(+4 bytes)**.
3. The **Return Address** is popped from the stack **(+4 bytes)** into the Instruction Pointer (EIP).
4. The CPU resumes execution at the restored Return Address.

> For each 32-bit x86 function call, the stack usage increase ranges from **8 to 8+N bytes**.

By analyzing the [source.c](./source.c) and [source.asm](./source.asm) files, we observe that the program allocates 76 bytes on the stack for the buffer. Since the buffer written to by `gets()` is the only local variable declared on the stack, we do not need to consider the ordering of local variables.

## Exploit

Our objective is, through a stack overflow, to overwrite data on the stack, specifically the **Return Address**, and therefore indirectly control the Instruction Pointer (EIP). This allows us to **hijack and redirect the program's execution flow** to code located at an address we control.

Since the [No-eXecute (NX)](https://ctf101.org/binary-exploitation/no-execute/) bit is disabled, the stack is executable. Therefore, the Instruction Pointer (EIP) can be redirected to execute code placed directly on the stack.

We have two options:
1. Redirect the code to an existing vulnerable function, such as `run()`, as seen in [source.c](./source.c) file.
2. Redirect the code to malicious injected valid machine code, such as a syscall.

Buffer overflow model
```sh
                      Write direction ->>>                      

[............BUFFER............][..EBP..][.....Return Addr.....]
|           76 Bytes           ||4 Bytes||       4 Bytes       |
|                   STACK LAYOUT PRE-OVERFLOW                  |

[................PAYLOAD................][.... Exploit addr....]
|           76 + 4 = 80 Bytes           ||       4 Bytes       |
|                  STACK LAYOUT POST-OVERFLOW                  |
```


"/bin/sh"
```asm

```

<!-- The injected malicious code must consist of valid machine code, ideally represented as hexadecimal byte values for flexibility and compactness.

To trigger a privilege escalation, we wish to replace the current process with a shell while keeping the current EUID *(level 2)*.

By considering the following [syscall table](https://filippo.io/linux-syscall-table/), we decided that the `execve syscall (%rax = 59)` would be an appropriate candidate.

```
"/bin/sh\0"
mov eax, 59
mov ebx, path
mov ecx, 0
mov edx, 0
syscall
```

<!-- "/bin/sh\0" = 8 bytes
mov rax,59
eax -->

-------------------

/bin/sh\0
 -->
