# RainFall (level5)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level5/level5`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level5`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level5`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level5
-rwsr-s---+ 1 level6 users 5385 Mar  6  2016 /home/user/level5/level5
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level6's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level5
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level5/level5
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

Similary to previous exercices ([level3](../level3/walkthrough.md), [level4](../level4/walkthrough.md)), the program shows a non-standard libc `printf()` usage that violates the specifications of the related [man-page](https://man7.org/linux/man-pages/man3/printf.3.html).

This allows us to write arbitrary data to arbitrary writable regions of memory. To understand how, you should refer to the previous exercices. We will assume you have read their **walkthrough.md** files.

## Vulnerability analysis

Our binary is compiled for a **32-bit x86** system.  
It contains three user-defined functions (`main()`, `n()`, and `o()`). Although `o()` is never called in normal execution, calling it enables privilege escalation via setuid and execution of `system("/bin/sh")`.  
Meanwhile, the `main()` function merely acts as a wrapper to the `n()` function, thus we will focus on the latter.

Neither `n()` nor `o()` returns through their [prologues](https://en.wikipedia.org/wiki/Function_prologue_and_epilogue). They do through a call to `exit()`. This prevents traditionnal **Return Address** hijacking as it's never evaluated.

Given this constraint and the explicit invitation to hijack the program's control flow, alternative exploitation techniques must be considered.

### GOT/PLT

We notice that the `exit()` call has actually been translated to a stub function, `_exit@plt`.

The [Procedure Linkage Table *(PLT)*](https://refspecs.linuxfoundation.org/ELF/zSeries/lzsabi0_zSeries/x2251.html#PROCEDURELINKAGETABLE) relies on the [Global Offset Table *(GOT)*](https://en.wikipedia.org/wiki/Global_Offset_Table) to resolve and execute functions from external shared libraries while maintaining position independence.

Understanding the [PLT](https://refspecs.linuxfoundation.org/ELF/zSeries/lzsabi0_zSeries/x2251.html#PROCEDURELINKAGETABLE) involves key [special ELF sections](https://refspecs.linuxfoundation.org/LSB_1.1.0/gLSB/specialsections.html):
- `.plt`: holds the Procedure Linkage Table, consisting of executable stubs that redirect calls to the Global Offset Table.
- `.got`: holds the Global Offset Table, consisting of absolute memory addresses (pointers) to external variables (including functions), populated by the dynamic linker.
- ...

Assuming the [Global Offset Table *(GOT)*](https://en.wikipedia.org/wiki/Global_Offset_Table) is writable, we could perform control flow hijacks through the [Procedure Linkage Table *(PLT)*](https://refspecs.linuxfoundation.org/ELF/zSeries/lzsabi0_zSeries/x2251.html#PROCEDURELINKAGETABLE) functions by injecting a malicious external function address.
```sh
$ readelf -S ./level5 | grep .got
  [22] .got              PROGBITS        08049814 000814 000004 04  WA  0   0  4
  [23] .got.plt          PROGBITS        08049818 000818 000028 04  WA  0   0  4
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings)
  I (info), L (link order), G (group), T (TLS), E (exclude), x (unknown)
  O (extra OS processing required) o (OS specific), p (processor specific)
```

### Uncontrolled format string (printf)

As seen in previous exercices ([level3](../level3/walkthrough.md), [level4](../level4/walkthrough.md)), we are capable of assigning a 32-bit integers to a specific memory address without much trouble.

Knowing that a 32-bit memory address is fundamentally a 32-bit integer—meaning it can be represented in either hexadecimal or decimal form. Thus we are able to overwrite a memory address pointed to by a GOT/PLT entry to redirect execution flow using the [uncontrolled format string](https://en.wikipedia.org/wiki/Uncontrolled_format_string) exploit, leveraging the `%n` format flag.

### Intent

We wish to overwrite the `exit()` [GOT](https://en.wikipedia.org/wiki/Global_Offset_Table) entry with the memory address of `o()` to perform a control flow hijack.

### Stack

After the `printf()` call, the stack frames would ressemble something like this.
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|       n's return address       | (4 bytes)
+--------------------------------+ <--- n's Stack Frame start (@ 0xbffff72c)
|    main's stack base pointer   | (4 bytes)
+--------------------------------+ <--- n's local variables start (@ 0xbffff728)
| |               |              |
| |               |              |
| |               |              |
| |     buffer    | (520 bytes)  |
| |               |              | (536 bytes)
| |               |              |
| +---------------+ (0xbffff520) |
| |     unused    | (12 bytes)   |
| +---------------+              |
| | ptr to buffer | (4 bytes)    |
+--------------------------------+ <-- n's Stack Pointer (ESP: @ 0xbffff510)
      LOWER MEMORY ADDRESSES      
```

### Heap

No user-defined functions request space on the heap. However, `printf()` calls may occasionally trigger `malloc()` depending on the arguments. Since we do not intend to use heap allocation, we will ignore this for now.

## Exploit

First let's identify where the buffer starts 
```sh
# We skip 4 words: (4+12) / 4 = 4
$ printf "%b\n" "\257\276\255\336%4\$p" | ./level5
����0xdeadbeaf
```

The `_exit@plt` function in the [source.asm](./source.asm) file specifies about it's GOT slot that:
- In **big-endian hex** notation, it's located at: `0x8049828`.
- In **little-endian hex** escape sequence, it's located at: `\x28\x98\x04\x80`.
- In **little-endian oct** escape sequence, it's located at: `\050\230\004\200`.

As seen in the [source.asm](./source.asm) file, the entrypoint address of the `o()` function:
- In **big-endian hex** notation, it's located at: `0x080484a4`.
- In **little-endian hex** escape sequence: `\xa4\x84\x04\x08`.
- In **little-endian oct** escape sequence: `\244\204\004\010`.
- In decimal: **`134513828`**.

In the same fashion as the previous exercice, we assign the value to the target address by writing the required amount of characters.
```sh
$ ./level6 "$(printf "%72c%b" "c" "\124\204\004\010")"
```

And there we are