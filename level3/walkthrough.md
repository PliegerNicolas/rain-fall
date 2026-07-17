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

Unlike previous levels, `gets()` has been replaced by `fgets()`, which mitigates standard buffer overflows through mandatory bounds checking.

However, the program shows a non-standard `printf()` usage.
Its [man page](https://man7.org/linux/man-pages/man3/printf.3.html) mentions:
> All of these functions write the output under the control of  a  format string  that  specifies how subsequent arguments (or arguments accessed via the variable-length argument facilities of stdarg(3)) are converted
for output.

> Code  such as printf(foo); often indicates a bug, since foo may contain a % character.  If foo comes from untrusted user input, it may  contain %n,  causing  the printf() call to write to memory and creating a secu‐
rity hole.

In other words, `printf()` is a variadic function. It doesn't know how many arguments to expect. It relies entirely on the format string to tell it how many arguments to look for and what types they are.  
By controlling the **format string** we also control the accessed variables.

This is called an [uncontrolled format string vulnerability](https://en.wikipedia.org/wiki/Uncontrolled_format_string).

## Vulnerability analysis

We notice in the [source.c](./source.c) file, that a privilege escalation opportunity is only protected by the following condition `if (m == 0x40) { ... }`.

`m` doesn't seem to be declared in the current stack frame.  
We can find it's relative address through the symbol table
```sh
$ objdump -t ./level3 | grep --word-regexp "m"
0804988c g     O .bss	00000004              m
```
Declared in the [ELF .bss section](https://en.wikipedia.org/wiki/.bss), is it a global variable:  
- It's address is `0x0804988c`  
- In **little-endian hex** encoding: `\x8c\x98\x04\x08`.  
- In **little-endian oct** encoding: `\214\230\004\010`.  

### Intent

We now know that we wish to exploit the found vulnerability to assign the **decimal value 64** to the **m (0x0804988c)** global variable.

### Stack

Our binary is compiled for a **32-bit x86** system.  
It contains two user defined functions (`main()`, `v()`).  
In it, the `main()` function merely acts as a wrapper to the `v()` function, thus we will focus on the latter.

By static and dynamic analysis we managed to portray to `v()` function's stack frame:
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|       v's return address       | (4 bytes)
+--------------------------------+ <--- v's Stack Frame start (@ 0xbffff72c)
|    main's stack base pointer   | (4 bytes)
+--------------------------------+ <--- Stack Base Pointer (EBP @ 0xbffff728)
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
| |               |              |
| | argument area | (12 bytes)   |
| |               |              |
+--------------------------------+ <--- Stack Pointer (ESP @ 0xbffff510)
      LOWER MEMORY ADDRESSES      
```

### Heap

No explicit Heap manipulation is present.  
`malloc()` calls could be triggered internally through `printf()` **format string** manipulation though.

<!-- We wish to exploit the `printf()` format string to overwrite the global variable `m()`'s value and set it to 64.

As seen in the assembly code
```asm
 80484da:	a1 8c 98 04 08       	mov    0x804988c,%eax
 80484df:	83 f8 40             	cmp    $0x40,%eax
```


The global variable `m` is located at the follow address: `` -->

<!-- ### Examples

```c
#include <stdio.h>

int main(void) {
    int a = 0;
    printf("a = %d\n", a);
    // Outputs: "a = 0\n"
    printf("abc%n\n", &a);
    // Outputs: "abc\n"
    printf("a = %d\n", a);
    // Outputs: "a = 3\n"
    return 0;
}
``` -->


## Exploit

...