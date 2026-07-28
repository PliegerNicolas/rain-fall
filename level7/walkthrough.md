# RainFall (level7)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level8/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level7` commands.

We use `objdump -d ~/level7` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level7`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level7/level7
```

The binary is owned by `level8` and has the `setuid` flag set.
```sh
$ ls -la ~/level7 
-rwsr-s---+ 1 level8 users 5648 Mar  9  2016 /home/user/level7/level7
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

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Potentially Dangerous Function" ([CWE-676](https://cwe.mitre.org/data/definitions/676.html)). Not all [`strcpy()` man page](https://man7.org/linux/man-pages/man3/strcpy.3.html)s do explicitly state it as dangerous. This one describes it as cause of undefined behaviour.

`strcpy()` does not perform a buffer overrun check. It introduces a **stack/heap-overflow** opportunity when handling user-controlled input. In parallel, the kernel and binary do not implement modern security practices *(No-eXecute bit)* that would make it harder to exploit.

## Vulnerability analysis

Our binary is compiled for a **32-bit x86** system.  
It contains two user-defined functions (`main()`, `m()`).  
Although `m()` is never called in normal execution, calling it prints the contents of the global stack variable `c`, in which the first 68 bytes of the contents of `fopen("/home/user/level8/.pass", "r")` are stored, exposing the password for **user8**.

The binary core logic works based on the **heap**.

### Intent

### Stack

After the `puts("~~")` call, the stack frames would ressemble something like this.
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffff73c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffff738)
| |               |              |
| |  unused/align | (8 bytes)    |
| |               |              |
| +---------------+              |
| |   cntr_a PTR  | (4 bytes)    |
| +---------------+ (@ bffff72c) |
| |   cntr_b PTR  | (4 bytes)    |(40 bytes)
| +---------------+ (@ bffff728) |
| |               |              |
| |  unused/align | (12 bytes)   |
| |               |              |
| +---------------+              |
| |   stream PTR  | (4 bytes)    |
| +---------------+ (@ bffff718) |
| |     arg#2     | (4 bytes)    |
| +---------------+              |
| |     arg#1     | (4 bytes)    |
+--------------------------------+ <-- main's Stack Pointer (ESP: @ 0xbffff710)
      LOWER MEMORY ADDRESSES      
```

### Heap

```ruby
      LOWER MEMORY ADDRESSES      
+--------------------------------+ <-- `cntr_a` (@ 0x804a008)
| id: 1          | (0x804a008)   |
| str: 0x804a018 | (0x804a00c)   | (8 bytes)
|                |               |
+--------------------------------+ <-- `cntr_a->str` (@ 0x804a018)
|           cntr_a->str          | (8 bytes)
+--------------------------------+ <-- `cntr_b` (@ 0x804a028)
| id: 2          | (0x804a028)   |
| str: 0x804a038 | (0x804a02c)   | (8 bytes)
|                |               |
+--------------------------------+ <-- `cntr_b->str` (@ 0x804a038)
|           cntr_b->str          | (8 bytes)
+--------------------------------+
      HIGHER MEMORY ADDRESSES     
```

```ruby
      LOWER MEMORY ADDRESSES      
+--------------------------------+ <-- `malloc $1` (@ 0x804a008)
|                                |
|                                |
|                                |
+--------------------------------+ <-- `malloc $2` (@ 0x804a018)
|                                |
|                                |
|                                |
+--------------------------------+ <-- `malloc $3` (@ 0x804a028)
|                                |
|                                |
|                                |
+--------------------------------+ <-- `malloc $4` (@ 0x804a038)
|                                |
|                                |
|                                |
+--------------------------------+
      HIGHER MEMORY ADDRESSES     
```

### Intent

...

## Exploit

...