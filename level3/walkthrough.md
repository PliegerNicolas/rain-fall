# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level3/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level3` commands.

We use `objdump -d ~/level3` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level3`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level3/level3
```

The binary is owned by `level4` and has the `setuid` flag set.
```sh
$ ls -la ~/level3 
-rwsr-s---+ 1 level4 users 5366 Mar  6  2016 /home/user/level3/level3
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

The program shows a non-standard `printf()` usage that violates the specifications of the related [man page](https://man7.org/linux/man-pages/man3/printf.3.html).

> All of these functions write the output under the control of  a  format string  that  specifies how subsequent arguments (or arguments accessed via the variable-length argument facilities of stdarg(3)) are converted
for output.

> Code  such as printf(foo); often indicates a bug, since foo may contain a % character.  If foo comes from untrusted user input, it may  contain %n,  causing  the printf() call to write to memory and creating a secu‐
rity hole.

In other words, `printf()`, as a variadic function, doesn't know how many arguments to expect. The amount and types of arguments are specified by the provided **format string**. By controlling it, we can read and write (using the %n format token) to arbitrary memory. This is called an [uncontrolled format string vulnerability](https://en.wikipedia.org/wiki/Uncontrolled_format_string).

## Vulnerability analysis

Static analysis of [source.c](./source.c) shows the following section
```c
if (m == 64) {
      puts("Wait what?!\n");
      system("/bin/sh");
}
```

### Intent

We wish to identify the variable `m` and set its value to 64 *(0x40)*, satisfying the privilege escalation condition.

### Stack

Our binary is compiled for a **32-bit x86** system.  
It contains two user defined functions (`main()`, `v()`).  
In it, the `main()` function merely acts as a wrapper to the `v()` function, thus we will focus on the latter.

We can assume `m` is either a local file variable or an external variable.  
We can identify it using
```sh
$ objdump -t ./level3 | grep --word-regexp "m"
0804988c g     O .bss	00000004              m
```
Declared in the [ELF .bss section](https://en.wikipedia.org/wiki/.bss), is it a global variable:  
- It's address is `0x0804988c`  
- In **little-endian hex** encoding: `\x8c\x98\x04\x08`.  
- In **little-endian oct** encoding: `\214\230\004\010`.  

Under the **`cdecl`** [x86 calling convention](https://en.wikipedia.org/wiki/X86_calling_conventions), the caller pushes the arguments onto its own stack frame right before executing a call. When the callee sets up its own stack frame, these arguments reside just outside its boundary, allowing it to access the arguments starting from **`ebp + 8`**.

Here the caller would be `v()` and the callee `printf()`.

In other words, during a `printf()` [uncontrolled format string exploit](https://en.wikipedia.org/wiki/Uncontrolled_format_string), we could start reading the stack from the end of the caller's (`v()`) stack frame up until wherever our format string specifiers (`%p`, `%x`, etc.) or arbitrary memory reads/writes stop—effectively leaking stack data or targeting arbitrary addresses until we run out of arguments or trigger a crash.

After the `printf()` call, the stack frames would ressemble something like this
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|       v's return address       | (4 bytes)
+--------------------------------+ <--- v's Stack Frame start (@ 0xbffff72c)
|    main's stack base pointer   | (4 bytes)
+--------------------------------+ (@ 0xbffff728)
| |               |              |
| |               |              |
| |               |              |
| |               |              |
| |               |              |
| |    buffer     | (520 bytes)  | (536 bytes)
| |               |              |
| |               |              |
| |               |              |
| |               |              |
| |               |              |
| +---------------+ (0xbffff520) |
| |   alignment   | (4 bytes)    |
| +---------------+              |
| |     unused    | (8 bytes)    |
| +---------------+ (0xbffff514) | <--- `printf()` official argument boundary.
| |     arg #1    | (4 bytes)    |
+--------------------------------+ (@ 0xbffff510)
|     printf's return address    | (4 bytes)
+--------------------------------+ <--- v's Stack Frame start (@ 0xbffff50c)
|     v's stack base pointer     | (4 bytes)
+--------------------------------+ <--- Stack Base Pointer (EBP @ 0xbffff508)
|                                |
|     printf local variables     |
|               ...              |
|                                |
      LOWER MEMORY ADDRESSES       <--- Stack Pointer (ESP @ 0x????????)
```

We have defined that the intended `printf()` argument boundary is at the address `0xbffff514`.
Our target address is at `0x0804988c`