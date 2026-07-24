# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level6/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level5` commands.

We use `objdump -d ~/level5` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level5`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level5/level5
```

The binary is owned by `level4` and has the `setuid` flag set.
```sh
$ ls -la ~/level5
-rwsr-s---+ 1 level6 users 5385 Mar  6  2016 /home/user/level5/level5
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

Similary to [level3](../level3/walkthrough.md) and [level4](../level4/walkthrough.md), the program shows a non-standard libc `printf()` usage that violates the specifications of the related [man-page](https://man7.org/linux/man-pages/man3/printf.3.html).

In the following explanations, we will assume you have read the previous  walkthrough.md files ([#1](../level3/walkthrough.md) [#2](../level4/walkthrough.md)).[walkthrough.md](../level3/walkthrough.md).

## Vulnerability analysis

Our binary is compiled for a **32-bit x86** system.  
It contains three user-defined functions (`main()`, `n()`, and `o()`). Although `o()` is never called in normal execution, it enables privilege escalation via setuid and a call to `system("/bin/sh")`. Meanwhile, the `main()` function merely acts as a wrapper to the `n()` function, thus we will focus on the latter.

### Intent

We wish to overwrite the **Return Address** of the `n()` function to hijack the program's control flow and redirect it to `o()`.

### Stack

...

### Heap

...