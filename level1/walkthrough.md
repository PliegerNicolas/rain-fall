# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/levelXX/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level1` commands.

We use the `objdump -d ~/level1` command to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompiled the binary using [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

This following can be observed by accessing the server via the [ssh.sh](./Ressources/ssh.sh) script.

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

This decompiled binary as described in the [source](source.c) file is subject to a "Use of Inherently Dangerous Function" ([CWE-242](http://cwe.mitre.org/data/definitions/242.html)).
It uses the [`gets()`](https://man7.org/linux/man-pages/man3/gets.3.html) who's man page states it explicitly.

As the function does no perform a buffer overrun check, it introduces a **stack-overflow** opportunity. In paralle, the kernel and binary do not implement modern security practices *(Stack Canaries, No-eXecute bit)*, that would make it harder to exploit.

## Vulnerability analysis

Analysis of [source.c](./source.c) reveals that `gets()` is intended to write into a 76 byte buffer.
Analysis of [source.asm](./source.asm) reveals that:
- `gets()` writes into a **80 byte** buffer expanded due to memory alignment requirements.
- The functions [prologue and epilogue](https://en.wikipedia.org/wiki/Function_prologue_and_epilogue) take 8 bytes *(on 32-bit binaries)*, including the current **frame pointer** (4 bytes) and **return address** (4 bytes).

Here is a representation of the `main()` function stack frame.
```ruby
 HIGHER MEMORY ADDRESSES
+-----------------------+
|  Return address (4B)  |
+-----------------------+
|  Frame pointer (4B)   | <- Stack Base Pointer (EBP)
+ ----------------------+
|                       |
|                       |
|                       |
|     Buffer (80B)      |
|                       |
|                       |
|                       |
+-----------------------+ <-- Stack Pointer (ESP)
 LOWER MEMORY ADDRESSES  
```
The function [epilogue process](https://en.wikipedia.org/wiki/Function_prologue_and_epilogue) cleans up the current stack frame and moves the stored Return Address into the **Next Instruction Pointer (EIP)**, effectively handing control of the CPU to that address.

By overwriting this return address, we can hijack the program's control flow, redirecting it to any function or malicious code of our choosing.

Since the [No-eXecute (NX)](https://ctf101.org/binary-exploitation/no-execute/) bit is disabled, we can simply inject our own code into the stack and point the EIP to the start of it to execute it.

## Exploit

The binary has the SetUID bit set, which assigns the Effective User ID (EUID) of **level2** to the process.
If we spawn a shell while preserving this EUID, we achieve privilege escalation.

Our exploit follows this procedure:
1. Inject machine code into the buffer (max 84 bytes). It must be ASM compatible and ideally compacted through HEX.
2. Overwrite the Return Address on the stack to point to the start of the buffer.
3. Allow the program to complete its function epilogue and execute our injected code.
