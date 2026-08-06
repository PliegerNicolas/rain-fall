# RainFall (level7)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level9/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level8` commands.

We use `objdump -d ~/level8` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

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

...

## Vulnerability analysis

...

### Stack

```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffff73c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffff738)
| |               | (8 bytes)    |
| +---------------+              |
| |  align/unused | (8 bytes)    |
| +---------------+              |
| |     strlen    | (4 bytes)    | (168 bytes)
| +---------------+              |
| |     buffer    | (128 bytes)  |
| +---------------+              |
| |   cdecl args  | (16 bytes)   |
+--------------------------------+ <-- main's Stack Pointer (ESP: @ 0xbffff690)
      LOWER MEMORY ADDRESSES      
```

### Heap

...

### GOTS

...

### Intent

...

## Exploit

```sh
```


----------

```sh
$ objdump -d -j .bss ./level8 | grep -A3 -E "auth|service"
08049aac <auth>:
 8049aac:	00 00 00 00                                         ....

08049ab0 <service>:
 8049ab0:	00 00 00 00                                         ....
```
